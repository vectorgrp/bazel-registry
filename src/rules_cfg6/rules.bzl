load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@dvcfg6//:cfg6.bzl", "script", "bsw_pkg", "SPECIAL_KEYS", "export_env", "run_shell", "runfiles", "input_files")

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
    return "//" + json.encode(json.encode(arg).replace("{", "{{").replace("}", "}}"))

def single_file_from_target(target):
    l = target[DefaultInfo].files.to_list()
    if len(l) != 1:
        fail("Expected exactly one file from {} but got {}.".format(target.label, len(l)))
    return l[0]

def _is_absolute(s):
    return s.startswith("/") or s.startswith("\\") or (len(s) > 2 and s[1] == ":" and (s[2] == "/" or s[2] == "\\"))

DvProjectProvider = provider()

_ENV_FLAG_ATTR = { "_env_flag": attr.label(default = "@dvcfg6//:env", providers = [BuildSettingInfo]) }
_BSW_PKG_ATTR = { "bsw_pkg": attr.label(doc = "The BSW package.", allow_files = True, mandatory = True) }
_TOOLCHAIN = Label("@dvcfg6//:toolchain_type")
_CFG6_TOOLCHAIN = [_TOOLCHAIN]

def _cfg6(ctx):
    return ctx.toolchains[_TOOLCHAIN].cfg6

def _generate_foundation_layer_script_impl(ctx):
    includelist, substitution = (' {--includelist}', { "--includelist": ctx.attr.filter }) if ctx.attr.filter else ("", {})
    dict = { "core": _cfg6(ctx).core, bsw_pkg: ctx.attr.bsw_pkg, "-o": ctx.attr.output } | substitution
    s = script(ctx, ctx.label.name + ".sh", export_env(ctx) + '{core} -application com.vector.cfg.bswmdmgen.app.flApplication {-b} --force {-o}' + includelist, False, dict)
    r = runfiles(ctx, dict)
    return [DefaultInfo(executable = s, runfiles = r)]

generate_foundation_layer_script = rule(
    attrs = _BSW_PKG_ATTR | _ENV_FLAG_ATTR | {
        "output": attr.label(doc = "The destination folder for generated sources.", allow_single_file = True, mandatory = True),
        "filter": attr.label(doc = "Optional filter file containing the definition-references of all modules to be generated, separated by newlines. If this is not provided all modules of the BSW package are generated.", allow_single_file = True)
    },
    implementation = _generate_foundation_layer_script_impl,
    toolchains = _CFG6_TOOLCHAIN
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

def _exclusive_label(ctx):
    return { "DVCFG_EXCLUSIVE_LABEL": str(ctx.label) }

def _system_extract_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    dict = { "xpro": _cfg6(ctx).xpro, "-i": ctx.attr.src, "ecu": ctx.attr.ecu or ctx.label.name, "out": out.path }
    return [run_shell(ctx, out, "{xpro} extract-sysd {-i} -e {ecu} '{out}'", dict, _exclusive_label(ctx))]

system_extract = rule(
    doc = "Rule for extracting a given ECU from a system description.",
    attrs = _ENV_FLAG_ATTR | {
        "src": attr.label(doc = "The system description .arxml files from which to extract the given ECU.", allow_files = [".arxml"], mandatory = True),
        "ecu": attr.string(doc = "The ECU to extract from the given system description (defaults to rule name).")
    },
    implementation = _system_extract_impl,
    toolchains = _CFG6_TOOLCHAIN
)

def _merged_extract_impl(ctx):
    xpro = _cfg6(ctx).xpro
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    dict = { "xpro": xpro, "-i": ctx.attr.src, "out": out.path }
    return [run_shell(ctx, out, "{xpro} merge {-i} '{out}'", dict, _exclusive_label(ctx))]

merged_extract = rule(
    doc = "Rule for merging multiple .arxml files into an ECU extract.",
    attrs = _ENV_FLAG_ATTR | {
        "src": attr.label(doc = "The .arxml files to merge into one ECU extract.", allow_files = [".arxml"], mandatory = True),
    },
    implementation = _merged_extract_impl,
    toolchains = _CFG6_TOOLCHAIN
)

def _variant_extract_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    cmd = '{xpro} variant-merge {-m} -e {_evs} '
    for variant in ctx.attr.srcs.keys():
        cmd += '-f {v}={{{v}}} '.format(v = variant)
    dict = _check_keys({ "xpro": _cfg6(ctx).xpro, "-m": ctx.attr.config, "_evs|,": ctx.attr.evs, "_out": out.path }, ctx.attr.srcs)
    return [run_shell(ctx, out, cmd + '"{_out}"', dict, _exclusive_label(ctx))]

variant_extract = rule(
    doc = "Rule for creating a variant ECU extract from invariant extracts.",
    attrs = _ENV_FLAG_ATTR | {
        "evs": attr.label(doc = "The .arxml files containing the EvaluatedVariantSet.", allow_files = [".arxml"], mandatory = True),
        "srcs": attr.string_keyed_label_dict(doc = 'One extract file for each variant in the EvaluatedVariantSet. E.g.: { "VariantA": ":ExtractA", ... }', allow_files = [".arxml"], allow_empty = False, mandatory = True),
        "config": attr.label(doc = "The merge configuration .xml file.", allow_single_file = [".xml"], mandatory = True)
    },
    implementation = _variant_extract_impl,
    toolchains = _CFG6_TOOLCHAIN
)

def _create_project_script_impl(ctx):
    dict = { "dvcfg": _cfg6(ctx).cli, bsw_pkg: ctx.attr.bsw_pkg, "name": ctx.attr.dvjson_name, "folder": ctx.label.package }
    s = script(ctx, ctx.label.name + ".sh", export_env(ctx) + '{dvcfg} project create {-b} --project-name {name} -o "$BUILD_WORKSPACE_DIRECTORY/{folder}"', False, dict)
    return [DefaultInfo(executable = s, runfiles = runfiles(ctx, dict))]

create_project_script = rule(
    attrs = _BSW_PKG_ATTR | _ENV_FLAG_ATTR | { "dvjson_name": attr.string(mandatory = True) },
    implementation = _create_project_script_impl,
    toolchains = _CFG6_TOOLCHAIN
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
        use_bash_launcher = True
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
    attrs = _BSW_PKG_ATTR,
    implementation = _dvjson_impl
)

def _derive_ecuc_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    dict = { "dvcfg": _cfg6(ctx).cli, bsw_pkg: ctx.attr.bsw_pkg, "out": out.path, "srcs": ctx.attr.srcs }
    cmd = "{dvcfg} derive-ecuc run {-b} "
    if ctx.attr.settings:
        cmd += "{-c} "
        dict = dict | { "-c": ctx.attr.settings }
    return [run_shell(ctx, out, cmd + "-o '{out}' {srcs}", dict, _exclusive_label(ctx))]

derive_ecuc = rule(
    doc = "Derive an ECU configuration from the given input files.",
    attrs = _BSW_PKG_ATTR | _ENV_FLAG_ATTR | {
        "settings": attr.label(doc = "Optional configuration file.", allow_single_file = [".json"]),
        "srcs": attr.label_list(doc = "Input files (ECU extract and - for post-build selectable only - EvaluatedVariantSet).", allow_files = [".arxml"], allow_empty = False)
    },
    implementation = _derive_ecuc_impl,
    toolchains = _CFG6_TOOLCHAIN
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

_PREPARE_FOLDER = "rm -rf '{_parent_dir_}'\nmkdir -p '{project_dir}'\n"
_UNTAR = "tar --force-local -zxf {_upstream_} -C '{project_dir}'\n"
_COMMON_TAR_OPTS = "--force-local --exclude '*.~lock' --exclude 'dvcfg.local.properties' --exclude 'BUILD' --exclude 'BUILD.bazel' --exclude '.gitignore'"
_TAR = "\ntar " + _COMMON_TAR_OPTS + " -zcf '{_parent_dir_}/dvproject.tar.gz' -C '{project_dir}' .\nrm -rf '{project_dir}'"
_STOP = '\n{dvcfg} stop {-p} --force'

def _from_scratch_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "/dvproject.tar.gz")
    cfg6 = _cfg6(ctx)
    cmd = _PREPARE_FOLDER + "{dvcfg} project create {-b} --project-name '{name}' -o '{project_dir}'"
    name = ctx.attr.project_name or ctx.label.package[ctx.label.package.rfind("/") + 1:] or ctx.label.name
    dict = { "_parent_dir_": out.dirname, "project_dir": out.dirname + "/_", "dvcfg": cfg6.cli, bsw_pkg: ctx.attr.bsw_pkg, "name": name }
    patcher_tool = None
    if ctx.attr.settings:
        cmd += "\n'{patcher}' '{project_dir}/{name}.dvjson' {settings}"
        dict = dict | { "patcher": cfg6.settings_patcher.executable.path, "settings": ctx.attr.settings }
        patcher_tool = [cfg6.settings_patcher]
    return [run_shell(ctx, out, cmd + _TAR, dict, _exclusive_label(ctx), ctx.label.name + "/script.sh", patcher_tool), DvProjectProvider(dvjson = name + ".dvjson", bsw_pkg = ctx.attr.bsw_pkg)]

from_scratch = rule(
    doc = "Create a new DaVinci Configurator Classic Version 6 project.",
    attrs = _BSW_PKG_ATTR | _ENV_FLAG_ATTR | {
        "project_name": attr.string(doc = "Optional name for the DaVinci project (e.g. used as .dvjson file name). Defaults to last segment of this target's package name or (for targets in the root package) to this target's name."),
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
    toolchains = _CFG6_TOOLCHAIN
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
    exclude = (" --exclude '" + "' --exclude '".join(ctx.attr.derived) + "'") if ctx.attr.derived else ""
    p = DvProjectProvider(
        dvjson = dvjson_file.basename,
        bsw_pkg = ctx.attr.bsw_pkg,
        hybrid = dvjson_file.dirname,
        copy_hybrid = "tar " + _COMMON_TAR_OPTS + exclude + " -hcf - -C '" + dvjson_file.dirname + "' . | tar --force-local -xf - -C '{project_dir}'"
    )
    return [run_shell(ctx, out, _PREPARE_FOLDER + p.copy_hybrid + _TAR, { "_parent_dir_": out.dirname, "project_dir": out.dirname + "/_", "_": ctx.attr.srcs }, None, ctx.label.name + "/script.sh"), p]

hybrid = rule(
    doc = "Use an existing DaVinci Configurator Classic Version 6 project.",
    attrs = _BSW_PKG_ATTR | _ENV_FLAG_ATTR | {
        "srcs": attr.label_list(doc = """The files of a checked-in project that invalidate this target when they change:

- The .dvjson file (always required).
- All settings .json files (referenced by the .dvjson file).

All of these files must be contained below the parent folder of the .dvjson file.

Usually a `hybrid` target is extended using [apply_command](#apply_command).
All checked-in project files must be listed as inputs of the `apply_command` target that needs to re-run when they change.

Typically, it is the `project update` command that needs to be re-executed when any files in the `./Config` folder have been modified:

```starlark
apply_command(
    name = "project",
    project = ":upstream",
    command = '{dvcfg} project update {-p} {-b}',
    # changes in any file inside the ./Config folder invalidate this target
    # instable ReferenceCorrectionData.arxml is excluded
    inputs = { "user_ecuc": glob(include = ["Config/**"], exclude = ["Config/StructuredExtract/BswConfig/ReferenceCorrectionData.arxml"]) }
)
```

Modifications to the files invalidate the target even if they are not used in the actual CLI call.""", allow_files = True),
        "derived": attr.string_list(doc = "Optional GNU tar exclude patterns listing all derived project files/folders.", default = ["./Output"])
    },
    implementation = _hybrid_impl
)

def _check_keys(built_in, user):
    reserved = [SPECIAL_KEYS.get(k) if k in SPECIAL_KEYS else k.split("|")[0] for k in built_in]
    clashes = [k for k in user.keys() if k.split("|")[0] in reserved]
    clashes and fail("The following keys are reserved for internal purposes: {}. Please choose different ones.".format(", ".join(clashes)))
    return built_in | user

_COMMAND_ATTRS = {
    "command": attr.string(doc = """Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell)).
Separate multiple CLI calls with newline or semicolon.""", mandatory = True),
    "inputs": attr.string_keyed_label_dict(doc = """Inputs used in `command`. The following rules apply:

- Dictionary keys starting with `-` (minus): `inputs = { "-f": "<label>" }` and `command = "... {-f} ..."` yield a resulting command line like this: `... -f <file1> -f <file2> ...` (i.e., all files are listed with the preceeding switch).
- Dictionary keys containing `|` (pipe): `inputs = { "files|,": "<label>" }` and `command = "... -f {files} ..."` yield a resulting command line like this: `... -f <file1>,<file2> ...` (i.e, all files are listed, joined by the given separator).
- Pipe and separator are optional defaulting to a single space separator, i.e.: `inputs = { "files": "<label>" }` and `command = "import {files}"` yield a resulting command line like this: `import <file1> <file2> ...`.""", allow_files = True)
}

def _next_token_and_rest(s):
    rest = s.lstrip()
    if s.find("\n", 0, len(s) - len(rest)) != -1:
        return "", s
    s = rest
    if s.startswith('"') or s.startswith("'"):
        segments = s[1:].split(s[0])
        for i, seg in enumerate(segments):
            if not seg.endswith("\\"):
                return s[0] + s[0].join(segments[:i + 1]) + s[0], s[0].join(segments[i + 1:])
    for i in range(len(s)):
        if (s[i].isspace() or s[i] == ";") and (i == 0 or s[i - 1] != "\\"):
            return s[:i], s[i:]
    return s, ""

def _is_cmd(s, *cmds):
    for c in cmds:
        token, s = _next_token_and_rest(s)
        if token != c:
            return False
    return True

def _fixup_eac_arg(c, is_hybrid, dict):
    if _is_cmd(c, "eac"):
        if is_hybrid:
            c = c.replace("eac", "eac --hybrid", 1)
        i = c.find("//")
        if i != -1:
            arg = c[i + 2:]
            for k in dict.keys():
                k = SPECIAL_KEYS.get(k, k)
                arg = arg.replace("{{" + k + "}}", "{" + k + "}")
            return c[:i + 2] + arg
    return c

def _join_dvcfg_cmds(p, commands, dict):
    result = ""
    differ_used = False
    for cmd_index, cmd in enumerate(commands):
        diff_cmds = cmd.split("{diff}")
        dvcfg_prefix = "" if cmd_index == 0 else "{dvcfg}"
        if len(diff_cmds) == 1:
            result = result + dvcfg_prefix + cmd
            continue
        differ_used = True
        diff_with_predecessor = False
        dvcfg_cmd = diff_cmds[0]
        for diff_cmd in diff_cmds[1:]:
            jsonl, rest = _next_token_and_rest(diff_cmd)
            if not jsonl:
                fail("Expected a project folder relative path to the JSONL output file as first argument for the diff command.")
            theirs, rest = _next_token_and_rest(rest)
            if theirs:
                if not (theirs.startswith("{") and theirs.endswith("}")):
                    fail("Expected notation like {theirs} for the other project of the diff command.")
                theirs = theirs[1:len(theirs) - 1]
                if not dict.get(theirs):
                    fail("Expected " + theirs + " (used as theirs for the diff command) to be present in the rule's inputs.")
                dvcfg_cmd = dvcfg_cmd + "mkdir -p '{_parent_dir_}/___'\n"\
                    + _UNTAR.replace("_upstream_", theirs).replace("{project_dir}", "{_parent_dir_}/___")\
                    + "{dvcfg} automation run {-b} {-p} --no-save -l {rules_cfg6_differ} -t diff -a diff -a '\"-t=../___/" + dict.get(theirs)[DvProjectProvider].dvjson + jsonl + "\"'\nrm -rf '{_parent_dir_}/___'"\
                    + rest
            elif diff_with_predecessor:
                fail("Supporting one diff per CLI call, only.")
            else:
                diff_with_predecessor = True
                dvcfg_cmd = "mkdir -p '{_parent_dir_}/__'\n"\
                    + "cp -r '{project_dir}/.' '{_parent_dir_}/__/' || true\n"\
                    + dvcfg_prefix + dvcfg_cmd\
                    + "{dvcfg} automation run {-b} {-p} --no-save -l {rules_cfg6_differ} -t diff -a diff -a '\"-t=../__/" + p.dvjson + jsonl + "\"'\nrm -rf '{_parent_dir_}/__'"\
                    + rest
        result = result + ("" if diff_with_predecessor else dvcfg_prefix) + dvcfg_cmd
    return result, differ_used

def _internal_apply_command_impl(ctx):
    p = ctx.attr.project[DvProjectProvider]
    out = ctx.actions.declare_file(ctx.label.name + "/dvproject.tar.gz")
    dict = _check_keys(
        {
            "_upstream_": ctx.attr.project,
            "_parent_dir_": out.dirname,
            "project_dir": out.dirname + "/_",
            "dvcfg": _cfg6(ctx).cli,
            bsw_pkg: p.bsw_pkg,
            "-p": "-p '" + out.dirname + "/_/" + p.dvjson + "'"
        },
        ctx.attr.inputs
    )
    is_hybrid = hasattr(p, "hybrid")
    dvcfg_commands = [_fixup_eac_arg(c, is_hybrid, dict) for c in ctx.attr.command.split("{dvcfg}")]
    hybrid = (p.copy_hybrid + "\n") if (is_hybrid and [c for c in dvcfg_commands if _is_cmd(c, "project", "update")]) else ""
    cmd, differ_used = _join_dvcfg_cmds(p, dvcfg_commands, dict)
    if differ_used:
        dict = dict | { "rules_cfg6_differ": _cfg6(ctx).differ }
    return [run_shell(ctx, out, _PREPARE_FOLDER + _UNTAR + hybrid + cmd + _STOP + _TAR, dict, ctx.attr.env, ctx.label.name + "/script.sh"), p]

_ENV_ATTR = { "env": attr.string_dict(doc = """Optional environment variables for this command.

To specify "DaVinci-Configurator-6-only" environment variables for individual calls use the repeatable flag `--@rules_cfg6//:env=KEY=VALUE` on the command line:

```
bazel run //my:target --@rules_cfg6//:env=DVCFG_CACHE_DISABLED=true
```

Use `--@rules_cfg6//:env` in `.bazelrc` to specify environment variables for all DaVinci Configurator 6 calls:

```
build:linux --@rules_cfg6//:env=DVCFG_JVM_ARGS="-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts -Xss2m"
```
""") }

internal_apply_command = rule(
    attrs = _ENV_ATTR | _ENV_FLAG_ATTR | _COMMAND_ATTRS | { "project": attr.label(doc = "The project to which to apply the command.", allow_single_file = True, providers = [DvProjectProvider], mandatory = True) },
    implementation = _internal_apply_command_impl,
    toolchains = _CFG6_TOOLCHAIN
)

def _apply_command_impl(name, dev_target, **kwargs):
    internal_apply_command(name = name, **kwargs)
    if dev_target:
        run_command(name = name + "_dev", **kwargs)

apply_command = macro(
    doc = """Extend a project by running a command on it (see [here](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/references/cli/index.html) for available commnds). E.g.:

- `{dvcfg} project update {-b} {-p}` updates the project (e.g. on input file changes).
- `{dvcfg} project validate {-b} {-p} --fail-on NONE` creates a validation report. [project_file](#project_file) with `path = "Output/Log/ValidationOutput.json"` yields the report.
- `{dvcfg} project generate {-b} {-p}` generates BSW code. [project_folder](#project_folder) with `path = "Output/Source/GenData"` yields the generation result.
- `{dvcfg} project generate-swct {-b} {-p}` generates SWC templates. [project_folder](#project_folder) with `path = "Output/Source/Templates"` yields the generation result.
- `{dvcfg} automation run {-b} {-p} {-l} -t MyTask` runs a PAI task (see `inputs` on how to provide the script location `{-l}`).
- `{dvcfg} export run {-b} {-p} -o "{project_dir}" -e everything` exports the entire AUTOSAR model. [project_file](#project_file) with `path = "Exported_everything.arxml"` yields the result.

`{dvcfg}` is expanded to the path of the DaVinci Configurator 6 CLI executable.
Use `{-p}` for the project and `{-b}` for the BSW package.
`{project_dir}` is expanded to the project folder (unquoted; useful for specifying output locations).

The `{diff}` command can be used to compare the states of a project before and after a command has been applied. E.g., a command like

```
{dvcfg} eac {-b} {-p} ...
{diff} eac.jsonl

{dvcfg} project update {-b} {-p}
{diff} update.jsonl
```

applies EaC and then updates the project. Additionally two JSONL files are created inside the project:

- `eac.jsonl` contains the comparison of the project before and after EaC has been applied.
- `update.jsonl` contains the comparison of the project after EaC has been applied and after the project has been updated.

The `{diff}` command can also be used with a second argument:

```
{diff} diff.jsonl {theirs}
```

If used like this, `input` is expected to contain an entry like `{ "theirs": ":some_project" }` where `:some_project`
is a target pointing to another DaVinci project.

Use [project_file](#project_file) with the same path as has been procided to `{diff}` to extract the created JSONL reports.
""",
    inherit_attrs = internal_apply_command,
    attrs = { "dev_target": attr.bool(doc = "Setting this to `True` results in a convenience development target `<name>_dev` for manually running/debugging the command.", configurable = False) },
    implementation = _apply_command_impl
)

def _run_command_script_impl(ctx):
    cmd = ctx.attr.command
    dict = {
        "_parent_dir_": ctx.label.name,
        "project_dir": ctx.label.name + "/_",
        "dvcfg": _cfg6(ctx).cli,
    }
    is_hybrid = False
    p = None
    if ctx.attr.project:
        p = ctx.attr.project[DvProjectProvider]
        dvjson = ctx.label.name + "/_/" + p.dvjson
        if hasattr(p, "hybrid"):
            is_hybrid = True
            hybrid_dir = "$BUILD_WORKSPACE_DIRECTORY/{}".format(p.hybrid)
            dvjson = hybrid_dir + "/" + p.dvjson
            dict = dict | { "hybrid_dir": hybrid_dir }
            cmd = 'cp -r "{project_dir}/." "{hybrid_dir}"\n' + cmd.replace("{project_dir}", "{hybrid_dir}")
        dict = dict | { "_upstream_": ctx.attr.project, bsw_pkg: p.bsw_pkg, "-p": '-p "{}"'.format(dvjson) }
    dict = _check_keys(dict, ctx.attr.inputs)
    cmd, differ_used = _join_dvcfg_cmds(p, [_fixup_eac_arg(c, is_hybrid, dict) for c in cmd.split("{dvcfg}")], dict)
    if differ_used:
        differ = _cfg6(ctx).differ
        dict = dict | { "rules_cfg6_differ": differ }
        r = runfiles(ctx, dict).merge(differ[DefaultInfo].default_runfiles)
    else:
        r = runfiles(ctx, dict)
    cmd = 'export DVCFG_BUILD_SYSTEM_PATH="$BUILD_WORKSPACE_DIRECTORY/{}"\n'.format(ctx.label.package) + cmd
    if p:
        cmd = _PREPARE_FOLDER + _UNTAR + cmd
    s = script(ctx, ctx.label.name + "/script.sh", export_env(ctx) + cmd, False, dict)
    return [DefaultInfo(executable = s, runfiles = r)]

run_command_script = rule(
    attrs = _COMMAND_ATTRS | _ENV_FLAG_ATTR | { "project": attr.label(doc = "The project on which to run the command. Only required if the command needs a project.", allow_single_file = True, providers = [DvProjectProvider]) },
    implementation = _run_command_script_impl,
    toolchains = _CFG6_TOOLCHAIN
)

def _run_command_impl(name, project, command, inputs, tags, **kwargs):
    script_name = name + "_script"
    run_command_script(
        name = script_name,
        project = project,
        command = command,
        inputs = inputs,
        tags = ["no-ide"]
    )
    sh_binary(
        name = name,
        srcs = [script_name],
        use_bash_launcher = True,
        tags = tags + ["dvcfg-dev"],
        **kwargs
    )

run_command = macro(
    doc = """Run a command on a project (see [here](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/references/cli/index.html) for available commnds).
See [apply_command](#apply_command) for some examples.
When running on an hybrid project, the resulting project is written back to the workspace.
Use `$BUILD_WORKSPACE_DIRECTORY` to specify locations relative to the workspace.""",
    inherit_attrs = run_command_script,
    attrs = _ENV_ATTR | { "tags": attr.string_list(configurable = False) },
    implementation = _run_command_impl
)

_NO_DEFAULT_CONTENT = "\0"

def _project_file_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out or ctx.label.name)
    path = ctx.attr.path.replace("\\", "/")
    if not path.startswith("./"):
        path = "./" + path
    cmd = "{{ tar --force-local -xzOf '{}' '{}'" + ("" if ctx.attr.default_content == _NO_DEFAULT_CONTENT else ' || printf \'%s\' "{}" '.format(ctx.attr.default_content.replace('"', '\\"'))) + "; }} > '{}'"
    ctx.actions.run_shell(outputs = [out], inputs = [ctx.file.project], command = cmd.format(ctx.file.project.path, path, out.path))
    return [DefaultInfo(files = depset([out]))]

project_file = rule(
    doc = "Get a file from a project.",
    attrs = {
        "project": attr.label(doc = "The project from which to get the file.", allow_single_file = True, mandatory = True),
        "path": attr.string(doc = "The path of the file relative to the project folder.", mandatory = True),
        "out": attr.string(doc = "Optional name for the created file (defaults to label name)."),
        "default_content": attr.string(doc = "Optional default content to return in case the project does not contain a file at the given path. Omit this to let the action fail in case the file is missing.", default = _NO_DEFAULT_CONTENT)
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
    s = script(ctx, ctx.label.name + ".sh", "tar --force-local -tzf {project} | sed -e '/\\/$/d' -e 's|^\\./||'", False, dict)
    return [DefaultInfo(executable = s, runfiles = ctx.runfiles(files = input_files(dict)))]

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
    s = script(ctx, ctx.label.name + ".sh", cmd, False, dict)
    return [DefaultInfo(executable = s, runfiles = ctx.runfiles(files = input_files(dict)))]

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
        env = env,
        tags = ["no-ide"]
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
    run_command(command = ("'" + evo1 + "'" if evo1 else "{dvcfg} project start") + """ {-b} {-p}
echo 'Project has been opened in DaVinci Configurator Classic Version 6.'
echo 'Terminate this run to shut down DaVinci Configurator Classic Version 6.'
read -n 1 -s -r -p 'Press any key to terminate...'""" + _STOP, **kwargs)

open = macro(
    doc = "Open a project in DaVinci Configurator Classic Version 6.",
    attrs = {
        "project": attr.label(doc = "The project to open.", allow_single_file = True, mandatory = True),
        "evo1": attr.string(doc = "Optional absolute path to a DaVinci Configurator Classic Version 6 Evo1 GUI launcher.", configurable = False)
    },
    implementation = _open_impl
)
