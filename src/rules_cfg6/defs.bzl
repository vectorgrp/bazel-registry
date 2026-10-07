"""
Bazel ruleset for working with [DaVinci Configurator Classic Version 6](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/index.html).
"""

load(":rules.bzl",
    _cfg6_archive = "cfg6_archive",
    _local_cfg6 = "local_cfg6",
    _cfg6_toolchain = "cfg6_toolchain",
    _generate_foundation_layer = "generate_foundation_layer",
    _script_jar = "script_jar",
    _system_extract = "system_extract",
    _merged_extract = "merged_extract",
    _variant_extract = "variant_extract",
    _script_patched_arxml = "script_patched_arxml",
    _script_task = "script_task",
    _dvjson = "dvjson",
    _app_design = "app_design",
    _arxml_patch = "arxml_patch",
    _extract_evs = "extract_evs",
    _merged_arxml = "merged_arxml",
    _open = "open",
    _eac_dev = "eac_dev",
    _project_folder = "project_folder",
    _project_file = "project_file",
    _apply_command = "apply_command",
    _hybrid = "hybrid",
    _from_scratch = "from_scratch",
    _expand_file_paths = "expand_file_paths",
    _run_command = "run_command",
    _copy_files = "copy_files",
    _list_project_files = "list_project_files",
    _encode_eac_arg = "encode_eac_arg",
    _diff = "diff"
)

cfg6_archive = _cfg6_archive
local_cfg6 = _local_cfg6
cfg6_toolchain = _cfg6_toolchain
generate_foundation_layer = _generate_foundation_layer
script_jar = _script_jar
system_extract = _system_extract
merged_extract = _merged_extract
variant_extract = _variant_extract
script_patched_arxml = _script_patched_arxml
script_task = _script_task
dvjson = _dvjson
app_design = _app_design
arxml_patch = _arxml_patch
extract_evs = _extract_evs
merged_arxml = _merged_arxml
open = _open
eac_dev = _eac_dev
project_folder = _project_folder
project_file = _project_file
apply_command = _apply_command
hybrid = _hybrid
from_scratch = _from_scratch
expand_file_paths = _expand_file_paths
run_command = _run_command
copy_files = _copy_files
list_project_files = _list_project_files
encode_eac_arg = _encode_eac_arg
diff = _diff
