"""Repository rules for fetching dvcfg6 toolchain from remote package"""

AUTH_PATTERN_ATTRS = {
    "auth_patterns": attr.string_dict(doc = "Authorization patterns (see [http_archive](https://bazel.build/rules/lib/repo/http#http_archive-auth_patterns))."),
}

def _extra_deb_package(repository_ctx, extracted_deb_path):
    # find the data archive, it could have various extensions depending on the chosen compression
    data_archive_types = ["tar", "tar.gz", "tar.xz", "tar.bz2", "tar.zst"]
    data_archive_path = None
    for data_archive_type in data_archive_types:
        data_archive_path_candidate = repository_ctx.path(extracted_deb_path + "/data." + data_archive_type)
        if data_archive_path_candidate.exists:
            data_archive_path = data_archive_path_candidate
            break
    if not data_archive_path:
        fail(".deb package is missing data.tar.*")

    extracted_data_path = repository_ctx.path("_extracted_data")
    repository_ctx.extract(data_archive_path, output = extracted_data_path)
    repository_ctx.delete(extracted_deb_path)

    # find the root of cfg6 inside the package via BFS
    data_cfg6_root_path = None
    paths_to_search = [extracted_data_path]
    MAX_PATH_TO_SEARCH = 40
    for i in range(MAX_PATH_TO_SEARCH):
        if i >= len(paths_to_search):
            break
        path_to_search = paths_to_search[i]
        for dir_entry in path_to_search.readdir():
            # we detect if we reached the app root, when we found the main executable
            if dir_entry.basename == "dvcfgcore":
                data_cfg6_root_path = path_to_search
                break
            elif dir_entry.is_dir:
                paths_to_search.append(dir_entry)
    if not data_cfg6_root_path:
        fail("Root path not found")

    # move root of cfg6 to root of repository
    for dir_entry in data_cfg6_root_path.readdir():
        repository_ctx.rename(dir_entry, dir_entry.basename)
    repository_ctx.delete(extracted_data_path)

# todo: replace macro construct with own rule driving single jar / manifest generation binding to toolchain
def _add_pai_macro_def(repository_ctx, base_path = None):
    libs_dir = "dvcfgpai/libs"
    if base_path:
        libs_dir = "{}/{}".format(base_path, libs_dir)
    version = None
    for path in repository_ctx.path(libs_dir).readdir():
        basename = path.basename
        version = basename.removeprefix("automation-interface-").removesuffix(".jar")
        if version != basename:
            break
    if not version:
        fail("Failed to read PAI version from jars in {}.".format(libs_dir))
    repository_ctx.file("defs.bzl", '''
def _call_with_pai_version(function, **kwargs):
    function(
        pai_version = "{version}",
        **kwargs
    )

script_jar = macro(
    doc = "Rule for setting up a PAI project.",
    inherit_attrs = _script_jar,
    attrs = dict(pai_version = None),
    implementation = lambda **kwargs: _call_with_pai_version(_script_jar, **kwargs),
)

sac = macro(
    doc = """Macro for setting up SaC. The following targets are provided:

- `<name>_dbg`: executable bazel target for running/debugging the SaC code in the IDE.
- `<name>`: The resulting `.arxml` file produced by the code.
""",
    inherit_attrs = _sac,
    attrs = dict(pai_version = None),
    implementation = lambda **kwargs: _call_with_pai_version(_sac, **kwargs),
)
'''.format(version = version))

def _toolchain_rule_attrs_str(repository_ctx, os, base_path = None):
    def exe_path(path, required = True):
        if base_path:
            path = "{}/{}".format(base_path, path)
        if os == "linux":
            pass
        elif os == "windows":
            path = path + ".exe"
        else:
            fail("Unsupported platform")
        if not repository_ctx.path(path).exists:
            if required:
                fail("{} not found".format(path))
            return None
        return path

    toolchain_attrs = {
        "core_exe": exe_path("dvcfgcore/dvcfgcore"),
        "cli_exe": exe_path("dvcfg", required = False) or exe_path("dvcfg-b"),
        "gui_exe": exe_path("dvcfgui-b/dvcfgui-b", required = False),
        "xpro_exe": exe_path("ecuxpro/ecuxpro"),
    }

    return "".join(["\n    {} = {},".format(key, json.encode(value)) for key, value in toolchain_attrs.items() if value])

def _cfg6_package_impl(repository_ctx):
    extracted_pkg = "_extracted_pkg"
    repository_ctx.download_and_extract(
        url = repository_ctx.attr.url,
        sha256 = repository_ctx.attr.sha256,
        auth = {repository_ctx.attr.url: repository_ctx.attr.auth_patterns} if repository_ctx.attr.auth_patterns else {},
        output = extracted_pkg,
    )

    if repository_ctx.attr.os == "linux":
        _extra_deb_package(repository_ctx, extracted_pkg)
    else:
        repository_ctx.extract(extracted_pkg + "/tools/archive.zip")

    toolchain_attrs_str = _toolchain_rule_attrs_str(repository_ctx, repository_ctx.attr.os)

    _add_pai_macro_def(repository_ctx)

    repository_ctx.file("BUILD.bazel", """
load("@rules_cfg6//toolchain:defs.bzl", "cfg6_hermetic_toolchain")
load("@rules_java//java:defs.bzl", "java_import")

package(default_visibility = ["//visibility:public"])

cfg6_hermetic_toolchain(
    name = "cfg6_toolchain_config",
    files = glob(["**"]),{}
)

java_import(
    name = "eac_annotation_processor_deps",
    jars = ["lib/com.vector.cfg.cac.processing.impl.jar"] + glob(
        include = ["dvcfgpai/libs/automation-interface-*.jar"],
        exclude = ["dvcfgpai/libs/automation-interface-*-stable.jar", "dvcfgpai/libs/automation-interface-*-sources.jar"],
    ),
)

java_import(
    name = "pai",
    jars = glob(
        include = ["dvcfgpai/libs/*.jar"],
        exclude = ["dvcfgpai/libs/*-sources.jar"],
    ),
    neverlink = True,
)
    """.format(toolchain_attrs_str))

cfg6_package = repository_rule(
    doc = "Repository Rule for loading a DaVinci Configurator Classic Version 6 package",
    attrs = dict(
        AUTH_PATTERN_ATTRS,
        url = attr.string(doc = "URL of the DaVinci Configurator .deb package.", mandatory = True),
        sha256 = attr.string(doc = "SHA256 checksum of the package.", mandatory = True),
        os = attr.string(mandatory = True, values = ["linux", "windows"]),
    ),
    implementation = _cfg6_package_impl,
)

def _cfg6_remote_toolchain_hub_impl(repository_ctx):
    linux_package_repo = repository_ctx.attr.linux_package_repo
    windows_package_repo = repository_ctx.attr.windows_package_repo
    if not (linux_package_repo or windows_package_repo):
        fail("No package repo specified")

    repos = []
    if linux_package_repo:
        repos.append((linux_package_repo, "linux"))
    if windows_package_repo:
        repos.append((windows_package_repo, "windows"))

    build_file_contents = """load("@rules_java//java:defs.bzl", "java_plugin")"""
    eac_annotation_proc_select = {}

    for package_repo, os in repos:
        build_file_contents += """
toolchain(
    name = "dvcfg6_toolchain_{os}",
    exec_compatible_with = [
        "@platforms//os:{os}",
        "@platforms//cpu:x86_64",
    ],
    toolchain = "@{package_repo}//:cfg6_toolchain_config",
    toolchain_type = "@rules_cfg6//toolchain:toolchain_type",
)
""".format(package_repo = package_repo, os = os)
        eac_annotation_proc_select["@platforms//os:{}".format(os)] = ["@{}//:eac_annotation_processor_deps".format(package_repo)]

    build_file_contents += """
java_plugin(
    name = "eac_annotation_processor",
    deps = select({}),
    processor_class = "com.vector.cfg.cac.processing.impl.CaCEntryPointProcessor",
)
""".format(json.encode(eac_annotation_proc_select))

    repository_ctx.file("BUILD.bazel", build_file_contents)

cfg6_remote_toolchain_hub = repository_rule(
    doc = "Repository Rule for creating a toolchain definition for a given DaVinci Configurator Classic Version pointing to the respective execution specific platform repos",
    attrs = {
        "windows_package_repo": attr.string(),
        "linux_package_repo": attr.string(),
    },
    implementation = _cfg6_remote_toolchain_hub_impl,
)

def _absolute_path(repository_ctx, path):
    is_absolute_or_label = path[0] in ("/", "\\", ":", "@") or (len(path) > 2 and path[1] == ":" and path[2] in ("/", "\\"))
    if not is_absolute_or_label:
        path = str(repository_ctx.workspace_root) + "/" + path

    return repository_ctx.path(path)

def _cfg6_local_toolchain_impl(repository_ctx):
    path = _absolute_path(repository_ctx, repository_ctx.attr.path)
    os = "windows" if repository_ctx.os.name.startswith("windows") else "linux"
    toolchain_attrs_str = _toolchain_rule_attrs_str(repository_ctx, os, path)

    repository_ctx.file("BUILD.bazel", """
load("@rules_java//java:defs.bzl", "java_import", "java_plugin")
load("@rules_cfg6//toolchain:defs.bzl", "cfg6_toolchain")

cfg6_toolchain(
    name = "dvcfg6_toolchain_{os}_config",{toolchain_attrs}
)

toolchain(
    name = "dvcfg6_toolchain_{os}",
    exec_compatible_with = [
        "@platforms//os:{os}",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":dvcfg6_toolchain_{os}_config",
    toolchain_type = "@rules_cfg6//toolchain:toolchain_type",
)

java_import(
    name = "eac_annotation_processor_deps",
    jars = ["lib/com.vector.cfg.cac.processing.impl.jar"] + glob(
        include = ["dvcfgpai/libs/automation-interface-*.jar"],
        exclude = ["dvcfgpai/libs/automation-interface-*-stable.jar", "dvcfgpai/libs/automation-interface-*-sources.jar"],
    ),
)

java_plugin(
    name = "[":eac_annotation_processor"]",
    deps = ["eac_annotation_processor_deps"],
    processor_class = "com.vector.cfg.cac.processing.impl.CaCEntryPointProcessor",
)

java_import(
    name = "pai",
    jars = glob(
        include = ["dvcfgpai/libs/*.jar"],
        exclude = ["dvcfgpai/libs/*-sources.jar"],
    ),
    neverlink = True,
)
""".format(toolchain_attrs = toolchain_attrs_str, os = os))
    _add_pai_macro_def(repository_ctx)

cfg6_local_toolchain = repository_rule(
    doc = "Repository Rule for creating a toolchain definition for a given DaVinci Configurator Classic Version pointing to a locally installed version.",
    attrs = {
        "path": attr.string(mandatory = True),
        "os": attr.string(),
    },
    implementation = _cfg6_local_toolchain_impl,
)
