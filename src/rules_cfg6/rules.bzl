load("@rules_java//java:defs.bzl", "java_library")
load("@rules_java//java:java_single_jar.bzl", "java_single_jar")
load("@rules_java//java/common/rules:java_library.bzl", "JAVA_LIBRARY_ATTRS")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

def encode_eac_arg(arg):
    """JSON-encoding for EaC command line arguments.

    If the code takes a command line argument use this method to obtain a correctly encoded string to use in the command line call running the code.

    Args:
        arg: the argument passed to the code as JSON (using `json.encode`).

    Returns:
        a string containing the JSON-encoded argument.
        Insert this in the command line running the code directly after (no spaces) the path to the .jar file. E.g.:
        ```
        apply_command(
            name = "as_code",
            project = ":upstream",
            command = "{dvcfg} eac {-b} {-p} {-c}" + encode_eac_arg({ "my": "arg" }),
            inputs = { "-c": ":jar" },
        )
        ```
    """
    return "//" + json.encode(json.encode(arg)).replace("{", "{{").replace("}", "}}").replace("{{{{", "{").replace("}}}}", "}")

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

def single_file_from_target(target):
    l = target[DefaultInfo].files.to_list()
    if len(l) != 1:
        fail("Expected exactly one file from {} but got {}.".format(target.label, len(l)))
    return l[0]

def get_bash(repository_ctx):
    return repository_ctx.getenv("BAZEL_SH", "bash")

def _is_absolute(s):
    return s.startswith("/") or s.startswith("\\") or (len(s) > 2 and s[1] == ":" and (s[2] == "/" or s[2] == "\\"))

def absolute_path(repository_ctx, s):
    return repository_ctx.path(s) if _is_absolute(s) else repository_ctx.path(str(repository_ctx.workspace_root) + "/" + s)

Cfg6ToolProvider = provider()

ScriptTaskProvider = provider()

DvProjectProvider = provider()

def _cfg6_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(cfg6 = Cfg6ToolProvider(
        cli = ctx.attr.cli,
        xpro = ctx.attr.xpro,
        core = ctx.attr.core,
        settings_patcher = ctx.attr.settings_patcher[DefaultInfo].files_to_run,
    ))]

cfg6_toolchain = rule(
    implementation = _cfg6_toolchain_impl,
    attrs = {
        "cli": attr.label(mandatory = True),
        "xpro": attr.label(mandatory = True),
        "core": attr.label(mandatory = True),
        "settings_patcher": attr.label(executable = True, mandatory = True, cfg = "exec")
    }
)

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

def _cfg6_repo_files(repository_ctx):
    is_windows = repository_ctx.os.name.startswith("windows")
    ext = ".exe" if is_windows else ""
    cli = repository_ctx.path("_/dvcfg" + ext)
    if is_windows:
        ret = repository_ctx.execute([get_bash(repository_ctx), "-c", '"{}" -v'.format(cli)])
        if ret.return_code != 0:
            fail("\r\nERROR: Failed to call DaVinci Configurator Classic Version 6 from bash. Please use a bash capable of windows-style paths (e.g. git bash). " + ret.stderr)
    repository_ctx.template("BUILD.bazel", Label("cfg6_BUILD_template.bzl"), substitutions = { ".exe": ext })
    repository_ctx.template("defs.bzl", Label("cfg6_defs_template.bzl"))
    repository_ctx.template("rules.bzl", Label("cfg6_rules_template.bzl"), substitutions = { "CFG6_PAI_VERSION": _pai_version(repository_ctx) })
    return cli

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
    cli = _cfg6_repo_files(repository_ctx)
    repository_ctx.watch(cli.realpath)

def _local_cfg6_impl(repository_ctx):
    _local_cfg6_at_path(repository_ctx , repository_ctx.attr.path)

local_cfg6 = repository_rule(
    doc = "Rule for using a local DaVinci Configurator Classic Version 6 installation.",
    attrs = {
        "path": attr.string(doc = "Path (absolute or relative to workspace root) of the dvcfg install folder.", mandatory = True)
    },
    implementation = _local_cfg6_impl
)

_BSW_PKG_ATTR = { "bsw_pkg": attr.label(doc = "The BSW package folder.", allow_single_file = True, mandatory = True) }

def _generate_foundation_layer_script_impl(ctx):
    core = ctx.toolchains[":toolchain_type"].cfg6.core
    includelist, substitution = (' {--includelist}', { "--includelist": ctx.attr.filter }) if ctx.attr.filter else ("", {})
    dict = { "core": core, "-b": ctx.attr.bsw_pkg, "-o": ctx.attr.output } | substitution
    script = _script(ctx, ctx.label.name + ".sh", '{core} -application com.vector.cfg.bswmdmgen.app.flApplication {-b} --force {-o}' + includelist, False, dict)
    return [DefaultInfo(executable = script, runfiles = ctx.runfiles(files = _input_files(dict)).merge(core[DefaultInfo].default_runfiles))]

generate_foundation_layer_script = rule(
    attrs = _BSW_PKG_ATTR | {
        "output": attr.label(doc = "The destination folder for generated sources.", allow_single_file = True, mandatory = True),
        "filter": attr.label(doc = "Optional filter file containing the definition-references of all modules to be generated, separated by newlines. If this is not provided all modules of the BSW package are generated.", allow_single_file = True)
    },
    implementation = _generate_foundation_layer_script_impl,
    toolchains = [":toolchain_type"]
)

def _generate_foundation_layer_impl(name, visibility, tags, **kwargs):
    script_name = name + "_script"
    generate_foundation_layer_script(
        name = script_name,
        visibility = ["//visibility:private"],
        tags = ["no-ide"],
        **kwargs
    )
    sh_binary(
        name = name,
        srcs = [script_name],
        use_bash_launcher = True,
        visibility = visibility,
        tags = tags
    )

generate_foundation_layer = macro(
    doc = "Rule for generating the foundation layer API sources.",
    inherit_attrs = generate_foundation_layer_script,
    implementation = _generate_foundation_layer_impl
)

def _script_jar_impl(name, pai_version, script_classes, allow_beta, tags, visibility, **kwargs):
    lib_name = name + "_lib"
    java_library(
        name = lib_name,
        **kwargs
    )
    java_single_jar(
        name = name,
        deps = [lib_name],
        deploy_manifest_lines = [
            "DvCfg-AutomationInterfaceJars-Compile-Version: " + pai_version,
            "Automation-Classes: " + ",".join(script_classes),
            "DvCfg-AutomationInterface-AllowBetaApiUsage: " + ("true" if allow_beta else "false")
        ],
        tags = tags,
        visibility = visibility
    )

script_jar = macro(
    doc = "Internal macro for setting up a PAI project.",
    attrs = dict({ k: v for k, v in JAVA_LIBRARY_ATTRS.items() if not k.startswith("_") },
        pai_version = attr.string(mandatory = True, configurable = False),
        script_classes = attr.string_list(doc = "ScriptFactory class names.", mandatory = True, allow_empty = False, configurable = False),
        tags = attr.string_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/common-definitions#common-attributes)", configurable = False),
        allow_beta = attr.bool(doc = "Whether to allow usage of beta PAI APIs.", configurable = False)
    ),
    implementation = _script_jar_impl
)

def _exclusive_label(ctx):
    return { "DVCFG_EXCLUSIVE_LABEL": str(ctx.label) }

_PRIMITIVE_TYPE = type("")
_LIST_TYPE = type([])

def _system_extract_impl(ctx):
    xpro = ctx.toolchains[":toolchain_type"].cfg6.xpro
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    dict = { "xpro": xpro, "-i": ctx.attr.src, "ecu": ctx.attr.ecu or ctx.label.name, "out": out.path }
    script = _script(ctx, ctx.label.name + ".sh", "{xpro} extract-sysd {-i} -e {ecu} '{out}'", True, dict)
    ctx.actions.run_shell(outputs = [out], inputs = _input_files(dict), tools = _files(xpro) + [script], command = "./" + script.path, env = _exclusive_label(ctx), use_default_shell_env = True)
    return [DefaultInfo(files = depset([out]))]

system_extract = rule(
    doc = "Rule for extracting a given ECU from a system description.",
    attrs = {
        "src": attr.label(doc = "The system description .arxml files from which to extract the given ECU.", allow_files = [".arxml"], mandatory = True),
        "ecu": attr.string(doc = "The ECU to extract from the given system description (defaults to rule name).")
    },
    implementation = _system_extract_impl,
    toolchains = [":toolchain_type"]
)

def _merged_extract_impl(ctx):
    xpro = ctx.toolchains[":toolchain_type"].cfg6.xpro
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    dict = { "xpro": xpro, "-i": ctx.attr.src, "out": out.path }
    script = _script(ctx, ctx.label.name + ".sh", "{xpro} merge {-i} '{out}'", True, dict)
    ctx.actions.run_shell(outputs = [out], inputs = _input_files(dict), tools = _files(xpro) + [script], command = "./" + script.path, env = _exclusive_label(ctx), use_default_shell_env = True)
    return [DefaultInfo(files = depset([out]))]

merged_extract = rule(
    doc = "Rule for merging multiple .arxml files into an ECU extract.",
    attrs = {
        "src": attr.label(doc = "The .arxml files to merge into one ECU extract.", allow_files = [".arxml"], mandatory = True),
    },
    implementation = _merged_extract_impl,
    toolchains = [":toolchain_type"]
)

def _variant_extract_impl(ctx):
    xpro = ctx.toolchains[":toolchain_type"].cfg6.xpro
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    dict = { "_xpro": xpro, "-m": ctx.attr.config, "_evs|,": ctx.attr.evs, "_out": out.path } | ctx.attr.srcs
    cmd = '{_xpro} variant-merge {-m} -e {_evs} '
    for variant in ctx.attr.srcs.keys():
        cmd += '-f {v}={{{v}}} '.format(v = variant)
    script = _script(ctx, ctx.label.name + ".sh", cmd + '"{_out}"', True, dict)
    ctx.actions.run_shell(outputs = [out], inputs = _input_files(dict), tools = _files(xpro) + [script], command = "./" + script.path, env = _exclusive_label(ctx), use_default_shell_env = True)
    return [DefaultInfo(files = depset([out]))]

variant_extract = rule(
    doc = "Rule for creating a variant ECU extract from invariant extracts.",
    attrs = {
        "evs": attr.label(doc = "The .arxml files containing the EvaluatedVariantSet.", allow_files = [".arxml"], mandatory = True),
        "srcs": attr.string_keyed_label_dict(doc = 'One extract file for each variant in the EvaluatedVariantSet. E.g.: { "VariantA": ":ExtractA", ... }', allow_files = [".arxml"], allow_empty = False, mandatory = True),
        "config": attr.label(doc = "The merge configuration .xml file.", allow_single_file = [".xml"], mandatory = True)
    },
    implementation = _variant_extract_impl,
    toolchains = [":toolchain_type"]
)

def _task_name(task):
    return task[ScriptTaskProvider].task_name.replace('"', '\\"')

def _task_args(ctx):
    result = ""
    for task in ctx.attr.tasks:
        task_provider = task[ScriptTaskProvider]
        args = " ".join(['\\"' + arg.replace('"', '\\\\"') + '\\"' for arg in task_provider.args])
        file_args = " ".join(['\\"{}\\" \\"{}\\"'.format(arg.replace('"', '\\\\"'), single_file_from_target(value).path) for arg, value in task_provider.file_args.items()])
        if file_args:
            args = args + " " + file_args
        if args:
            result += ' -a "{}" -a "{}"'.format(_task_name(task), args)
    return result

def _script_patched_arxml_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    file_args = [single_file_from_target(target) for task in ctx.attr.tasks for target in task[ScriptTaskProvider].file_args.values()]
    xpro = ctx.toolchains[":toolchain_type"].cfg6.xpro
    dict = {
        "xpro": xpro,
        "src": ctx.files.srcs[0].path,
        "evs":  " -e '{}'".format("','".join([file.path for file in ctx.files.srcs[1:]])) if len(ctx.files.srcs) > 1 else "",
        "scripts|,": ctx.attr.tasks,
        "tasks": "','".join([_task_name(task) for task in ctx.attr.tasks]),
        "args": _task_args(ctx),
        "out": out.path
    }
    script = _script(ctx, ctx.label.name + ".sh", "{xpro} run-script -i '{src}'{evs} -l '{scripts}' -t '{tasks}'{args} '{out}'", True, dict)
    ctx.actions.run_shell(outputs = [out], inputs = _input_files(dict) + file_args + ctx.files.srcs, tools = _files(xpro) + [script], command = "./" + script.path, env = _exclusive_label(ctx), use_default_shell_env = True)
    return [DefaultInfo(files = depset([out]))]

_SCRIPT_PATCHED_ARXML_ATTRS = {
    "srcs": attr.label_list(doc = "The .arxml files to be patched.", allow_files = [".arxml"], default = [Label("empty.arxml")]),
    "tasks": attr.label_list(doc = 'The tasks to execute (see [script_task](#script_task)).', providers = [ScriptTaskProvider], allow_empty = False, mandatory = True)
}

script_patched_arxml = rule(
    doc = "Rule for patching .arxml file content by applying a script task.",
    attrs = _SCRIPT_PATCHED_ARXML_ATTRS,
    implementation = _script_patched_arxml_impl,
    toolchains = [":toolchain_type"]
)

def _arxml_patcher_src_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".java")
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = out,
        substitutions = {
            "ArxmlPatcher": ctx.label.name,
            "// CALL": ctx.attr.call
        }
    )
    return [DefaultInfo(files = depset([out]))]

_CALL_ATTR = attr.string(doc = "The task call. Must be self-contained (i.e. not requiring any imports). E.g.: call a zero-argument public static void method using a fully qualified class name.", mandatory = True)

arxml_patcher_src = rule(
    doc = "Internal rule for creating a .java file defining a task to be used in `script_patched_arxml`.",
    attrs = {
        "call": _CALL_ATTR,
        "_template": attr.label(default = Label("ArxmlPatcher.java"), allow_single_file = True)
    },
    implementation = _arxml_patcher_src_impl
)

def _arxml_patch_impl(name, srcs, call, visibility, **kwargs):
    arxml_patcher_src_name = name + "_arxml_patcher_src"
    arxml_patcher_src(
        name = arxml_patcher_src_name,
        call = call
    )
    script_jar_name = name + "_script_jar"
    script_jar(
        name = script_jar_name,
        script_classes = [arxml_patcher_src_name],
        srcs = srcs + [arxml_patcher_src_name],
        **kwargs
    )
    script_task(
        name = name,
        script = script_jar_name,
        task_name = "patch",
        visibility = visibility
    )

arxml_patch = macro(
    doc = "Internal macro for creating a task to be used in rule `script_patched_arxml`.",
    inherit_attrs = script_jar,
    attrs = {
        "script_classes": None,
        "srcs": attr.label_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/java#java_library)", configurable = False),
        "call": _CALL_ATTR
    },
    implementation = _arxml_patch_impl
)

def _extract_evs_impl(name, pai, pai_version, short_name_path, **kwargs):
    arxml_patch_name = name + "_arxml_patch"
    arxml_patch(
        name = arxml_patch_name,
        srcs = [Label("EvsExtractor.java")],
        call = 'EvsExtractor.run("{}")'.format(short_name_path),
        deps = [pai],
        pai_version = pai_version
    )
    script_patched_arxml(
        name = name,
        tasks = [arxml_patch_name],
        **kwargs
    )

_PATCHER_MACRO_ATTRS = {
   "srcs": _SCRIPT_PATCHED_ARXML_ATTRS["srcs"],
   "pai": attr.label(mandatory = True, configurable = False),
   "pai_version": attr.string(mandatory = True, configurable = False)
}

extract_evs = macro(
    doc = "Internal macro for extracting a single EvaluatedVariantSet from an .arxml file containing multiple EvaluatedVariantSets.",
    attrs = dict(_PATCHER_MACRO_ATTRS, short_name_path = attr.string(doc = "The short name path of the EvaluatedVariantSet to extract.", mandatory = True, configurable = False)),
    implementation = _extract_evs_impl
)

def _merged_arxml_impl(name, pai, pai_version, **kwargs):
    arxml_patch_name = name + "_no_patch"
    arxml_patch(
        name = arxml_patch_name,
        call = "// JUST MERGE - NO PATCH",
        deps = [pai],
        pai_version = pai_version
    )
    script_patched_arxml(
        name = name,
        tasks = [arxml_patch_name],
        **kwargs
    )

merged_arxml = macro(
    doc = "Internal macro for merging .arxml files.",
    attrs = _PATCHER_MACRO_ATTRS,
    implementation = _merged_arxml_impl
)

def _script_task_impl(ctx):
    return [
        DefaultInfo(files = depset([ctx.file.script])),
        ScriptTaskProvider(task_name = ctx.attr.task_name or ctx.label.name, args = ctx.attr.args, file_args = ctx.attr.file_args)
    ]

script_task = rule(
    doc = "Rule for selecting a script task from a script and optionally provide command line arguments for the task.",
    attrs = {
        "script": attr.label(doc = 'Location of the script (".dv.groovy" file, ".jar" file or folder).', allow_single_file = True, mandatory = True),
        "task_name": attr.string(doc = "The task name (defaults to rule name)."),
        "args": attr.string_list(doc = "Optional arguments for the script task."),
        "file_args": attr.string_keyed_label_dict(doc = "Optional file arguments for the script task (keys are arg names).", allow_files = True)
    },
    implementation = _script_task_impl
)

def _create_project_script_impl(ctx):
    cli = ctx.toolchains[":toolchain_type"].cfg6.cli
    dict = { "dvcfg": cli, "-b": ctx.attr.bsw_pkg, "name": ctx.attr.dvjson_name, "folder": ctx.label.package }
    script = _script(ctx, ctx.label.name + ".sh", '{dvcfg} project create {-b} --project-name {name} -o "$BUILD_WORKSPACE_DIRECTORY/{folder}"', False, dict)
    return [DefaultInfo(executable = script, runfiles = ctx.runfiles(files = _input_files(dict)).merge(cli[DefaultInfo].default_runfiles))]

create_project_script = rule(
    attrs = {
        "bsw_pkg": attr.label(allow_single_file = True, mandatory = True),
        "dvjson_name": attr.string(mandatory = True)
    },
    implementation = _create_project_script_impl,
    toolchains = [":toolchain_type"]
)

def _dvjson_impl(name, bsw_pkg, **kwargs):
    script_name = name + "_create_script"
    create_project_script(
        name = script_name,
        bsw_pkg = bsw_pkg,
        dvjson_name = name
    )
    sh_binary(
        name = name + "_create",
        srcs = [script_name],
        use_bash_launcher = True,
    )
    native.exports_files([name + ".dvjson"])

dvjson = macro(
    doc = """Macro for declaring a DaVinci project.

Best instantiated within an otherwise empty package, like this:

```starlark
load("@rules_cfg6//:defs.bzl", "dvjson")
dvjson(
    name = "myecu",
    bsw_pkg = "@sip_myecu//:bsw_pkg",
)
```

Now `bazel run //:myecu` will create a new project
See [hybrid](#hybrid) on how to use this project in the pipeline.""",
    attrs = {
        "bsw_pkg": attr.label(doc = "The BSW package folder.", allow_single_file = True, mandatory = True)
    },
    implementation = _dvjson_impl
)

_dbg_script_postfix = "_dbg_script"

def _app_design_dbg_script_impl(ctx):
    command = """
if [[ "${{EAC_DEBUG-}}" == "true" ]]; then
    export DVCFG_JVM_ARGS='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n -Djdk.attach.allowAttachSelf=true'
    export IDE_INTEGRATION_PORT="${{EAC_IDE_PORT-}}"
fi
_term() {{
    kill "$child" 2>/dev/null
}}
trap _term SIGINT
{xpro} run-script -i {input} {-l} -t '{task}' "$BUILD_WORKSPACE_DIRECTORY/{pkg}/{name}.arxml" &
child=$!
wait "$child"
"""
    xpro = ctx.toolchains[":toolchain_type"].cfg6.xpro
    dict = { "xpro": xpro, "input| -e ": ctx.attr.srcs, "-l": ctx.attr.tasks, "task": ctx.attr.task_name, "pkg": ctx.label.package, "name": ctx.label.name[:-len(_dbg_script_postfix)] }
    script = _script(ctx, ctx.label.name + ".sh", command, False, dict)
    return [DefaultInfo(executable = script, runfiles = ctx.runfiles(files = _input_files(dict)).merge(xpro[DefaultInfo].default_runfiles))]

_APP_DESIGN_ATTRS = dict(
    _SCRIPT_PATCHED_ARXML_ATTRS,
    task_name = attr.string(default = "AppDesign")
)

app_design_dbg_script = rule(
    attrs = _APP_DESIGN_ATTRS,
    implementation = _app_design_dbg_script_impl,
    toolchains = [":toolchain_type"]
)

def _app_design_impl(name, code, script_classes, task_name, pai_version, **kwargs):
    script_jar_name = name + "_script_jar"
    script_jar(
        name = script_jar_name,
        script_classes = script_classes,
        runtime_deps = code,
        pai_version = pai_version,
        tags = ["manual"]
    )
    script_task_name = name + "_script_task"
    script_task(
        name = script_task_name,
        script = script_jar_name,
        task_name = task_name
    )
    tasks = [script_task_name]
    script_patched_arxml(
        name = name,
        tasks = tasks,
        **kwargs
    )
    dbg_script_name = name + _dbg_script_postfix
    app_design_dbg_script(
        name = dbg_script_name,
        tasks = tasks,
        task_name = task_name,
        **{ k: kwargs[k] for k in _SCRIPT_PATCHED_ARXML_ATTRS.keys() if k != "tasks" }
    )
    sh_binary(
        name = name + "_dbg",
        srcs = [dbg_script_name],
        use_bash_launcher = True,
    )

app_design = macro(
    doc = "Internal macro for setting up an AppDesign project.",
    inherit_attrs = script_patched_arxml,
    attrs = dict(_APP_DESIGN_ATTRS,
        tasks = None,
        code = JAVA_LIBRARY_ATTRS["runtime_deps"],
        script_classes = attr.string_list(default = ["AppDesign"], configurable = False),
        pai_version = attr.string(mandatory = True, configurable = False)
    ),
    implementation = _app_design_impl
)

def _expand_file_paths_impl(ctx):
    t = ctx.file.template
    out = ctx.actions.declare_file(ctx.label.name + (t.extension if t.extension and len(t.extension) < len(t.basename) - 1 else ""))
    ctx.actions.expand_template(
        t,
        out,
        substitutions = { k: single_file_from_target(v).path.replace("\\", "/") for k, v in ctx.attr.substitutions.items() }
    )
    return [DefaultInfo(files = depset([out]))]

expand_file_paths = rule(
    doc = "Expand file paths in a template.",
    attrs = {
        "template": attr.label(doc = "The UTF-8 encoded template file.", allow_single_file = True),
        "substitutions": attr.string_keyed_label_dict(doc = "Files whose paths to expand in the template.", allow_files = True)
    },
    implementation = _expand_file_paths_impl,
)

def _to_paths(ctx, target, build):
    paths = [p for t in target for p in ctx.expand_location("$({} {})".format("locations" if build else "rlocationpaths", t.label), [t]).split(" ")] if type(target) == _LIST_TYPE else ctx.expand_location("$({} {})".format("locations" if build else "rlocationpaths", target.label), [target]).split(" ")
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

def _item(ctx, item, build):
    k, v = item
    if type(v) == _PRIMITIVE_TYPE:
        return item
    if k.startswith("-"):
        return (k, k + " " + (" " + k + " ").join(_to_paths(ctx, v, build)))
    key_and_sep = k.split("|")
    if len(key_and_sep) != 2:
        key_and_sep = [k, " "]
    return (key_and_sep[0], key_and_sep[1].join(_to_paths(ctx, v, build)))

def _format_dict(ctx, dict, build):
    return { k: v for k, v in [_item(ctx, i, build) for i in dict.items()] }

def _files(target):
    return [f for t in target for f in t[DefaultInfo].files.to_list()] if type(target) == _LIST_TYPE else target[DefaultInfo].files.to_list()

def _input_files(dict):
    return [f for v in dict.values() if type(v) != _PRIMITIVE_TYPE for f in _files(v)]

_PREPARE_FOLDER = "rm -rf '{_parent_dir_}'\nmkdir -p '{project_dir}'\n"
_UNTAR = "tar --force-local -zxf {_upstream_} -C '{project_dir}'\n"
_COMMON_TAR_OPTS = "--force-local --exclude '*.~lock' --exclude 'dvcfg.local.properties'"
_TAR = "\ntar " + _COMMON_TAR_OPTS + " -zcf '{_parent_dir_}/dvproject.tar.gz' -C '{project_dir}' .\nrm -rf '{project_dir}'"
_STOP = '\n{dvcfg} stop {-p} --force'

def _script(ctx, name, cmd, build, dict):
    script = ctx.actions.declare_file(name)
    ctx.actions.write(script, 'set -euo pipefail\n' + cmd.format(**_format_dict(ctx, dict, build)), is_executable = True)
    return script

def _from_scratch_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "/dvproject.tar.gz")
    cfg6 = ctx.toolchains[":toolchain_type"].cfg6
    cmd = _PREPARE_FOLDER + "{dvcfg} project create {-b} --project-name {name} -o '{project_dir}'"
    dict = { "_parent_dir_": out.dirname, "project_dir": out.dirname + "/_", "dvcfg": cfg6.cli, "-b": ctx.attr.bsw_pkg, "name": ctx.label.name }
    if ctx.attr.settings:
        cmd += "\n'{patcher}' '{project_dir}/{name}.dvjson' {settings}"
        dict.update(patcher = cfg6.settings_patcher.executable.path, settings = ctx.attr.settings)
    script = _script(ctx, ctx.label.name + "/script.sh", cmd + _TAR, True, dict)
    ctx.actions.run_shell(outputs = [out], inputs = _input_files(dict), tools = _files(cfg6.cli) + [script] + ([cfg6.settings_patcher] if ctx.attr.settings else []), command = "./" + script.path, use_default_shell_env = True, env = _exclusive_label(ctx))
    return [DefaultInfo(files = depset([out])), DvProjectProvider(dvjson = ctx.label.name + ".dvjson", bsw_pkg = ctx.attr.bsw_pkg)]

from_scratch = rule(
    doc = "Create a new DaVinci Configurator Classic Version 6 project.",
    attrs = _BSW_PKG_ATTR | {
        "settings": attr.label(doc = """Optional JSON file for overriding default project settings.
E.g., for setting `allowMergeConflicts` in the `General.json` file to `true` and removing the mapping for the `Dcm` module from the `moduleDefinitionMappings` array in the `Ifp.json` file:

```json
{
  "general": {
    "allowMergeConflicts": true
  },
  "ifp": {
    "moduleDefinitionMappings": [
      { "__delete__": true, "moduleConfigName": "Dcm" }
    ]
  }
}
```

Each object-typed property is merged into the settings file referenced by the .dvjson file with the corresponding key:

- Object-typed properties are merged recursively.
- Primitive-typed properties are overwritten with the given value (use `null` to delete the property).
- Arrays with primitive-typed elements are merged as duplicate-free unions.
- Objects in arrays are identified by a key property:
  - In `General.json`, `useCases` are identified by their `vector` property.
  - In `Ifp.json`, `moduleDefinitionMappings` are identified by their `moduleConfigName` (see example) and `comControllerMappings` by their `clusterPath`.
  - Use the `__delete__` property (see example) to remove an object from the array.

Some settings might point to generated files. Use [expand_file_paths](#expand_file_paths) for these.""", allow_single_file = [".json"])
    },
    implementation = _from_scratch_impl,
    toolchains = [":toolchain_type"]
)

def _hybrid_impl(ctx):
    dvjson_target = [t for t in ctx.attr.srcs if [f for f in t[DefaultInfo].files.to_list() if f.extension == "dvjson"]]
    if len(dvjson_target) != 1:
        fail("Expected a single .dvjson file in srcs.")
    dvjson_target = dvjson_target[0]
    if dvjson_target.label.repo_name:
        fail("The .dvjson file must reside in the workspace.")
    dvjson_file = [f for f in dvjson_target[DefaultInfo].files.to_list() if f.extension == "dvjson"]
    if len(dvjson_file) != 1:
        fail("Expected a single .dvjson file in srcs.")
    dvjson_file = dvjson_file[0]
    if not dvjson_file.is_source:
        fail("The .dvjson files must be a source file and no generated target.")
    prefix = dvjson_file.dirname + "/"
    if [f for f in ctx.files.srcs if not f.path.startswith(prefix)]:
        fail("All srcs must be contained below the folder containing the .dvjson file.")
    out = ctx.actions.declare_file(ctx.label.name + "/dvproject.tar.gz")
    exclude = (" --exclude '" + "' --exclude '".join(ctx.attr.exclude) + "'") if ctx.attr.exclude else ""
    copy = "tar " + _COMMON_TAR_OPTS + exclude + " -cf - -C '{source}' . | tar --force-local -xf - -C '{project_dir}'"
    script = _script(ctx, ctx.label.name + "/script.sh", _PREPARE_FOLDER + copy + _TAR, True, { "_parent_dir_": out.dirname, "project_dir": out.dirname + "/_", "source": dvjson_file.dirname })
    ctx.actions.run_shell(outputs = [out], inputs = ctx.files.srcs, tools = [script], command = "./" + script.path, use_default_shell_env = True)
    return [DefaultInfo(files = depset([out])), DvProjectProvider(dvjson = dvjson_file.basename, bsw_pkg = ctx.attr.bsw_pkg, hybrid = dvjson_file.dirname)]

hybrid = rule(
    doc = "Use an existing DaVinci Configurator Classic Version 6 project.",
    attrs = _BSW_PKG_ATTR | {
        "srcs": attr.label_list(doc = """The files of an existing project.

- The .dvjson file (always required).
- All settings .json files (referenced by the .dvjson file).

All of these files must be contained below the parent folder of the .dvjson file.
Modifications to any of these files invalidate the target.

Usually a `hybrid` target is extended using [apply_command](#apply_command).
If the project folder contains files, that are modified through different tools,
these files should be listed as inputs of the `apply_command` target that needs to re-run after the modification.

Typically, this is the `project update` command. I.e., if your workflow requires modifying user ECUC files
(in `./Config/EcuConfig`) through some other tool capture all relevant files in some label and list them as an input to the command:

```starlark
filegroup(name = "user_ecuc", srcs = glob(["Config/EcuConfig/**"]), visibility = ["//visibility:public"])

apply_command(
    name = "project",
    project = ":upstream",
    command = '{dvcfg} project update {-p} {-b}',
    inputs = { "user_ecuc": ":user_ecuc" }
)
```

Even if the files are not used in the command they will invalidate the target when getting modified.""", allow_files = True),
        "exclude": attr.string_list(doc = "Optional GNU tar exclude patterns listing all project files/folders that should be excluded from the target (no trailing slashes for folders).", default = ["./Output"])
    },
    implementation = _hybrid_impl
)

def _check_keys(built_in, user):
    clashes = [k for k in user.keys() if k in built_in]
    clashes and fail("The following keys are reserved for internal purposes: {}. Please choose different ones.".format(", ".join(clashes)))
    return built_in | user

_COMMAND_ATTRS = {
    "command": attr.string(doc = """Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell)).
Use `{dvcfg}` for the DaVinci Configurator Classic Version 6 executable, `{-p}` for the project and `{-b}` for the BSW package.
E.g., the command to update the project looks like this: `{dvcfg} project update {-b} {-p}`.
Separate multiple commands to run sequentially with `\\n` (newline).""", mandatory = True),
    "inputs": attr.string_keyed_label_dict(doc = """Input files used in `command`. The following rules apply:

- Dictionary keys starting with `-` (minus): `inputs = { "-f": "<label>" }` and `command = '... {-f} ...'` yield a resulting command line like this: `... -f "<file1>" -f "{file2}" ...` (i.e., all files are listed with the preceeding switch).
- Dictionary keys containing `|` (pipe): `inputs = { "files|,": "<label>" }` and `command = '... -f {files} ...'` yield a resulting command line like this: `... -f "<file1>","{file2}" ...` (i.e, all files are listed, joined by the given separator).
- Pipe and separator are optional defaulting to a single space separator, i.e.: `inputs = { "files": "<label>" }` and `command = 'import {files}'` yield a resulting command line like this: `import "<file1>" "{file2}" ...`.""", allow_files = True)
}

def _is_update(s):
    s = s.lstrip("\"' \t")
    if not s.startswith("project"):
        return False
    s = s[7:]
    remainder = s.lstrip(" \t")
    return len(remainder) < len(s) and remainder.startswith("update")

def _is_hybrid_update(ctx):
    return hasattr(ctx.attr.project[DvProjectProvider], "hybrid") and [c for c in ctx.attr.command.split("{dvcfg}") if _is_update(c)]

def _apply_dict(ctx, out, project):
    p = project[DvProjectProvider]
    return {
        "_upstream_": project,
        "_parent_dir_": out.dirname,
        "project_dir": out.dirname + "/_",
        "dvcfg": ctx.toolchains[":toolchain_type"].cfg6.cli,
        "-b": p.bsw_pkg,
        "-p": "-p '" + out.dirname + "/_/" + p.dvjson + "'",
    }

def _apply_command_impl(ctx):
    p = ctx.attr.project[DvProjectProvider]
    out = ctx.actions.declare_file(ctx.label.name + "/dvproject.tar.gz")
    hybrid = "cp -r '{}/.' '{{project_dir}}'\n".format(p.hybrid) if _is_hybrid_update(ctx) else ""
    dict = _check_keys(_apply_dict(ctx, out, ctx.attr.project), ctx.attr.inputs)
    script = _script(ctx, ctx.label.name + "/script.sh", _PREPARE_FOLDER + hybrid + _UNTAR + ctx.attr.command + _STOP + _TAR, True, dict)
    ctx.actions.run_shell(outputs = [out], inputs = _input_files(dict), tools = _files(ctx.toolchains[":toolchain_type"].cfg6.cli) + [script], command = "./" + script.path, env = ctx.attr.env, use_default_shell_env = True)
    return [DefaultInfo(files = depset([out])), p]

apply_command = rule(
    doc = """Extend a project by running a command on it (see [here](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/references/cli/index.html) for available commnds). E.g.:

- `{dvcfg} project update {-b} {-p}` updates the project (e.g. on input file changes).
- `{dvcfg} project validate {-b} {-p} --fail-on NONE` creates a validation report. [project_file](#project_file) with `path = "Output/Log/ValidationOutput.json"` yields the report.
- `{dvcfg} project generate {-b} {-p}` generates BSW code. [project_folder](#project_folder) with `path = "Output/Source/GenData"` yields the generation result.
- `{dvcfg} project generate-swct {-b} {-p}` generates SWC templates. [project_folder](#project_folder) with `path = "Output/Source/Templates"` yields the generation result.
- `{dvcfg} automation run {-b} {-p} {-l} -t MyTask` runs a PAI task (see `inputs` on how to provide the script location `{-l}`).
- `{dvcfg} export run {-b} {-p} -o "{project_dir}" -e everything` exports the entire AUTOSAR model. [project_file](#project_file) with `path = "Exported_everything.arxml"` yields the result.

`{project_dir}` is expanded to the project folder (unquoted; useful for specifying output locations).""",
    attrs = {
        "project": attr.label(doc = "The project to which to apply the command.", allow_single_file = True, providers = [DvProjectProvider], mandatory = True),
        "env": attr.string_dict(doc = "Optional environment variables.")
    } | _COMMAND_ATTRS,
    implementation = _apply_command_impl,
    toolchains = [":toolchain_type"]
)

def _run_command_script_impl(ctx):
    cli = ctx.toolchains[":toolchain_type"].cfg6.cli
    cmd = ctx.attr.command
    dict = {
        "_upstream_": ctx.attr.project,
        "_parent_dir_": ctx.label.name,
        "project_dir": ctx.label.name + "/_",
        "dvcfg": cli
    }
    if ctx.attr.project:
        p = ctx.attr.project[DvProjectProvider]
        dvjson = ctx.label.name + "/_/" + p.dvjson
        if hasattr(p, "hybrid"):
            hybrid_dir = "$BUILD_WORKSPACE_DIRECTORY/{}".format(p.hybrid)
            dvjson = hybrid_dir + "/" + p.dvjson
            dict = dict | { "hybrid_dir": hybrid_dir }
            cmd = 'cp -r "{project_dir}/." "{hybrid_dir}"\n' + cmd.replace("{project_dir}", "{hybrid_dir}")
        dict = dict | { "-b": p.bsw_pkg, "-p": "-p '{}'".format(dvjson) }
    dict = _check_keys(dict, ctx.attr.inputs)
    script = _script(ctx, ctx.label.name + "/script.sh", _PREPARE_FOLDER + _UNTAR + cmd, False, dict)
    return [DefaultInfo(executable = script, runfiles = ctx.runfiles(files = _input_files(dict)).merge(cli[DefaultInfo].default_runfiles))]

run_command_script = rule(
    attrs = { "project": attr.label(doc = "The project on which to run the command. Only required if the command needs a project.", allow_single_file = True, providers = [DvProjectProvider]) } | _COMMAND_ATTRS,
    implementation = _run_command_script_impl,
    toolchains = [":toolchain_type"]
)

def _run_command_impl(name, project, command, inputs, **kwargs):
    script_name = name + "_script"
    run_command_script(
        name = script_name,
        project = project,
        command = command,
        inputs = inputs
    )
    sh_binary(
        name = name,
        srcs = [script_name],
        use_bash_launcher = True,
        **kwargs
    )

run_command = macro(
    doc = """Run a command on a project (see [here](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/references/cli/index.html) for available commnds). When running on an hybrid project, the resulting project is written back to the workspace. E.g.:

- `{dvcfg} project validate {-b} {-p} --fail-on NONE` creates a validation report.
- `{dvcfg} project generate {-b} {-p}` generates BSW code.
- `{dvcfg} project generate-swct {-b} {-p}` generates SWC templates.
- `{dvcfg} automation run {-b} {-p} {-l} -t MyTask` runs a PAI task (see `inputs` on how to provide the script location `{-l}`).
- `{dvcfg} export run {-b} {-p} -o "$BUILD_WORKSPACE_DIRECTORY/export" -e everything` exports the entire AUTOSAR model.

Use `$BUILD_WORKSPACE_DIRECTORY` to specify locations relative to the workspace.""",
    inherit_attrs = run_command_script,
    attrs = {
        "env": attr.string_dict(doc = "Optional environment variables.")
    },
    implementation = _run_command_impl
)

def _project_file_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out or ctx.label.name)
    path = ctx.attr.path.replace("\\", "/")
    if not path.startswith("./"):
        path = "./" + path
    ctx.actions.run_shell(outputs = [out], inputs = [ctx.file.project], command = "tar --force-local -xzOf '{}' '{}' > '{}'".format(ctx.file.project.path, path, out.path))
    return [DefaultInfo(files = depset([out]))]

project_file = rule(
    doc = "Get a file from a project.",
    attrs = {
        "project": attr.label(doc = "The project from which to get the file.", allow_single_file = True, mandatory = True),
        "path": attr.string(doc = "The path of the file relative to the project folder.", mandatory = True),
        "out": attr.string(doc = "Optional name for the created file (defaults to label name).")
    },
    implementation = _project_file_impl
)

def _project_folder_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name)
    path = ctx.attr.path.replace("\\", "/")
    if path and not path.startswith("./"):
        path = "./" + path
    cmd = "tar --force-local -xzf '{}' -C '{}' --strip-components {} '{}'".format(ctx.file.project.path, out.path, path.count("/") + 1, path)
    ctx.actions.run_shell(outputs = [out], inputs = [ctx.file.project], command = cmd)
    return [DefaultInfo(files = depset([out]))]

project_folder = rule(
    doc = "Get a folder from a project.",
    attrs = {
        "project": attr.label(doc = "The project from which to get the folder.", allow_single_file = True, mandatory = True),
        "path": attr.string(doc = "The path of the folder relative to the project folder.")
    },
    implementation = _project_folder_impl
)

def _list_project_files_script_impl(ctx):
    dict = { "project": ctx.attr.project }
    script = _script(ctx, ctx.label.name + ".sh", "tar --force-local -tzf {project} | sed -e '/\\/$/d' -e 's|^\\./||'", False, dict)
    return [DefaultInfo(executable = script, runfiles = ctx.runfiles(files = _input_files(dict)))]

list_project_files_script = rule(
    attrs = { "project": attr.label(doc = "The project whose files to list.", allow_single_file = True, mandatory = True) },
    implementation = _list_project_files_script_impl
)

def _list_project_files_impl(name, project, **kwargs):
    script_name = name + "_script"
    list_project_files_script(
        name = script_name,
        project = project
    )
    sh_binary(
        name = name,
        srcs = [script_name],
        use_bash_launcher = True,
        **kwargs
    )

list_project_files = macro(
    doc = "List all files contained in a project (paths relative to the project folder, usable as `path` in [project_file](#project_file)). Run with `bazel run`.",
    inherit_attrs = list_project_files_script,
    implementation = _list_project_files_impl
)

_COPY = """_copy() {{
  local dst="$2"
  if [[ "$dst" == */ ]]; then
    dst="$dst$(basename "$1")"
  fi
  if [[ -d "$1" ]]; then
    mkdir -p "$dst"
    cp -R "$1/." "$dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$1" "$dst"
  fi
}}"""

def _copy_files_script_impl(ctx):
    cmd = _COPY
    for name, value in ctx.attr.env.items():
        cmd += '\n{}="{}"'.format(name, value.replace('"', '\\"'))
    dict = {}
    i = 0
    for target, dst in ctx.attr.from_to.items():
        dst = dst.replace("\\", "/")
        if not dst.endswith("/") and len(target[DefaultInfo].files.to_list()) != 1:
            fail("Expected exactly one file/folder from {} for destination '{}' but got {} (use a trailing '/' to copy into a folder).".format(target.label, dst, len(target[DefaultInfo].files.to_list())))
        source = "src_" + str(i)
        i += 1
        dict.update([(source, target)])
        cmd += '\n_copy {{{}}} {}'.format(source, ("'{}'" if _is_absolute(dst) else '"$BUILD_WORKSPACE_DIRECTORY/{}"').format(dst))
    script = _script(ctx, ctx.label.name + ".sh", cmd, False, dict)
    return [DefaultInfo(executable = script, runfiles = ctx.runfiles(files = _input_files(dict)))]

copy_files_script = rule(
    attrs = {
        "from_to": attr.label_keyed_string_dict(doc = """Files/folders to copy (label -> destination). E.g.:

```starlark
files = {
    ":file": "destination/file.txt",        # file -> to given path
    ":file": "destination/",                # file -> into given folder
    ":folder": "destination/",              # folder -> into given folder (yields gen/<folder name>)
    ":folder": "destination",               # folder -> to given path
}
```

- A destination ending with `/` denotes a folder to copy into, otherwise the path of the file/folder to create (requires the label to provide a single file/folder).
- Relative destinations are resolved relative to the workspace root.
- Existing destination files are overwritten, existing destination folders are merged.""", allow_files = True, allow_empty = False, mandatory = True),
        "env": attr.string_dict(doc = "Optional environment variables.")
    },
    implementation = _copy_files_script_impl
)

def _copy_files_impl(name, from_to, env, **kwargs):
    script_name = name + "_script"
    copy_files_script(
        name = script_name,
        from_to = from_to,
        env = env
    )
    sh_binary(
        name = name,
        srcs = [script_name],
        use_bash_launcher = True,
        **kwargs
    )

copy_files = macro(
    doc = "Copy files/folders (e.g. build results) to the workspace or any other location.",
    inherit_attrs = copy_files_script,
    implementation = _copy_files_impl
)

def _open_impl(evo1, **kwargs):
    run_command(command = ("'" + evo1 + "'" if evo1 else "{dvcfg} project start") + " {-b} {-p}\necho 'Project has been opened in DaVinci Configurator Classic Version 6.'\nread -n 1 -s -r -p 'Press any key to continue...'\necho", **kwargs)

open = macro(
    doc = "Open a project in DaVinci Configurator Classic Version 6.",
    attrs = {
        "project": attr.label(doc = "The project to open.", allow_single_file = True, mandatory = True),
        "evo1": attr.string(doc = "Optional absolute path to a DaVinci Configurator Classic Version 6 Evo1 GUI launcher.", configurable = False)
    },
    implementation = _open_impl
)

def _diff_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "/" + ctx.label.name + ".jsonl")
    dict = _apply_dict(ctx, out, ctx.attr.ours) | {
        "_theirs_": ctx.attr.theirs,
        "theirs_dir": out.dirname + "/__",
        "-t": "-t '" + out.dirname + "/__/" + ctx.attr.theirs[DvProjectProvider].dvjson + "'",
    }
    script = _script(ctx, ctx.label.name + "/script.sh", _PREPARE_FOLDER + _UNTAR + "mkdir -p '{theirs_dir}'\n" + _UNTAR.replace("_upstream_", "_theirs_").replace("project_dir", "theirs_dir") + "{dvcfg} compare report {-b} {-p} {-t} -f JSONL" + _STOP + "\ncp '{project_dir}/Output/Log/DiffReport.jsonl' '{_parent_dir_}/" + ctx.label.name + ".jsonl'\nrm -rf '{project_dir}'\nrm -rf '{theirs_dir}'", True, dict)
    ctx.actions.run_shell(outputs = [out], inputs = _input_files(dict), tools = _files(ctx.toolchains[":toolchain_type"].cfg6.cli) + [script], command = "./" + script.path, use_default_shell_env = True)
    return [DefaultInfo(files = depset([out])), ctx.attr.ours[DvProjectProvider]]

diff = rule(
    doc = "Compare two projects.",
    attrs = {
        "ours": attr.label(doc = "Our project.", mandatory = True, providers = [DvProjectProvider]),
        "theirs": attr.label(doc = "Their project.", mandatory = True, providers = [DvProjectProvider]),
    },
    implementation = _diff_impl,
    toolchains = [":toolchain_type"]
)

def _eac_dev_impl(jar, arg, tags, **kwargs):
    run_command(
        command = '''export DVCFG_JVM_ARGS='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n -Djdk.attach.allowAttachSelf=true'
export DVCFG_TIMEOUT=300
export DVCFG_BUILD_SYSTEM_PATH="$BUILD_WORKSPACE_DIRECTORY/''' + native.package_name() + '''"
REST=''
if [[ "${{EAC_SPAWN-}}" != 'true' ]]; then
    REST+=" {-c}"''' + arg + '''
fi
REST+=" --ide-integration-port ${{EAC_IDE_PORT--2 --no-undo}}"
if [[ "${{EAC_DEBUG-}}" == 'true' ]]; then
    REST+=' --debug'
fi
{dvcfg} eac {-b} {-p}$REST
''' + _COPY + '''
if [[ "${{EAC_SPAWN-}}" != 'true' ]]; then
    _copy "{project_dir}/Output/Log/EaC" "$BUILD_WORKSPACE_DIRECTORY/.eac-run-artifacts/$(date '+%Y-%m-%d_%H-%M-%S')"
fi''',
        inputs = { "-c": jar },
        tags = tags + ["EAC_SPAWN"],
        **kwargs
    )

eac_dev = macro(
    doc = "Run/Debug EaC in an IDE.",
    inherit_attrs = run_command,
    attrs = {
        "jar": attr.label(doc = "EaC .jar file to run/debug.", mandatory = True, configurable = False),
        "arg": attr.string(doc = "Optional command line argument to call the code with (use [encode_eac_arg](#encode_eac_arg)).", configurable = False),
        "tags": attr.string_list(configurable = False),
        "command": None,
        "inputs": None
    },
    implementation = _eac_dev_impl
)
