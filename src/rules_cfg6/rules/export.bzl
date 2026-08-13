"""Rules for exporting extracts out of dvcfg6 project."""

load("//:private/project_transform.bzl", "cfg6_project_transform_rule")

_STD_EXPORT_ATTRS = dict(
    binding_time = attr.string(doc = "Binding time to use for the export."),
    split_pre_build_variants = attr.bool(doc = "Generate separate output for each pre-build variant."),
    split_post_build_variants = attr.bool(doc = "Generate separate output for each post-build variant."),
    args = attr.string_list(doc = "Exporter-specific arguments."),
)

def _export_command_builder(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "/export")
    args = ctx.actions.args()
    args.add("-o", out.path)
    args.add("-e", ctx.attr.exporter)
    if ctx.attr.binding_time:
        args.add("--binding-time", ctx.attr.binding_time)
    if ctx.attr.split_pre_build_variants:
        args.add("--split-pre-build-variants", ctx.attr.split_pre_build_variants)
    if ctx.attr.split_post_build_variants:
        args.add("--split-post-build-variants", ctx.attr.split_post_build_variants)
    args.add_all(ctx.attr.args)

    return struct(
        command = "export run",
        args = args,
        outputs = [out],
    )

cfg6_export = cfg6_project_transform_rule(
    doc = "Rule for exporting data from the DaVinci project.",
    attrs = dict(_STD_EXPORT_ATTRS, exporter = attr.string(doc = "Exporter ID. A list of all IDs is available via the `export list` command of the DaVinci Configurator Classic CLI.", mandatory = True)),
    command_builder = _export_command_builder,
)

def _flat_extract_export_command_builder(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "/flat_extract")
    args = ctx.actions.args()
    args.add("-o", out.path)
    for exporter in ctx.attr.exporters:
        args.add("-e", exporter)
    if ctx.attr.binding_time:
        args.add("--binding-time", ctx.attr.binding_time)
    if ctx.attr.split_pre_build_variants:
        args.add("--split-pre-build-variants", ctx.attr.split_pre_build_variants)
    if ctx.attr.split_post_build_variants:
        args.add("--split-post-build-variants", ctx.attr.split_post_build_variants)
    args.add_all(ctx.attr.args)

    return struct(
        command = "export run",
        args = args,
        outputs = [out],
    )

cfg6_flat_extract_export = cfg6_project_transform_rule(
    doc = "Rule for exporting a flat ECU extract from the DaVinci project.",
    attrs = dict(_STD_EXPORT_ATTRS, exporters = attr.string_list(doc = "Exporter IDs. A list of all IDs is available via the `export list` command of the DaVinci Configurator Classic CLI.", allow_empty = False, mandatory = True)),
    command_builder = _flat_extract_export_command_builder,
)

def _system_extract_impl(ctx):
    name = ctx.label.name
    out = ctx.actions.declare_file(name + ".arxml")
    sysd = ctx.files.sysd
    args = ctx.actions.args().add("extract-sysd")
    for file in sysd:
        args.add("-i", file)
    args.add("-e", ctx.attr.ecu if ctx.attr.ecu else name)
    args.add(out)
    ctx.actions.run(
        executable = ctx.toolchains[TOOLCHAIN_TYPE].cfg6.xpro,
        arguments = args,
        inputs = sysd,
        outputs = [out],
        toolchains = [TOOLCHAIN_TYPE],
    )
    return [DefaultInfo(files = depset([out]))]

cfg6_system_extract = rule(
    doc = "Rule for extracting a given ECU from a system description.",
    attrs = {
        "sysd": attr.label_list(doc = "The system description .arxml files from which to extract the given ECU.", allow_files = [".arxml"], allow_empty = False, mandatory = True),
        "ecu": attr.string(doc = "The ECU to extract from the given system description (defaults to rule name)."),
    },
    implementation = _system_extract_impl,
    toolchains = [TOOLCHAIN_TYPE],
)

def _merged_extract_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    args = ctx.actions.args().add("merge")
    for file in ctx.files.src:
        args.add("-i", file)
    args.add(out)
    ctx.actions.run(
        executable = ctx.toolchains[TOOLCHAIN_TYPE].cfg6.xpro,
        arguments = args,
        inputs = ctx.files.src,
        outputs = [out],
        toolchains = [TOOLCHAIN_TYPE],
    )
    return [DefaultInfo(files = depset([out]))]

cfg6_merged_extract = rule(
    doc = "Rule for merging multiple .arxml files into an ECU extract.",
    attrs = {
        "srcs": attr.label_list(doc = "The .arxml files to merge into one ECU extract.", allow_files = [".arxml"], allow_empty = False, mandatory = True),
    },
    implementation = _merged_extract_impl,
    toolchains = [TOOLCHAIN_TYPE],
)

def _variant_extract_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    args = ctx.actions.args()
    args.add("variant-merge")
    args.add("-m", ctx.file.config)
    args.add_joined("-e", ctx.files.evs, join_with = ",")
    extract_files = []
    for extract, variant in ctx.attr.extracts.items():
        extract_file = single_file_from_target(extract)
        extract_files.append(extract_file)
        args.add("-f", "{}={}".format(variant, extract_file.path))

    ctx.actions.run(
        executable = ctx.toolchains[TOOLCHAIN_TYPE].cfg6.xpro,
        arguments = args,
        inputs = ctx.files.evs + [ctx.file.config] + extract_files,
        outputs = [out],
    )
    return [DefaultInfo(files = depset(ctx.files.evs + [out]))]

cfg6_variant_extract = rule(
    doc = "Rule for creating a variant ECU extract from invariant extracts.",
    attrs = {
        "evs": attr.label_list(doc = "The .arxml files containing the EvaluatedVariantSet.", allow_files = [".arxml"], allow_empty = False, mandatory = True),
        "extracts": attr.label_keyed_string_dict(doc = 'One extract for each variant in the EvaluatedVariantSet. E.g.: { ":ExtractA": "VariantA", ... }', allow_files = [".arxml"], allow_empty = False, mandatory = True),
        "config": attr.label(doc = "The merge configuration .xml file.", allow_single_file = [".xml"], mandatory = True),
    },
    implementation = _variant_extract_impl,
    toolchains = [TOOLCHAIN_TYPE],
)
