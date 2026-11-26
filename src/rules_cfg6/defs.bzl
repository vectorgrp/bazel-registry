"""
Bazel ruleset for working with [DaVinci Configurator Classic Version 6](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/index.html).
"""

load(":kt_jar_library.bzl", _kt_jar_library = "kt_jar_library")
load(":rules.bzl",
    _generate_foundation_layer = "generate_foundation_layer",
    _system_extract = "system_extract",
    _merged_extract = "merged_extract",
    _variant_extract = "variant_extract",
    _dvjson = "dvjson",
    _open = "open",
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
    _derive_ecuc = "derive_ecuc"
)

generate_foundation_layer = _generate_foundation_layer
system_extract = _system_extract
merged_extract = _merged_extract
variant_extract = _variant_extract
dvjson = _dvjson
open = _open
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
derive_ecuc = _derive_ecuc
kt_jar_library = _kt_jar_library

