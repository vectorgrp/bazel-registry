load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

_Cfg6ToolProvider = provider()

ScriptTaskProvider = provider()

def _cfg6_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(cfg6 = _Cfg6ToolProvider(
        cli = ctx.attr.cli,
        xpro = ctx.attr.xpro,
        core = ctx.attr.core,
        files = depset(ctx.files.cfg6_files),
        settings_patcher = ctx.attr.settings_patcher[DefaultInfo].files_to_run,
        differ = ctx.attr.differ
    ))]

cfg6_toolchain = rule(
    implementation = _cfg6_toolchain_impl,
    attrs = {
        "cli": attr.label(doc = "The DaVinci Configurator CLI executable.", allow_single_file = True, mandatory = True),
        "xpro": attr.label(doc = "The ECU extract processor executable.", allow_single_file = True, mandatory = True),
        "core": attr.label(doc = "The DaVinci Configurator core executable.", allow_single_file = True, mandatory = True),
        "cfg6_files": attr.label_list(doc = "All files of the CFG6 installation, declared as tools of every action using one of the executables.", allow_files = True, mandatory = True),
        "settings_patcher": attr.label(doc = "Tool for configuring the settings of a DaVinci project.", executable = True, mandatory = True, cfg = "exec"),
        "differ": attr.label(doc = "Tool for comparing two DaVinci projects.", mandatory = True)
    }
)

_TOOLCHAIN = Label(":toolchain_type")

def _cfg6(ctx):
    return ctx.toolchains[_TOOLCHAIN].cfg6

def _expand_location(ctx, target, build):
    return ctx.expand_location("$({} {})".format("locations" if build else "rlocationpaths", target.label), [target]).split(" ")

_PRIMITIVE_TYPE = type("")
_LIST_TYPE = type([])

def _to_paths(ctx, target, build):
    if BuildSettingInfo in target:
        v = target[BuildSettingInfo].value
        return v if type(v) == _LIST_TYPE else [str(v)]
    paths = [p for t in target for p in _expand_location(ctx, t, build)] if type(target) == _LIST_TYPE else _expand_location(ctx, target, build)
    result = []
    tmp = ""
    for s in paths:
        p = tmp + " " + s if tmp else s
        if p.startswith("'"):
            if p.endswith("'") and not p.endswith("\\'"):
                result.append(p if build else "$(rlocation {})".format(p))
                tmp = ""
            else:
                tmp = p
        else:
            result.append(p if build else "$(rlocation {})".format(p))
    return result

def bsw_pkg(ctx, target, build):
    paths = _to_paths(ctx, target, build)
    if len(paths) == 1:
        return "-b", "-b " + paths[0]
    for p in paths:
        i = p.find("/Components/")
        if i != -1:
            return "-b", "-b " + ((p[:i] + ("'" if p.startswith("'") else "")) if build else '"$(r={}; echo "${{r%%/Components/*}}")"'.format(p))
    fail("The BSW package must either be provided as folder or as a label aggregating all BSW package files relevant for DaVinci Configurator Classic Version 6.")

SPECIAL_KEYS = {
    bsw_pkg: "-b"
}

def _item(ctx, item, build):
    k, v = item
    if type(v) == _PRIMITIVE_TYPE:
        return item
    if k in SPECIAL_KEYS:
        return k(ctx, v, build)
    if k.startswith("-"):
        return k, k + " " + (" " + k + " ").join(_to_paths(ctx, v, build))
    key_and_sep = k.split("|")
    if len(key_and_sep) != 2:
        key_and_sep = [k, " "]
    return key_and_sep[0], key_and_sep[1].join(_to_paths(ctx, v, build))

def _format_dict(ctx, dict, build):
    return { k: v for k, v in [_item(ctx, i, build) for i in dict.items()] }

def script(ctx, name, cmd, build, dict):
    script = ctx.actions.declare_file(name)
    ctx.actions.write(script, 'set -euo pipefail\n' + cmd.format(**_format_dict(ctx, dict, build)), is_executable = True)
    return script

def export_env(ctx):
    exports = "\n".join([
        "export {name}='{value}'".format(name = k, value = v.replace("'", "'\\''").replace("{", "{{").replace("}", "}}"))
        for k, v in ctx.attr._env_flag[BuildSettingInfo].value.items()
    ])
    return ("\n" + exports + "\n") if exports else ""

def _uses_cfg6(dict):
    return "xpro" in dict or "dvcfg" in dict or "core" in dict

def run_shell(ctx, out, script_content, dict, env, script_name = None, additional_tools = None):
    s = script(ctx, script_name or ctx.label.name + ".sh", script_content, True, dict)
    tools = additional_tools
    if tools:
        tools.append(s)
    else:
        tools = [s]
    if _uses_cfg6(dict):
        tools.append(_cfg6(ctx).files)
    ctx.actions.run_shell(outputs = [out], inputs = input_files(dict), tools = tools, command = "./" + s.path, env = (env | ctx.attr._env_flag[BuildSettingInfo].value) if env else ctx.attr._env_flag[BuildSettingInfo].value, use_default_shell_env = True)
    return DefaultInfo(files = depset([out]))

def runfiles(ctx, dict):
    return ctx.runfiles(files = input_files(dict), transitive_files = _cfg6(ctx).files)

def _files(target):
    return [f for t in target for f in t[DefaultInfo].files.to_list()] if type(target) == _LIST_TYPE else target[DefaultInfo].files.to_list()

def input_files(dict):
    return [f for v in dict.values() if type(v) != _PRIMITIVE_TYPE for f in _files(v)]

def _parse_env_entry(entry):
    k, sep, v = entry.partition("=")
    if not sep or not k or k[0].isdigit() or not k.replace("_", "a").isalnum():
        fail("Expected KEY=VALUE for --@rules_cfg6//:env, got: " + entry)
    return k, v

env_flag = rule(
    doc = "Repeatable `KEY=VALUE` flag for environment variables applied to every call of a DaVinci Configurator executable.",
    implementation = lambda ctx: BuildSettingInfo(value = dict([_parse_env_entry(e) for e in ctx.build_setting_value])),
    build_setting = config.string_list(flag = True, repeatable = True)
)

def get_bash(repository_ctx):
    return repository_ctx.getenv("BAZEL_SH", "bash")

def _is_absolute(s):
    return s.startswith("/") or s.startswith("\\") or (len(s) > 2 and s[1] == ":" and (s[2] == "/" or s[2] == "\\"))

def absolute_path(repository_ctx, s):
    return repository_ctx.path(s) if _is_absolute(s) else repository_ctx.path(str(repository_ctx.workspace_root) + "/" + s)

def _version_from_pai_jar(path):
    result = path.basename
    if (result.startswith("automation-interface-") and result.endswith(".jar")):
        result = result[len("automation-interface-"):len(result) - 4]
        if (result.find("-") == -1):
            return result

def _pai_version(repository_ctx):
    libs_folder = repository_ctx.path("_/dvcfgpai/libs")
    for path in libs_folder.readdir():
        v = _version_from_pai_jar(path)
        if (v):
            return v
    fail("Failed to read PAI version from jars in {}.".format(libs_folder))

def default_http_archive_attrs(archive_name, *mutex_attrs):
    return {
        "url": attr.string(doc = "URL of the {} archive.{}".format(archive_name, " Mutually exclusive with `{}`.".format("`, `".join(mutex_attrs)) if mutex_attrs else ""), mandatory = len(mutex_attrs) == 0),
        "sha256": attr.string(doc = "SHA256 checksum of the {} archive.".format(archive_name)),
        "auth_patterns": attr.string_dict(doc = "Authorization patterns (see [http_archive](https://bazel.build/rules/lib/repo/http#http_archive-auth_patterns)).")
    }

def download_and_extract(repository_ctx, output, **kwargs):
    url = kwargs.get("url")
    if not url:
        url = repository_ctx.attr.url
    sha256 = kwargs.get("sha256")
    if not sha256 and hasattr(repository_ctx.attr, "sha256"):
        sha256 = repository_ctx.attr.sha256
    auth_patterns = kwargs.get("auth_patterns")
    if auth_patterns == None and hasattr(repository_ctx.attr, "auth_patterns"):
        auth_patterns = repository_ctx.attr.auth_patterns
    repository_ctx.download_and_extract(
        url = url,
        sha256 = sha256,
        auth = { url: auth_patterns } if auth_patterns else {},
        output = output
    )

def _cfg6_repo_files(repository_ctx):
    is_windows = repository_ctx.os.name.startswith("windows")
    ext, java = (".exe", "_/java-win/bin/java.exe") if is_windows else ("", "_/java-linux/bin/java")
    cli = repository_ctx.path("_/dvcfg" + ext)
    if is_windows:
        ret = repository_ctx.execute([cli, "initialize-installation"])
        if ret.return_code != 0:
            fail("dvcfg initialize-installation failed:\n" + ret.stdout + ret.stderr)
    else:
        _retry(
            lambda: repository_ctx.execute([java, "-XX:+UseCompactObjectHeaders", "-Xshare:dump"]),
            "CDS archive creation",
            10,
            lambda: repository_ctx.path("_/java-linux/lib/server/classes_coh.jsa").exists,
            True
        )
        _retry(
            lambda: repository_ctx.execute([cli, "initialize-installation"]),
            "dvcfg initialize-installation",
            10,
            lambda: repository_ctx.execute(["test", "-s", "./_/dvcfg.aot"]).return_code == 0
        )
    if is_windows:
        ret = repository_ctx.execute([get_bash(repository_ctx), "-c", str(cli) + ' -v'])
        if ret.return_code != 0:
            fail("""
ERROR: Failed to call DaVinci Configurator Classic Version 6 using '{}'.
Please configure a bash capable of windows-style paths in BAZEL_SH repo-env variable.
E.g. in .bazelrc: common:windows --repo_env=BAZEL_SH='<path>'

""".format(get_bash(repository_ctx)) + ret.stdout + ret.stderr)
    CFG6_PAI_VERSION = { "CFG6_PAI_VERSION": _pai_version(repository_ctx) }
    repository_ctx.template("BUILD.bazel", Label("cfg6_BUILD_template.bzl"), substitutions = { ".exe": ext })
    repository_ctx.template("defs.bzl", Label("cfg6_defs_template.bzl"))
    repository_ctx.template("rules.bzl", Label("cfg6_rules_template.bzl"), substitutions = CFG6_PAI_VERSION)

def _retry(call, description, retries, done, tolerate_failure = False):
    for _ in range(retries):
        ret = call()
        if ret.return_code == 0 and done():
            return
    if not tolerate_failure:
        fail("{} failed:\n{}{}".format(description, ret.stdout, ret.stderr))

def _fail_incompatible_version(required, actual):
    fail("Incompatible DaVinci Configurator Classic version {}. Current rules_cfg6 require {}. Please update DaVinci Configurator Classic.".format(actual.strip(), ".".join([str(v) for v in required])))

def _cfg6_archive_impl(repository_ctx):
    local_dvcfg6 = repository_ctx.getenv("LOCAL_DVCFG6")
    if local_dvcfg6:
        _local_cfg6_at_path(repository_ctx, local_dvcfg6)
        return
    if repository_ctx.os.name.startswith("windows"):
        download_and_extract(repository_ctx, "_download_", url = repository_ctx.attr.nupkg_url, sha256 = repository_ctx.attr.nupkg_sha256, auth_patterns = repository_ctx.attr.nupkg_auth_patterns)
        repository_ctx.extract(
            archive = "_download_/tools/archive.zip",
            output = "_"
        )
    else:
        prefix = repository_ctx.attr.url
        prefix = prefix[prefix.rindex("/") + len("vector-davinci-configurator-classic") + 1:-4].replace("-", "/")
        download_and_extract(repository_ctx, "_download_")
        repository_ctx.extract(
            archive = "_download_/data.tar.zst",
            output = "_",
            strip_prefix = "opt/vector-davinci-configurator-classic" + prefix
        )
    repository_ctx.delete("_download_")
    _cfg6_repo_files(repository_ctx)

cfg6_archive = repository_rule(
    doc = "Rule for using a DaVinci Configurator Classic Version 6 .nupkg or .deb archive. Use a locally installed DaVinci Configurator Classic Version 6 with `--repo_env=LOCAL_DVCFG6='<path>'`.",
    attrs = { "nupkg_" + k: v for k, v in default_http_archive_attrs(".nupkg", "url").items() } | default_http_archive_attrs(".deb", "nupkg_url"),
    implementation = _cfg6_archive_impl
)

def _local_cfg6_at_path(repository_ctx, s):
    repository_ctx.symlink(absolute_path(repository_ctx, s), "_")
    _cfg6_repo_files(repository_ctx)

def _local_cfg6_impl(repository_ctx):
    _local_cfg6_at_path(repository_ctx , repository_ctx.attr.path)

local_cfg6 = repository_rule(
    doc = "Rule for using a local DaVinci Configurator Classic Version 6 installation.",
    attrs = {
        "path": attr.string(doc = "Path (absolute or relative to workspace root) of the dvcfg install folder.", mandatory = True)
    },
    implementation = _local_cfg6_impl
)
