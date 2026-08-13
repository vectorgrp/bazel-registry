"""Rules for applying EaC jars on a dvcfg6 project."""

load("//:private/project_transform.bzl", "cfg6_project_transform_rule")

AsCodeTypeInfo = provider("Instance of EaC jar with arguments", fields = ["type", "jar", "arg"])

AsCodeArgInfo = provider("Argument for EaC jar with file references", fields = ["arg", "files"])

def _eac_argument_impl(ctx):
    args = [arg for arg in [ctx.attr.value, ctx.attr.values, ctx.attr.file, ctx.attr.files, ctx.attr.list, ctx.attr.object] if arg]
    if len(args) != 1:
        fail("Exactly one attribute must be provided.")
    if ctx.attr.value or ctx.attr.values:
        return [AsCodeArgInfo(arg = args[0], files = depset([]))]
    if ctx.attr.file:
        return [AsCodeArgInfo(arg = ctx.attr.file.path, files = depset([ctx.attr.file]))]
    if ctx.attr.files:
        return [AsCodeArgInfo(arg = [f.path for f in ctx.attr.files], files = depset(ctx.attr.files))]
    if ctx.attr.list:
        return [AsCodeArgInfo(
            arg = [target[AsCodeArgInfo].arg for target in ctx.attr.list],
            files = depset(transitive = [target[AsCodeArgInfo].files for target in ctx.attr.list]),
        )]
    return [AsCodeArgInfo(
        arg = {key: target[AsCodeArgInfo].arg for key, target in ctx.attr.object.items()},
        files = depset(transitive = [target[DefaultInfo].files for target in ctx.attr.object.values()]),
    )]

cfg6_eac_argument = rule(
    doc = "Rule for specifying arguments for the EaC code.",
    attrs = {
        "value": attr.string(doc = 'A primitive JSON value (e.g.: `true`, `false`, `123`, `"string"`, `null`).'),
        "values": attr.string_list(doc = "A list of values (see [value](#as_code_arg.value))."),
        "file": attr.label(allow_single_file = True, doc = "A file argument (available to the code as String containing the absolute file path)."),
        "files": attr.label_list(allow_files = True, doc = "A list of files (available to the code as Strings containing the absolute file paths)."),
        "list": attr.label_list(doc = "A list of `as_code_arg` labels.", providers = [AsCodeArgInfo]),
        "object": attr.string_keyed_label_dict(doc = "An `as_code_arg`-label-valued JSON object.", providers = [AsCodeArgInfo]),
    },
    implementation = _eac_argument_impl,
)

def _eac_component_impl(ctx):
    return [
        DefaultInfo(files = depset([ctx.file.jar])),
        AsCodeTypeInfo(
            type = "eac",
            jar = ctx.file.jar,
            arg = ctx.attr.arg[AsCodeArgInfo] if ctx.attr.arg else None,
        ),
    ]

cfg6_eac_component = rule(
    doc = "Rule for marking up a .jar for EaC usage.",
    attrs = {
        "jar": attr.label(doc = "The EaC .jar file.", allow_single_file = [".jar"], mandatory = True),
        "arg": attr.label(doc = "Optional argument (see [as_code_arg](#as_code_arg)).", providers = [AsCodeArgInfo]),
    },
    implementation = _eac_component_impl,
)

def _eac_apply_command_builder(ctx):
    inputs = []
    inputs_transitive = []
    args = ctx.actions.args()
    for jar in ctx.attr.jars:
        as_code_type_info = jar[AsCodeTypeInfo]
        inputs.append(as_code_type_info.jar)

        jar_arg = as_code_type_info.jar.path
        if as_code_type_info.arg:
            inputs_transitive.append(as_code_type_info.arg.files)
            jar_arg += "//" + json.encode(as_code_type_info.arg.arg)
        args.add("-c", jar_arg)

    return struct(
        command = "eac",
        args = args,
        inputs = depset(inputs, transitive = inputs_transitive),
    )

cfg6_eac_apply = cfg6_project_transform_rule(
    doc = "Internal rule for adding EaC logic to the DaVinci project.",
    attrs = {"jars": attr.label_list(doc = "The EaC .jar files (see [as_code_eac](#as_code_eac)).", providers = [AsCodeTypeInfo], allow_empty = False, mandatory = True)},
    command_builder = _eac_apply_command_builder,
)
