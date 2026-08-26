"""Rules for adding manual dvcfg6 project transformation steps."""

load("//private:project_transform.bzl", "cfg6_project_transform_rule")
load(":actions.bzl", "cfg6_view_project")

def _pipeline_step_command_builder(ctx):
    args = [ctx.expand_location(arg, ctx.attr.inputs) for arg in ctx.attr.args]
    return struct(
        command = ctx.attr.command,
        args = args,
        inputs = ctx.files.inputs,
    )

_pipeline_step = cfg6_project_transform_rule(
    doc = "Internal rule for running a generic CLI command on a DaVinci project.",
    attrs = dict(
        command = attr.string(doc = "Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.command)).", mandatory = True),
        args = attr.string_list(),
        inputs = attr.label_list(doc = "Input files (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.inputs)).", allow_files = True),
    ),
    command_builder = _pipeline_step_command_builder,
)

def _pipeline_step_impl(name, upstream, **kwargs):
    _pipeline_step(
        name = name,
        upstream = upstream,
        **kwargs
    )
    cfg6_view_project(
        name = name + "_view_result",
        upstream = ":" + name,
    )

cfg6_pipeline_step = macro(
    doc = "Macro for running a generic CLI command on a DaVinci project. The macro automatically adds target `<name>_view_result` for viewing the result in DaVinci Configurator Classic Version 6 GUI tool.",
    inherit_attrs = _pipeline_step,
    implementation = _pipeline_step_impl,
)
