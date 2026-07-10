"""
Bazel ruleset for working with [DaVinci Configurator Classic Version 6](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/index.html).
"""

load(":rules.bzl",
    _cfg6_archive = "cfg6_archive",
    _local_cfg6 = "local_cfg6",
    _cfg6_toolchain = "cfg6_toolchain",
    _generate_foundation_layer = "generate_foundation_layer",
    _script_jar = "script_jar",
    _select_evs = "select_evs",
    _import_evs = "import_evs",
    _derive_ecuc = "derive_ecuc",
    _replace_modules = "replace_modules",
    _import_modules = "import_modules",
    _variant_arxmls = "variant_arxmls",
    _import_diag_modules = "import_diag_modules",
    _update_project = "update_project",
    _as_code = "as_code",
    _as_code_arg = "as_code_arg",
    _as_code_eac = "as_code_eac",
    _system_extract = "system_extract",
    _merged_extract = "merged_extract",
    _variant_extract = "variant_extract",
    _script_patched_arxml = "script_patched_arxml",
    _script_task = "script_task",
    _edit_project = "edit_project",
    _run_export = "run_export",
    _export_flat_extract = "export_flat_extract",
    _generate = "generate",
    _generate_swct = "generate_swct",
    _validation_report = "validation_report",
    _downstream_project = "downstream_project",
    _pipeline_step = "pipeline_step",
    _archived_project = "archived_project",
    _pipeline_executable = "pipeline_executable",
    _run_on_project = "run_on_project",
    _apply_bswmd = "apply_bswmd"
)

cfg6_archive = _cfg6_archive
local_cfg6 = _local_cfg6
cfg6_toolchain = _cfg6_toolchain
generate_foundation_layer = _generate_foundation_layer
script_jar = _script_jar
select_evs = _select_evs
import_evs = _import_evs
derive_ecuc = _derive_ecuc
replace_modules = _replace_modules
import_modules = _import_modules
variant_arxmls = _variant_arxmls
import_diag_modules = _import_diag_modules
update_project = _update_project
as_code = _as_code
as_code_arg = _as_code_arg
as_code_eac = _as_code_eac
system_extract = _system_extract
merged_extract = _merged_extract
variant_extract = _variant_extract
script_patched_arxml = _script_patched_arxml
script_task = _script_task
edit_project = _edit_project
run_export = _run_export
export_flat_extract = _export_flat_extract
generate = _generate
generate_swct = _generate_swct
validation_report = _validation_report
downstream_project = _downstream_project
pipeline_step = _pipeline_step
archived_project = _archived_project
pipeline_executable = _pipeline_executable
run_on_project = _run_on_project
apply_bswmd = _apply_bswmd
