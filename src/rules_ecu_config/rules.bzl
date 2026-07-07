load("@rules_cfg6//:rules.bzl", "AsCodeTypeProvider", "AsCodeArgProvider", "single_file_from_target")

def _get_normalized_path(repository_ctx, json_label, path_in_json):
    path_in_json = path_in_json.replace("\\", "/")
    if _is_windows(repository_ctx):
        if len(path_in_json) > 1 and path_in_json[1] == ":":
            return repository_ctx.path(path_in_json)
    elif path_in_json.startswith("/"):
        return repository_ctx.path(path_in_json)
    result = repository_ctx.path(json_label).realpath.dirname
    for part in path_in_json.split("/"):
        if part == "..":
            result = result.dirname
        elif part != ".":
            result = result.get_child(part)
    return result

def _is_windows(repository_ctx):
    return repository_ctx.os.name.startswith("windows")

def _ext(repository_ctx):
    return ".exe" if _is_windows(repository_ctx) else ""

def _cli(repository_ctx):
    folder = repository_ctx.path(repository_ctx.attr.cfg6_defs).dirname.get_child("_")
    ext = _ext(repository_ctx)
    result = folder.get_child("dvcfg" + ext)
    return result if result.exists else folder.get_child("dvcfg-b" + ext)

def _java(repository_ctx):
    ext = _ext(repository_ctx)
    return repository_ctx.path(repository_ctx.attr.cfg6_defs).dirname.get_child("_", "java-win" if ext else "java-linux", "bin", "java" + ext)

def _gson_jar(repository_ctx):
    plugins_dir = repository_ctx.path(repository_ctx.attr.cfg6_defs).dirname.get_child("_", "dvcfgcore", "plugins")
    return [f for f in plugins_dir.readdir(watch = "no") if "com.google.gson" in f.basename][0]

def _execute(repository_ctx, *cmd_and_args):
    ret = repository_ctx.execute(
        cmd_and_args,
        quiet = False
    )
    if ret.return_code != 0:
        fail(ret.stderr)

def _dvjson_substitution(repository_ctx):
    bsw_pkg = str(repository_ctx.path(repository_ctx.attr.bsw_pkg))
    upstream_cmd = ["powershell", "-NoP", "-NonI", "-c", "[guid]::NewGuid().ToString() > upstream"] if _is_windows(repository_ctx) else ["bash", "-c", "cat /proc/sys/kernel/random/uuid > upstream"]
    _execute(repository_ctx, *upstream_cmd)
    upstream_label = "@@{}//:upstream".format(repository_ctx.name)
    if repository_ctx.attr.dvjson:
        dvjson_path = repository_ctx.path(repository_ctx.attr.dvjson)
        lock_file_name = dvjson_path.basename[:-6] + "~lock"
        for entry in dvjson_path.dirname.readdir(watch = "no"):
            if entry.is_dir:
                folder_name = entry.basename.lower()
                if folder_name == "output":
                    repository_ctx.watch_tree(entry.get_child("Config"))
                elif folder_name != "config":
                    repository_ctx.watch_tree(entry)
            elif entry.basename != lock_file_name:
                repository_ctx.watch(entry)
        return (bsw_pkg, str(dvjson_path), upstream_label)
    cli = _cli(repository_ctx)
    repository_ctx.watch(cli)
    _execute(repository_ctx, cli, "project", "create", "-b", bsw_pkg, "-f", repository_ctx.attr.creation_file, "--project-name", repository_ctx.original_name, "-o", "_")
    dvjson = "_/{}.dvjson".format(repository_ctx.original_name)
    repository_ctx.watch(repository_ctx.attr.creation_file)
    return (bsw_pkg, str(repository_ctx.path(dvjson)), upstream_label)

def _patch_settings(repository_ctx, dvjson):
    if repository_ctx.attr.settings_patch_template:
        expanded_patch = "_settings_patch_expanded.json"
        repository_ctx.template(
            expanded_patch,
            repository_ctx.attr.settings_patch_template,
            substitutions = {
                placeholder: str(repository_ctx.path(label))
                for placeholder, label in repository_ctx.attr.settings_patch_substitutions.items()
            }
        )
        _execute(
            repository_ctx,
            _java(repository_ctx), "-cp", _gson_jar(repository_ctx), Label("SettingsPatcher.java"),
            dvjson,
            expanded_patch,
        )
        repository_ctx.watch(repository_ctx.attr.settings_patch_template)
        for label in repository_ctx.attr.settings_patch_substitutions.values():
            repository_ctx.watch(label)

def _import_evs_substitution(repository_ctx, bsw_pkg, dvjson, upstream):
    arxml_labels = repository_ctx.attr.evs
    if not arxml_labels:
        return (upstream, "")
    substitution = ""
    if len(arxml_labels) == 1 and arxml_labels[0].name.endswith(".json"):
        substitution = """evs(
    name = "evs",
    json = "{}"
)
""".format(arxml_labels[0])
        arxml_labels = ["evs"]
    substitution += """import_evs(
    name = "import_evs",
    evs = ["{evs}"],
    bsw_pkg = "{bsw_pkg}",
    dvjson = "{dvjson}",
    upstream = "{upstream}"
)
""".format(
    evs = '", "'.join([str(label) for label in arxml_labels]),
    bsw_pkg = bsw_pkg,
    dvjson = dvjson,
    upstream = upstream
)
    return ("import_evs", substitution)

def _apply_bswmd_substitution(repository_ctx, bsw_pkg, dvjson, upstream):
    return ("apply_bswmd", """apply_bswmd(
    name = "apply_bswmd",
    bsw_pkg = "{bsw_pkg}",
    dvjson = "{dvjson}",
    upstream = "{upstream}"
)
""".format(
        bsw_pkg = bsw_pkg,
        dvjson = dvjson,
        upstream = upstream,
    )) if repository_ctx.attr.extract or repository_ctx.attr.diag_modules else (upstream, "")

def _derive_ecuc_substitution(repository_ctx, bsw_pkg, dvjson, upstream):
    return ("derive_ecuc", """derive_ecuc(
    name = "derive_ecuc",
    extract = ["{extract}"],
    bsw_pkg = "{bsw_pkg}",
    dvjson = "{dvjson}",
    upstream = "{upstream}"
)
""".format(
    extract = '", "'.join([str(label) for label in repository_ctx.attr.extract]),
    bsw_pkg = bsw_pkg,
    dvjson = dvjson,
    upstream = upstream
)) if repository_ctx.attr.extract else (upstream, "")

def _import_modules_substitution(repository_ctx, bsw_pkg, dvjson, upstream):
    return ("import_modules", """import_modules(
    name = "import_modules",
    modules = ["{modules}"],
    bsw_pkg = "{bsw_pkg}",
    dvjson = "{dvjson}",
    upstream = "{upstream}"
)
""".format(
    modules = '", "'.join([str(label) for label in repository_ctx.attr.modules]),
    bsw_pkg = bsw_pkg,
    dvjson = dvjson,
    upstream = upstream
)) if repository_ctx.attr.modules else (upstream, "")

def _get_file_extension(path):
    name = path.basename
    i = name.rfind(".")
    if i == -1:
        return ""
    return name[i:]

def _import_diag_modules_substitution(repository_ctx, bsw_pkg, dvjson, upstream):
    if not repository_ctx.attr.diag_modules:
        return (upstream, "")
    substitution = ""
    arxml_labels = []
    count = -1
    for label in repository_ctx.attr.diag_modules:
        if label.name.endswith(".json"):
            count += 1
            parsed = json.decode(repository_ctx.read(label))
            diagnosticData = parsed["diagnosticData"]
            cdd_path = _get_normalized_path(repository_ctx, label, diagnosticData["cdd"])
            repository_ctx.symlink(cdd_path, "linked_cdd_{}.cdd".format(count))
            patch_file = "None"
            if "diagnosticDescriptionPatchFile" in diagnosticData:
                patch_file_path = _get_normalized_path(repository_ctx, label, diagnosticData["diagnosticDescriptionPatchFile"])
                patch_file = "linked_patch_{}{}".format(count, _get_file_extension(patch_file_path))
                repository_ctx.symlink(patch_file_path, patch_file)
                patch_file = '"' + patch_file + '"'
            substitution += """ddm_json(
    name = "ddm_json_{index}",
    cdd = "linked_cdd_{index}.cdd",
    bsw_pkg = "{bsw}",
    ecu = "{ecu}",
    variant = "{variant}",
    did_and_rid_as_single_signal = {single_signal},
    generic_legacy_import = {generic_legacy_import},
    patch_file = {patch_file}
)
ddm(
    name = "diag_module_{index}",
    json = "ddm_json_{index}"
)
""".format(
    index = count,
    bsw = bsw_pkg,
    ecu = diagnosticData["ecu"],
    variant = diagnosticData["variant"],
    single_signal = "importDIDsAndRIDsAsSingleSignal" in diagnosticData and diagnosticData["importDIDsAndRIDsAsSingleSignal"],
    generic_legacy_import = "genericLegacyDiagnosticImport" in diagnosticData and diagnosticData["genericLegacyDiagnosticImport"],
    patch_file = patch_file
)
            arxml_labels.append("diag_module_{}".format(count))
        else:
            arxml_labels.append(str(label))
    return ("import_diag_modules", substitution + """import_diag_modules(
    name = "import_diag_modules",
    modules = ["{modules}"],
    bsw_pkg = "{bsw_pkg}",
    dvjson = "{dvjson}",
    upstream = "{upstream}"
)
""".format(
    modules = '", "'.join(arxml_labels),
    bsw_pkg = bsw_pkg,
    dvjson = dvjson,
    upstream = upstream
))

def _update_project_substitution(repository_ctx, bsw_pkg, dvjson, upstream):
    return ("update_project", """update_project(
    name = "update_project",
    switches = "{switches}",
    bsw_pkg = "{bsw_pkg}",
    dvjson = "{dvjson}",
    upstream = "{upstream}"
)
""".format(
    switches = repository_ctx.attr.update_switches,
    bsw_pkg = bsw_pkg,
    dvjson = dvjson,
    upstream = upstream
)) if dvjson != upstream else (upstream, "")

def _as_code_substitution(repository_ctx, bsw_pkg, dvjson, upstream):
    return ("as_code", """alias(
    name = "as_code_upstream",
    actual = "{upstream}"
)
as_code(
    name = "as_code",
    jars = as_code_jars,
    bsw_pkg = "{bsw_pkg}",
    dvjson = "{dvjson}",
    upstream = "{upstream}"
)
""".format(
    bsw_pkg = bsw_pkg,
    dvjson = dvjson,
    upstream = upstream
)) if repository_ctx.attr.as_code else (upstream, "")

def _ecu_config_repo_impl(repository_ctx):
    repository_ctx.template("defs.bzl", Label("ecu_config_defs_template.bzl"))
    bsw_pkg, dvjson, upstream = _dvjson_substitution(repository_ctx)
    _patch_settings(repository_ctx, dvjson)
    upstream, IMPORT_EVS = _import_evs_substitution(repository_ctx, bsw_pkg, dvjson, upstream)
    upstream, DERIVE_ECUC = _derive_ecuc_substitution(repository_ctx, bsw_pkg, dvjson, upstream)
    upstream, IMPORT_DIAG_MODULES = _import_diag_modules_substitution(repository_ctx, bsw_pkg, dvjson, upstream)
    upstream, APPLY_BSWMD = _apply_bswmd_substitution(repository_ctx, bsw_pkg, dvjson, upstream)
    upstream, IMPORT_MODULES = _import_modules_substitution(repository_ctx, bsw_pkg, dvjson, upstream)
    upstream, AS_CODE = _as_code_substitution(repository_ctx, bsw_pkg, dvjson, upstream)
    upstream, UPDATE_PROJECT = _update_project_substitution(repository_ctx, bsw_pkg, dvjson, upstream)
    repository_ctx.template(
        "BUILD.bazel",
        Label("ecu_config_BUILD_template.bzl"),
        substitutions = {
            "IMPORT_EVS": IMPORT_EVS,
            "DERIVE_ECUC": DERIVE_ECUC,
            "IMPORT_DIAG_MODULES": IMPORT_DIAG_MODULES,
            "APPLY_BSWMD": APPLY_BSWMD,
            "IMPORT_MODULES": IMPORT_MODULES,
            "UPDATE_PROJECT": UPDATE_PROJECT,
            "AS_CODE": AS_CODE,
            "BSW": bsw_pkg,
            "DVJSON": dvjson,
            "GUI_PROJECT": upstream
        }
    )
    repository_ctx.template(
        "rules.bzl",
        Label("ecu_config_rules_template.bzl"),
        substitutions = {
            "CFG6_DEFS": str(repository_ctx.attr.cfg6_defs),
            "CFG6_EAC_AP": str(repository_ctx.attr.cfg6_defs.same_package_label("eac_annotation_processor")),
            "AS_CODE_JARS": str([str(label) for label in repository_ctx.attr.as_code]),
            "FOUNDATION_LAYER_PKG": str(repository_ctx.attr.bsw_pkg),
            "BSW": bsw_pkg,
            "DVJSON": dvjson,
            "GUI_PROJECT": upstream
        }
    )

ECU_CONFIG_ATTRS = {
    "cfg6_defs": attr.label(doc = "The `defs.bzl` file of the DaVinci Configurator Classic Version 6 tool repo.", allow_single_file = ["defs.bzl"], mandatory = True),
    "bsw_pkg": attr.label(doc = "The BSW package folder.", allow_single_file = True, mandatory = True),
    "dvjson": attr.label(doc = "The existing .dvjson file. Mutually exclusive with `creation_file`.", allow_single_file = [".dvjson"]),
    "creation_file": attr.label(doc = "Project creation file containing general settings. Mutually exclusive with `dvjson`.", allow_single_file = [".json"]),
    "settings_patch_template": attr.label(doc = """Optional JSON file for patching project settings.

Here is an example for setting `allowMergeConflicts` in the `General.json` file to `true` and removing the mapping for the `Dcm` module from the `moduleDefinitionMappings` array in the `Ifp.json` file:

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
- Primitive-typed properties are overwritten with the patch value (use `null` to delete the property).
- Arrays with primitive-typed elements are merged as duplicate-free unions.
- Objects in arrays are identified by a key property:
  - In `General.json`, `useCases` are identified by their `vector` property.
  - In `Ifp.json`, `moduleDefinitionMappings` are identified by their `moduleConfigName` (see example) and `comControllerMappings` by their `clusterPath`.
  - Use the `__delete__` property (see example) to remove an object from the array.
 """, allow_single_file = [".json"]),
    "settings_patch_substitutions": attr.string_keyed_label_dict(doc = """Optional substitutions for replacing variables in the `settings_patch_template` with build target file paths. E.g.:
Use `{"{{OUTPUT_DIR}}": "//pkg:target"}` to replace the text `{{OUTPUT_DIR}}` in the provided `settings_patch_template` with the path to the file created by building `//pkg:target`.""", allow_files = True),
    "evs": attr.label_list(doc = "EvaluatedVariantSet (either one .json file or .arxml files).", allow_files = True, allow_empty = False),
    "extract": attr.label_list(doc = "ECU extract .arxml files.", allow_files = [".arxml"], allow_empty = False),
    "modules": attr.label_list(doc = "Module .arxml files to import.", allow_files = [".arxml"], allow_empty = False),
    "diag_modules": attr.label_list(doc = "Diagnostic module .arxml or .json files to import.", allow_files = [".arxml", ".json"], allow_empty = False),
    "update_switches": attr.string(doc = '''String consisting of all switches to apply when running the "project update" command (defaults to "" meaning perform all updates). E.g.: "asr" will only run "automatic reference correction", "solve all" and "RTE config update". The following switches are available:<br/>
`a`: Perform automatic correction of unresolved or inconsistent references.<br/>
`s`: Perform 'solve all' by executing all recommended solving actions of the project.<br/>
`c`: Apply changes from project input files.<br/>
`r`: Apply changes to the RTE configuration.<br/>
`e`: Apply changes from evaluated variant set.
'''),
    "as_code": attr.label_list(doc = "List of as-code .jar files. Each .jar must be tagged with `as_code_eac`. The .jar files are applied in the order given here.", allow_empty = False)
}

ecu_config_repo = repository_rule(
    attrs = ECU_CONFIG_ATTRS,
    implementation = _ecu_config_repo_impl
)

_PRIMITIVE_TYPE = type("")
_LIST_TYPE = type([])
_OBJECT_TYPE = type({})

def _arg_file_string(target, file_targets):
    arg_string = '"${{FILE_ARG_{}//\\\\//}}"'.format(len(file_targets))
    file_targets.append(target)
    return arg_string

def _arg_string_and_runfiles(arg, file_targets):
    t = type(arg)
    if t == _PRIMITIVE_TYPE:
        return arg
    separator = ""
    if t == _LIST_TYPE:
        arg_string = "["
        for e in arg:
            e_string = _arg_string_and_runfiles_1(e, file_targets)
            arg_string = arg_string + separator + e_string
            separator = ","
        return arg_string + "]"
    if t == _OBJECT_TYPE:
        arg_string = "{"
        for k, v in arg.items():
            e_string = _arg_string_and_runfiles_1(v, file_targets)
            arg_string = arg_string + separator + '"{}":'.format(k) + e_string
            separator = ","
        return arg_string + "}"
    return _arg_file_string(arg, file_targets)

def _arg_string_and_runfiles_1(arg, file_targets):
    t = type(arg)
    if t == _PRIMITIVE_TYPE:
        return arg
    separator = ""
    if t == _LIST_TYPE:
        arg_string = "["
        for e in arg:
            e_string = _arg_string_and_runfiles_2(e, file_targets)
            arg_string = arg_string + separator + e_string
            separator = ","
        return arg_string + "]"
    if t == _OBJECT_TYPE:
        arg_string = "{"
        for k, v in arg.items():
            e_string = _arg_string_and_runfiles_2(v, file_targets)
            arg_string = arg_string + separator + '"{}":'.format(k) + e_string
            separator = ","
        return arg_string + "}"
    return _arg_file_string(arg, file_targets)

def _arg_string_and_runfiles_2(arg, file_targets):
    t = type(arg)
    if t == _PRIMITIVE_TYPE:
        return arg
    separator = ""
    if t == _LIST_TYPE:
        arg_string = "["
        for e in arg:
            e_string = _arg_string_and_runfiles_3(e, file_targets)
            arg_string = arg_string + separator + e_string
            separator = ","
        return arg_string + "]"
    if t == _OBJECT_TYPE:
        arg_string = "{"
        for k, v in arg.items():
            e_string = _arg_string_and_runfiles_3(v, file_targets)
            arg_string = arg_string + separator + '"{}":'.format(k) + e_string
            separator = ","
        return arg_string + "}"
    return _arg_file_string(arg, file_targets)

def _arg_string_and_runfiles_3(arg, file_targets):
    t = type(arg)
    if t == _PRIMITIVE_TYPE:
        return arg
    separator = ""
    if t == _LIST_TYPE:
        arg_string = "["
        for e in arg:
            e_string = _arg_string_and_runfiles_4(e, file_targets)
            arg_string = arg_string + separator + e_string
            separator = ","
        return arg_string + "]"
    if t == _OBJECT_TYPE:
        arg_string = "{"
        for k, v in arg.items():
            e_string = _arg_string_and_runfiles_4(v, file_targets)
            arg_string = arg_string + separator + '"{}":'.format(k) + e_string
            separator = ","
        return arg_string + "}"
    return _arg_file_string(arg, file_targets)

def _arg_string_and_runfiles_4(arg, file_targets):
    t = type(arg)
    if t == _PRIMITIVE_TYPE:
        return arg
    separator = ""
    if t == _LIST_TYPE:
        arg_string = "["
        for e in arg:
            e_string = _arg_string_and_runfiles_5(e, file_targets)
            arg_string = arg_string + separator + e_string
            separator = ","
        return arg_string + "]"
    if t == _OBJECT_TYPE:
        arg_string = "{"
        for k, v in arg.items():
            e_string = _arg_string_and_runfiles_5(v, file_targets)
            arg_string = arg_string + separator + '"{}":'.format(k) + e_string
            separator = ","
        return arg_string + "}"
    return _arg_file_string(arg, file_targets)

def _arg_string_and_runfiles_5(arg, file_targets):
    t = type(arg)
    if t == _LIST_TYPE or t == _OBJECT_TYPE:
        fail("Maximum nesting level for JSON arguments is 5.")
    if t == _PRIMITIVE_TYPE:
        return arg
    return _arg_file_string(arg, file_targets)

def _dbg_as_code_script_impl(ctx):
    files = [single_file_from_target(upstream) for upstream in ctx.attr.upstream if upstream.label.name != "spawn_dev_cfg6"]
    jar_locations = []
    file_targets = []
    for jar in ctx.attr.jars:
        path = "$(rlocation {})".format(ctx.expand_location("$(rlocationpath {})".format(jar.label), [jar]))
        files.extend(jar[DefaultInfo].files.to_list())
        arg = jar[AsCodeTypeProvider].arg
        if arg:
            path = path + "//" + _arg_string_and_runfiles(arg[AsCodeArgProvider].arg, file_targets).replace('"', '\\"')
        jar_locations.append(path)
    files.extend([single_file_from_target(target) for target in file_targets])
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.expand_template(
        output = script,
        is_executable = True,
        template = ctx.file._template,
        substitutions = {
            "FILE_ARGS": "\n".join(['FILE_ARG_{}={}'.format(i, '"$(rlocation {})"'.format(ctx.expand_location("$(rlocationpath {})".format(target.label), [target]))) for i, target in enumerate(file_targets)]),
            "CLI": ctx.toolchains["@rules_cfg6//:toolchain_type"].cfg6.cli,
            "DVJSON": ctx.attr.dvjson,
            "BSW_PKG": ctx.attr.bsw_pkg,
            "JARS": ' -c "{}"'.format('" -c "'.join(jar_locations)) if jar_locations else ""
        }
    )
    return [DefaultInfo(executable = script, runfiles = ctx.runfiles(files = files))]

dbg_as_code_script = rule(
    attrs = {
        "dvjson": attr.string(mandatory = True),
        "bsw_pkg": attr.string(mandatory = True),
        "jars": attr.label_list(providers = [AsCodeTypeProvider]),
        "upstream": attr.label_list(allow_files = True),
        "_template": attr.label(default = Label(":dbg_as_code_script_template.sh"), allow_single_file = True)
    },
    implementation = _dbg_as_code_script_impl,
    toolchains = ["@rules_cfg6//:toolchain_type"]
)

