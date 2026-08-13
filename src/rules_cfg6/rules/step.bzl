"""Rules for adding manual dvcfg6 project transformation steps."""

load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("//:private/project_provider.bzl", "Cfg6ProjectInfo", "UPSTREAM_ATTR", "get_bsw_pkg_root_short_path", "get_project_root_short_path")
load("//:private/project_transform.bzl", "cfg6_project_transform_rule")
load("//toolchain:defs.bzl", "TOOLCHAIN_TYPE")

def _cli_step_command_builder(ctx):
    args = [ctx.expand_location(arg, ctx.attr.inputs) for arg in ctx.attr.args]
    return struct(
        command = ctx.attr.command,
        args = args,
        inputs = ctx.files.inputs,
    )

_cli_step = cfg6_project_transform_rule(
    doc = "Internal rule for running a generic CLI command on a DaVinci project.",
    attrs = dict(
        command = attr.string(doc = "Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.command)).", mandatory = True),
        args = attr.string_list(),
        inputs = attr.label_list(doc = "Input files (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.inputs)).", allow_files = True),
    ),
    command_builder = _cli_step_command_builder,
)

def _view_result_script_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "/" + ctx.label.name + ".sh")
    run_files = []
    project_info = ctx.attr.upstream[Cfg6ProjectInfo]
    project_root_short_path = get_project_root_short_path(project_info)
    run_files.extend(project_info.project_files.to_list())
    bsw_pkg_root_short_path = get_bsw_pkg_root_short_path(project_info)
    run_files.extend(project_info.bsw_pkg_files.to_list())

    toolchain = ctx.toolchains[TOOLCHAIN_TYPE].cfg6
    if toolchain.files:
        run_files.extend(toolchain.files.to_list())

    if toolchain.gui_exe:
        script = getattr(toolchain.gui_exe, "short_path", toolchain.gui_exe)
    else:
        script = "{} project start ".format(getattr(toolchain.cli_exe, "short_path", toolchain.cli_exe))
    script += " -p {} -b {} && read -srn 1 -p \"Press any key to terminate...\"".format(project_root_short_path, bsw_pkg_root_short_path)

    ctx.actions.write(
        out,
        script,
        is_executable = True,
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = run_files))]

view_result_script = rule(
    doc = "Internal rule for viewing the result of a `pipeline_step` in DaVinci Configurator Classic Version 6 GUI tool.",
    attrs = UPSTREAM_ATTR,
    implementation = _view_result_script_impl,
    toolchains = [TOOLCHAIN_TYPE],
)

def _pipeline_step_impl(name, upstream, **kwargs):
    _cli_step(
        name = name,
        upstream = upstream,
        **kwargs
    )
    script_name = name + "_view_script"
    view_result_script(
        name = script_name,
        upstream = name,
        tags = ["no-ide"],
    )
    sh_binary(
        name = name + "_view_result",
        srcs = [script_name],
        use_bash_launcher = True,
        tags = ["no-ide"],
    )

pipeline_step = macro(
    doc = "Macro for running a generic CLI command on a DaVinci project. The macro automatically adds target `<name>_view_result` for viewing the result in DaVinci Configurator Classic Version 6 GUI tool.",
    inherit_attrs = _cli_step,
    implementation = _pipeline_step_impl,
)
