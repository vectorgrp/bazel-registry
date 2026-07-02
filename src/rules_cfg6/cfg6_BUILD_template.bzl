load("@rules_java//java:defs.bzl", "java_import", "java_plugin")
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
    unpack = 'UNPACK',
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

java_import(
    name = "pai",
    jars = glob(
        include = ["_/dvcfgpai/libs/*.jar"],
        exclude = ["_/dvcfgpai/libs/*-sources.jar"]
    )
)
