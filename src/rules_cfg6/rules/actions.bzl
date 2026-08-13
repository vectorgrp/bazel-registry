load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("//toolchain:defs.bzl", "TOOLCHAIN_TYPE")

def _gui_script_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    cfg6 = ctx.toolchains[TOOLCHAIN_TYPE].cfg6
    evo1 = ctx.attr.evo1
    template = '"{dvcfg}" --project "{project}" --bsw-package "{bsw_pkg}" && read -srn 1 -p "Press any key to terminate..."' if evo1 else cfg6.gui_template
    ctx.actions.write(
        out,
        template.format(
            dvcfg = evo1 if evo1 else cfg6.gui,
            project = ctx.attr.dvjson,
            bsw_pkg = ctx.attr.bsw_pkg,
        ),
        is_executable = True,
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [ctx.file.upstream]))]

gui_script = rule(
    doc = "Internal rule for generating a launcher script for DaVinci Configurator Classic Version 6 GUI tool.",
    attrs = dict(_STD_CLI_ATTRS, evo1 = attr.string(doc = "The DaVinci Configurator Classic Version 6 Evo1 GUI executable for opening the project (absolute path).")),
    implementation = _gui_script_impl,
    toolchains = [TOOLCHAIN_TYPE],
)

def _edit_project_impl(name, visibility, tags, **kwargs):
    script_name = name + "_script"
    gui_script(
        name = script_name,
        visibility = ["//visibility:private"],
        tags = ["no-ide"],
        **kwargs
    )
    sh_binary(
        name = name,
        srcs = [script_name],
        visibility = visibility,
        tags = tags,
    )

edit_project = macro(
    doc = "Macro for editing the project of an `ecu_config` repo in DaVinci Configurator Classic Version 6 GUI tool.",
    inherit_attrs = gui_script,
    implementation = _edit_project_impl,
)

def _run_script_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        out,
        ctx.attr.command.format(
            dvcfg = ctx.toolchains[TOOLCHAIN_TYPE].cfg6.cli,
            project = ctx.attr.dvjson,
            bsw_pkg = ctx.attr.bsw_pkg,
            **{key: _rlocation(ctx, target) for key, target in ctx.attr.inputs.items()}
        ),
        is_executable = True,
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [ctx.file.upstream] + [file for target in ctx.attr.inputs.values() for file in target[DefaultInfo].files.to_list()]))]

_run_script = rule(
    doc = "Internal rule for running DaVinci Configurator Classic Version 6 on a DaVinci project.",
    attrs = dict(
        _STD_CLI_ATTRS,
        command = attr.string(doc = "Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.command)). Use `{dvcfg}` for the DaVinci Configurator Classic CLI executable, `{project}` for the .dvjson file and `{bsw_pkg}` for the BSW package folder.", mandatory = True),
        inputs = attr.string_keyed_label_dict(doc = 'Input files (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.inputs)). Use `{key}` to access file `input["key"]` in `command`.', allow_files = True),
    ),
    implementation = _run_script_impl,
    toolchains = [TOOLCHAIN_TYPE],
)

def _run_on_project_impl(name, visibility, tags, **kwargs):
    script_name = name + "_script"
    _run_script(
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
        tags = tags,
    )

run_on_project = macro(
    doc = "Macro for running DaVinci Configurator Classic Version 6 on the project of an `ecu_config` repo.",
    inherit_attrs = run_script,
    implementation = _run_on_project_impl,
)

def _create_project_script_impl(ctx):
    return _write_script(
        ctx,
        '"{dvcfg}" project create -b "{bsw_pkg}" --project-name {dvjson_name} -o "$BUILD_WORKSPACE_DIRECTORY/{folder}"',
        {"bsw_pkg": ctx.attr.bsw_pkg},
        dvcfg = ctx.toolchains[TOOLCHAIN_TYPE].cfg6.cli,
        dvjson_name = ctx.attr.dvjson_name,
        folder = ctx.label.package,
    )

create_project_script = rule(
    attrs = {
        "bsw_pkg": attr.label(allow_single_file = True, mandatory = True),
        "dvjson_name": attr.string(mandatory = True),
    },
    implementation = _create_project_script_impl,
    toolchains = [TOOLCHAIN_TYPE],
)

def _dvjson_impl(name, bsw_pkg, **kwargs):
    script_name = name + "_create_script"
    create_project_script(
        name = script_name,
        bsw_pkg = bsw_pkg,
        dvjson_name = name,
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

it provides the following targets:

- `<name>_create`: executable bazel target for initially creating the project inside the package via `bazel run //:<name>_create`.
- `<name>.dvjson`: the `.dvjson` file of the project (once it has been created), e.g. for use in `dvjson` attribute of module extension `ecu_config.project`.
""",
    attrs = {
        "bsw_pkg": attr.label(doc = "The BSW package folder.", allow_single_file = True, mandatory = True),
    },
    implementation = _dvjson_impl,
)

def _rlocation(ctx, target):
    if type(target) == _LIST_TYPE:
        return '","'.join(["$(rlocation {})".format(ctx.expand_location("$(rlocationpath {})".format(t.label), [t])) for t in target])
    return "$(rlocation {})".format(ctx.expand_location("$(rlocationpath {})".format(target.label), [target]))

def _dvcfg_cli_executable_script_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "/" + ctx.label.name + ".sh")
    project_root_dir = None
    for file in project_info.project_files.to_list():
        if file.is_directory:
            project_root_dir = file.short_path
            break
        elif file.extension == "dvjson":
            project_root_dir = file.parent.short_path
            break
    if not project_root_dir:
        fail("dvjson missing in project files.")
    ctx.actions.write(
        out,
        _format_command(ctx, project_root_dir, ctx.attr.command, **{key: ",".join([f.short_path for f in target[DefaultInfo].files]) for key, target in ctx.attr.inputs.items()}),
        is_executable = True,
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [ctx.file.upstream] + [file for target in ctx.attr.inputs.values() for file in target[DefaultInfo].files.to_list()]))]

dvcfg_cli_executable_script = rule(
    doc = "Internal rule for creating a generic executable on a DaVinci project.",
    attrs = dict(
        upstream = attr.label(mandatory = True, providers = [PipelineCfg6ProjectInfo]),
        command = attr.string(doc = "Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.command)). Use `{dvcfg}` for the DaVinci Configurator Classic CLI executable, `{project}` for the .dvjson file and `{bsw_pkg}` for the BSW package folder.", mandatory = True),
        inputs = attr.string_keyed_label_dict(doc = 'Input files (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.inputs)). Use `{key}` to access file `input["key"]` in `command`.', allow_files = True),
    ),
    implementation = _dvcfg_cli_executable_script_impl,
    toolchains = [TOOLCHAIN_TYPE],
)

def _pipeline_executable_impl(name, visibility, tags, **kwargs):
    script_name = name + "_script"
    dvcfg_cli_executable_script(
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
        tags = tags,
    )

pipeline_executable = macro(
    doc = "Macro for creating a generic executable on a DaVinci project.",
    inherit_attrs = dvcfg_cli_executable_script,
    implementation = _pipeline_executable_impl,
)

def _write_script(ctx, command, targets_dict, **kwargs):
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        out,
        command.format(**({k: _rlocation(ctx, target) for k, target in targets_dict.items()} | kwargs)),
        is_executable = True,
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [file for targets in targets_dict.values() for target in (targets if type(targets) == _LIST_TYPE else [targets]) for file in target[DefaultInfo].files.to_list()]))]

def _generate_foundation_layer_script_impl(ctx):
    includelist, substitution = (' --includelist "{filter}"', {"filter": ctx.attr.filter}) if ctx.attr.filter else ("", {})
    return _write_script(
        ctx,
        '"{core}" -application com.vector.cfg.bswmdmgen.app.flApplication -b "{bsw_pkg}" --force -o "$BUILD_WORKSPACE_DIRECTORY/{folder}"' + includelist,
        {"bsw_pkg": ctx.attr.bsw_pkg} | substitution,
        core = ctx.toolchains[TOOLCHAIN_TYPE].cfg6.core,
        folder = ctx.file.output.short_path,
    )

generate_foundation_layer_script = rule(
    attrs = {
        "bsw_pkg": attr.label(doc = "The BSW package folder.", allow_single_file = True, mandatory = True),
        "output": attr.label(doc = "The output folder.", allow_single_file = True, mandatory = True),
        "filter": attr.label(doc = "Optional filter file containing the definition-references of all modules to be generated, separated by newlines. If this is not provided all modules of the BSW package are generated.", allow_single_file = True),
    },
    implementation = _generate_foundation_layer_script_impl,
    toolchains = [TOOLCHAIN_TYPE],
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
        tags = tags,
    )

generate_foundation_layer = macro(
    doc = "Rule for generating the foundation layer API sources.",
    inherit_attrs = generate_foundation_layer_script,
    implementation = _generate_foundation_layer_impl,
)
