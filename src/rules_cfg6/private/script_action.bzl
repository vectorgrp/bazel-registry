"""Macro / Rule builder for running scripts in workspace."""

load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

def make_script_action(command_builder, **kwargs):
    def _impl(ctx):
        command = command_builder(ctx)
        out = ctx.actions.declare_file(ctx.label.name + ".sh")
        ctx.actions.write(
            out,
            command.script,
            is_executable = True,
        )
        return [DefaultInfo(
            executable = out,
            runfiles = ctx.runfiles(files = command.inputs),
        )]

    _command_script = rule(implementation = _impl, **kwargs)

    def _macro_impl(name, visibility, **macro_kwargs):
        _command_script(
            name = "{}_script".format(name),
            visibility = ["//visibility:private"],
            tags = ["no-ide"],
            **macro_kwargs
        )

        sh_binary(
            name = name,
            srcs = [":{}_script".format(name)],
            use_bash_launcher = True,
            visibility = visibility,
        )

    return _command_script, macro(
        attrs = kwargs["attrs"],
        implementation = _macro_impl,
    )
