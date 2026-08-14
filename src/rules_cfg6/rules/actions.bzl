"""Utility macros for project generation and GUI viewing and editing."""

load("//private:project_provider.bzl", "Cfg6ProjectInfo", "UPSTREAM_ATTR", "get_bsw_pkg_root_short_path", "get_project_root", "get_project_root_short_path")
load("//private:script_action.bzl", "make_script_action")
load("//toolchain:defs.bzl", "TOOLCHAIN_TYPE")

def _open_project_command_builder(ctx, editable):
    toolchain = ctx.toolchains[TOOLCHAIN_TYPE].cfg6
    transitive_inputs = []
    project_info = ctx.attr.upstream[Cfg6ProjectInfo]
    bsw_pkg_root_path = get_bsw_pkg_root_short_path(project_info)
    transitive_inputs.append(project_info.bsw_pkg_files)

    if editable:
        for f in project_info.project_files.to_list():
            if not f.is_source:
                fail("Generated project")
        project_root_path = "$BUILD_WORKSPACE_DIRECTORY/" + get_project_root(project_info)
    else:
        project_root_path = get_project_root_short_path(project_info)
        transitive_inputs.append(project_info.project_files)

    if toolchain.files:
        transitive_inputs.append(toolchain.files)

    if toolchain.gui_exe:
        script = getattr(toolchain.gui_exe, "short_path", toolchain.gui_exe)
    else:
        script = "{} project start ".format(getattr(toolchain.cli_exe, "short_path", toolchain.cli_exe))
    script += " -p {} -b {} && read -srn 1 -p \"Press any key to terminate...\"".format(project_root_path, bsw_pkg_root_path)

    return struct(
        script = script,
        inputs = depset(transitive=transitive_inputs).to_list(),
    )

# buildifier: disable=unused-variable
_cfg6_edit_project_script, cfg6_edit_project = make_script_action(
    doc = "Macro for editing the project of an `ecu_config` repo in DaVinci Configurator Classic Version 6 GUI tool.",
    attrs = UPSTREAM_ATTR,
    command_builder = lambda ctx: _open_project_command_builder(ctx, True),
    toolchains = [TOOLCHAIN_TYPE],
)

# buildifier: disable=unused-variable
_cfg6_view_project_script, cfg6_view_project = make_script_action(
    doc = "Macro for viewing a project of an `ecu_config` repo in DaVinci Configurator Classic Version 6 GUI tool.",
    attrs = UPSTREAM_ATTR,
    command_builder = lambda ctx: _open_project_command_builder(ctx, False),
    toolchains = [TOOLCHAIN_TYPE],
)

#def _run_script_command_builder(ctx):
#    out = ctx.actions.declare_file(ctx.label.name + ".sh")
#    ctx.actions.write(
#        out,
#        ctx.attr.command.format(
#            dvcfg = ctx.toolchains[TOOLCHAIN_TYPE].cfg6.cli,
#            project = ctx.attr.dvjson,
#            bsw_pkg = ctx.attr.bsw_pkg,
#            **{key: _rlocation(ctx, target) for key, target in ctx.attr.inputs.items()}
#        ),
#        is_executable = True,
#    )
#    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [ctx.file.upstream] + [file for target in ctx.attr.inputs.values() for file in target[DefaultInfo].files.to_list()]))]
#
#run_on_project = make_script_action(
#    doc = "Macro for editing the project of an `ecu_config` repo in DaVinci Configurator Classic Version 6 GUI tool.",
#    attrs = dict(
#        UPSTREAM_ATTR,
#        command = attr.string(doc = "Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.command)). Use `{dvcfg}` for the DaVinci Configurator Classic CLI executable, `{project}` for the .dvjson file and `{bsw_pkg}` for the BSW package folder.", mandatory = True),
#        inputs = attr.string_keyed_label_dict(doc = 'Input files (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.inputs)). Use `{key}` to access file `input["key"]` in `command`.', allow_files = True),
#    ),
#    implementation = _run_script_impl,
#    toolchains = [TOOLCHAIN_TYPE],
#    command_builder = _run_script_command_builder,
#)

def _create_project_script_command_builder(ctx):
    toolchain = ctx.toolchains[TOOLCHAIN_TYPE].cfg6
    inputs = []
    inputs.extend(ctx.files.bsw_pkg)
    if toolchain.files:
        inputs.extend(toolchain.files.to_list())

    bsw_pkg_root = None

    # xxx find root of bsw pkg
    for file in ctx.files.bsw_pkg:
        if "/Components" in file.short_path:
            bsw_pkg_root = file.short_path.rpartition("/Components")[0]
            break
    if not bsw_pkg_root:
        fail("Could not find root of bsw pkg")

    script = '"{dvcfg}" project create -b "{bsw_pkg_root}" --project-name "{dvjson_name}" -o "$BUILD_WORKSPACE_DIRECTORY/{folder}"'.format(
        dvcfg = getattr(toolchain.cli_exe, "short_path", toolchain.cli_exe),
        bsw_pkg_root = bsw_pkg_root,
        dvjson_name = ctx.attr.dvjson_name,
        folder = ctx.label.package,
    )

    return struct(
        script = script,
        inputs = inputs,
    )

_create_project_script, create_project = make_script_action(
    # buildifier: disable=unused-variable
    attrs = {
        "bsw_pkg": attr.label(doc = "The BSW package folder.", mandatory = True),
        "dvjson_name": attr.string(mandatory = True),
    },
    command_builder = _create_project_script_command_builder,
    toolchains = [TOOLCHAIN_TYPE],
)

def _dvjson_impl(name, bsw_pkg, **kwargs):
    create_project(
        name = name + "_create",
        bsw_pkg = bsw_pkg,
        dvjson_name = name,
        **kwargs
    )

    native.exports_files([name + ".dvjson"])

dvjson = macro(
    doc = """Macro for creating a DaVinci project.

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

def _generate_foundation_layer_builder(ctx):
    bsw_pkg_root = None
    toolchain = ctx.toolchains[TOOLCHAIN_TYPE].cfg6

    # xxx find root of bsw pkg
    for file in ctx.files.bsw_pkg:
        if "/Components" in file.short_path:
            bsw_pkg_root = file.short_path.rpartition("/Components")[0]
            break
    if not bsw_pkg_root:
        fail("Could not find root of bsw pkg")

    inputs = []
    inputs.extend(ctx.files.bsw_pkg)
    if toolchain.files:
        inputs.append(toolchain.files.to_list())

    script = '"{core}" -application com.vector.cfg.bswmdmgen.app.flApplication -b "{bsw_pkg_root}" --force -o "$BUILD_WORKSPACE_DIRECTORY/{folder}"'.format(
        core = getattr(toolchain.core_exe, "short_path", toolchain.core_exe),
        bsw_pkg_root = bsw_pkg_root,
        folder = ctx.file.output.short_path,
    )

    if ctx.attr.filter:
        script += "--includelist " + ctx.file.filter.short_path
        inputs.append(ctx.file.filter)

    return struct(
        script = script,
        inputs = inputs,
    )

_generate_foundation_layer_script, generate_foundation_layer = make_script_action(
    # buildifier: disable=unused-variable
    attrs = {
        "bsw_pkg": attr.label(doc = "The BSW package folder.", allow_single_file = True, mandatory = True),
        "output": attr.label(doc = "The output folder.", allow_single_file = True, mandatory = True),
        "filter": attr.label(doc = "Optional filter file containing the definition-references of all modules to be generated, separated by newlines. If this is not provided all modules of the BSW package are generated.", allow_single_file = True),
    },
    command_builder = _generate_foundation_layer_builder,
    toolchains = [TOOLCHAIN_TYPE],
    doc = "Rule for generating the foundation layer API sources.",
)
