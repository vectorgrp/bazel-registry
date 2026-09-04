load("@rules_java//java:defs.bzl", "java_import", "java_plugin", "java_library")
load("@rules_cfg6//:defs.bzl", "cfg6_toolchain")

package(default_visibility = ["//visibility:public"])

exports_files(["defs.bzl", "rules.bzl"])

cfg6_toolchain(
    name = "cfg6",
    cli = "CLI",
    core = "CORE",
    xpro = "XPRO",
    gui = "GUI",
    gui_template = 'TEMPLATE',
    result_file_cmd = "RESULT_FILE_CMD",
    pack = 'COMPRESS',
    unpack = 'UNPACK'
)

toolchain(
    name ="toolchain",
    toolchain = ":cfg6",
    toolchain_type = "@rules_cfg6//:toolchain_type"
)

java_import(
    name = "eac_annotation_processor_deps",
    jars = ["_/lib/com.vector.cfg.cac.processing.impl.jar"] + glob(
        include = ["_/dvcfgpai/libs/automation-interface-*.jar"],
        exclude = ["_/dvcfgpai/libs/automation-interface-*-stable.jar", "_/dvcfgpai/libs/automation-interface-*-sources.jar"]
    ),
    visibility = ["//visibility:private"]
)

java_plugin(
    name = "eac_annotation_processor",
    deps = [":eac_annotation_processor_deps"],
    processor_class = "com.vector.cfg.cac.processing.impl.CaCEntryPointProcessor"
)

_lib_folder = "_/dvcfgpai/libs/"
_pai_jars = glob(include = [_lib_folder + "*.jar"], exclude = [_lib_folder + "*-sources.jar"])
_pai_common_lib_names = [jar[len(_lib_folder):-4] for jar in _pai_jars if not (jar.endswith("-sources.jar") or jar.endswith("-stable.jar") or jar.endswith("-beta.jar"))]
_pai_stable_lib_names = [jar[len(_lib_folder):-4] for jar in _pai_jars if jar.endswith("-stable.jar")]
_pai_beta_lib_names = [jar[len(_lib_folder):-4] for jar in _pai_jars if jar.endswith("-beta.jar")]
[
    java_import(
        name = name,
        jars = [_lib_folder + name + ".jar"],
        srcjar = _lib_folder + name + "-sources.jar",
        visibility = ["//visibility:private"]
    )
    for name in _pai_common_lib_names
]
[
    java_import(
        name = name,
        jars = [_lib_folder + name + ".jar"],
        visibility = ["//visibility:private"]
    )
    for name in _pai_stable_lib_names
]
[
    java_import(
        name = name,
        jars = [_lib_folder + name + ".jar"],
        visibility = ["//visibility:private"]
    )
    for name in _pai_beta_lib_names
]

java_library(
    name = "pai",
    exports = _pai_common_lib_names + _pai_stable_lib_names
)

java_library(
    name = "pai_beta",
    exports = _pai_common_lib_names + _pai_beta_lib_names
)

java_library(
    name = "pai_neverlink",
    exports = [":pai"],
    neverlink = True,
    visibility = ["//visibility:private"]
)
