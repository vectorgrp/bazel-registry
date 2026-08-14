"""Rules for generating a DaVinci Configurator Classic 6 project to embedded sources."""

load("//private:project_generation.bzl", "cfg6_generation_rule")

def _bsw_generation_command_builder(ctx):
    args = ctx.actions.args()
    args.add_joined("-x", ctx.attr.excluded, join_with = ",")
    args.add("-t", ctx.attr.target)

    return struct(
        command = "project generate",
        args = args,
    )

cfg6_generation = cfg6_generation_rule(
    doc = "Rule for generating embedded source files via DaVinci Configurator Classic 6.",
    command_builder = _bsw_generation_command_builder,
    attrs = {
        "excluded": attr.string_list(default = [], doc = "Excluded components."),
        "target": attr.string(default = "REAL", values = ["REAL", "VTT"]),
    },
)

def _swct_generation_command_builder(ctx):
    args = ctx.actions.args()
    args.add_joined("-c", ctx.attr.components, join_with = ",")
    args.add_joined("-a", ctx.attr.args, join_with = ",")
    return struct(
        command = "project generate-swct",
        args = args,
    )

cfg6_swct_generation = cfg6_generation_rule(
    doc = "Rule for generating SWC templates and contract phase headers.",
    attrs = {
        "components": attr.string_list(doc = "Software components for which a template and/or contract phase header will be generated, given by name specified in the project settings."),
        "args": attr.string_list(doc = 'Arguments for certain generators given in the form "<module>:<arg>" where <module> is a module definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte").'),
        "keep_tmp_files": attr.bool(doc = "Keep temporary files created during generation."),
    },
    command_builder = _swct_generation_command_builder,
)
