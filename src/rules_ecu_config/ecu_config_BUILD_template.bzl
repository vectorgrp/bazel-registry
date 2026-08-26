load("@rules_cfg6//:defs.bzl", "apply_bswmd", "as_code", "derive_ecuc", "downstream_project", "import_diag_modules", "import_evs", "import_modules", "update_project")
load("@rules_dvarjson//:defs.bzl", "ddm", "ddm_json", "evs")
load("@rules_ecu_config//:defs.bzl", "dbg_as_code_script")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load(":defs.bzl", "as_code_jars", "edit_project")

package(default_visibility = ["//visibility:public"])

exports_files(["defs.bzl", "rules.bzl"])

dbg_as_code_script(
    name = "spawn_dev_cfg6_script",
    bsw_pkg = "BSW",
    dvjson = "DVJSON",
    visibility = ["//visibility:private"],
)

sh_binary(
    name = "spawn_dev_cfg6",
    srcs = [":spawn_dev_cfg6_script"],
)

IMPORT_EVS
DERIVE_ECUC
IMPORT_DIAG_MODULES
APPLY_BSWMD
IMPORT_MODULES
AS_CODE
UPDATE_PROJECT

downstream_project(
    name = "project",
    bsw_pkg = "BSW",
    dvjson = "DVJSON",
    upstream = "GUI_PROJECT",
)

edit_project(
    name = "edit_project",
)
