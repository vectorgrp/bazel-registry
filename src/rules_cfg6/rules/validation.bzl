"""Rules for validating a dvcfg6 project"""

load("//:private/project_transform.bzl", "cfg6_project_transform_rule")

def _validation_report_command_builder(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "/validation_report.html")
    args = ctx.actions.args()
    args.add("--fail-on", "NONE")
    args.add("--report", out)
    return struct(
        command = "project validate",
        args = args,
        outputs = [out],
    )

cfg6_validation_report = cfg6_project_transform_rule(
    doc = "Rule for creating a validating report for a DaVinci project.",
    command_builder = _validation_report_command_builder,
)
