"""Rules for importing configurations into a dvcfg6 project."""

load("//:private/project_provider.bzl", "Cfg6ProjectInfo")
load("//:private/project_transform.bzl", "cfg6_project_transform_rule")

VariantNameInfo = provider("Variant Name", fields = ["variant"])
EvsShortNamePathInfo = provider("Evs ShortNamePath", fields = ["evs_path"])

def _project_import_impl(ctx):
    project_files = depset(ctx.files.project_srcs)
    return [
        DefaultInfo(files = project_files),
        Cfg6ProjectInfo(bsw_pkg_files = depset(ctx.files.bsw_pkg_srcs), project_files = project_files),
    ]

cfg6_project_import = rule(
    doc = "Rule for using an archived DaVinci project.",
    attrs = {
        "bsw_pkg_srcs": attr.label_list(doc = "The BSW package folder.", mandatory = True, allow_files = True),
        "project_srcs": attr.label_list(doc = "The name of the .dvjson file in the archive.", mandatory = True, allow_files = True),
    },
    implementation = _project_import_impl,
)

def _module_import_command_builder(ctx):
    args = ctx.actions().args()
    if ctx.attr.replace:
        args.add("-r")
    args.add_all(ctx.files.module)
    return struct(
        command = "import module",
        args = args,
        inputs = ctx.files.module,
    )

cfg6_module_import = cfg6_project_transform_rule(
    doc = "Rule for importing module configurations into the DaVinci project.",
    attrs = {
        "module": attr.label(doc = "The .arxml files containing the module configurations).", allow_files = [".arxml"], mandatory = True),
        "replace": attr.bool(doc = "todo", default = False),
    },
    command_builder = _module_import_command_builder,
)

def _diag_modules_import_command_builder(ctx):
    args = ctx.actions.args().add("--force")
    variant_to_modules = {}
    for target in ctx.attr.modules:
        variant = target[VariantNameInfo].variant if VariantNameInfo in target else ""
        arxml_files = target[DefaultInfo].files.to_list()
        if variant in variant_to_modules:
            variant_to_modules[variant].extend(arxml_files)
        else:
            variant_to_modules[variant] = arxml_files

    if len(variant_to_modules) == 1:
        args.add_joined("-f", [arxml for arxml in arxmls for arxmls in variant_to_modules.values()], join_with = ",")
    else:
        if "" in variant_to_modules:
            fail("These diagnostic modules are not assigned to a variant: " + ", ".join([arxml.owner for arxml in variant_to_modules[""]]))
        for variant, arxmls in variant_to_modules.items():
            args.add("-f", "{}={}".format(variant, ",".join([arxml.path for arxml in arxmls])))
    return struct(
        command = "import diagnostic-modules",
        args = args,
        inputs = ctx.files.modules,
    )

cfg6_diag_modules_import = cfg6_project_transform_rule(
    doc = "Rule for importing diagnostic module configurations into the DaVinci project.",
    attrs = {"modules": attr.label_list(doc = "The .arxml files containing the diagnostic module configurations.", allow_files = [".arxml"], allow_empty = False, mandatory = True)},
    command_builder = _diag_modules_import_command_builder,
)

def _variant_arxmls_impl(ctx):
    return [DefaultInfo(files = depset(ctx.files.arxmls)), VariantNameInfo(variant = ctx.attr.variant)]

variant_arxmls = rule(
    doc = "Rule for specifying which post-build selectable variant the given .arxml files are associated with (e.g.: when [importing diagnostic modules](#import_diag_modules)).",
    attrs = {
        "variant": attr.string(doc = "The name of the variant.", mandatory = True),
        "arxmls": attr.label_list(doc = "The .arxml files.", allow_files = [".arxml"], allow_empty = False, mandatory = True),
    },
    implementation = _variant_arxmls_impl,
)

def _select_evs_impl(ctx):
    return [DefaultInfo(files = depset(ctx.files.arxmls)), EvsShortNamePathInfo(evs_path = ctx.attr.evs_path)]

select_evs = rule(
    doc = "Rule for selecting one of multiple EvaluatedVariantSets from the given .arxml files.",
    attrs = {
        "arxmls": attr.label_list(doc = "The .arxml files containing the EvaluatedVariantSet.", allow_files = [".arxml"], allow_empty = False, mandatory = True),
        "evs_path": attr.string(doc = "Short name path of the EvaluatedVariantSet.", mandatory = True),
    },
    implementation = _select_evs_impl,
)

def _evs_import_command_builder(ctx):
    args = ctx.actions.args()
    snp_provider_targets = [target for target in ctx.attr.evs if EvsShortNamePathInfo in target]
    if snp_provider_targets:
        args.add("-s", snp_provider_targets[0][EvsShortNamePathInfo].evs_path)
    args.add_all(ctx.files.evs)
    return struct(
        command = "import evs",
        args = args,
        inputs = ctx.files.evs,
    )

cfg6_evs_import = cfg6_project_transform_rule(
    doc = "Internal rule for adding an EvaluatedVariantSet to the DaVinci project.",
    attrs = {"evs": attr.label_list(doc = "The .arxml files containing the EvaluatedVariantSet.", allow_files = [".arxml"], allow_empty = False, mandatory = True)},
    command_builder = _evs_import_command_builder,
)

def _ecuc_derive_command_builder(ctx):
    return struct(
        command = "project derive-ecuc",
        args = ctx.actions.args().add("--force").add_all(ctx.files.extract),
        inputs = ctx.files.extract,
    )

cfg6_ecuc_derive = cfg6_project_transform_rule(
    doc = "Internal rule for adding an ECU extract to the DaVinci project.",
    attrs = {
        "extract": attr.label_list(doc = "The .arxml files containing the ECU extract.", allow_files = [".arxml"], allow_empty = False, mandatory = True),
    },
    command_builder = _ecuc_derive_command_builder,
)

def _bswmd_apply_impl(_ctx):
    return struct(command = "project apply-bswmd")

cfg6_bswmd_apply = cfg6_project_transform_rule(
    doc = "Internal rule for applying pre config, recommended config and BSWMD defaults to the ECU configuration derived from the ECU extract.",
    command_builder = _bswmd_apply_impl,
)

def _project_update_command_builder(ctx):
    args = ctx.actions.args()
    if ctx.attr.switches:
        args.add("-" + ctx.attr.switches)
    return struct(
        command = "project update",
        args = args,
    )

cfg6_project_update = cfg6_project_transform_rule(
    doc = "Internal rule for updating the DaVinci project when input files have changed.",
    attrs = {"switches": attr.string(doc = '''String consisting of all switches to apply when running the "project update" command (defaults to "" meaning perform all updates). E.g.: "asr" will only run "automatic reference correction", "solve all" and "RTE config update". The following switches are available:<br/>
`a`: Perform automatic correction of unresolved or inconsistent references.<br/>
`s`: Perform 'solve all' by executing all recommended solving actions of the project.<br/>
`c`: Apply changes from project input files.<br/>
`r`: Apply changes to the RTE configuration.<br/>
`e`: Apply changes from evaluated variant set.
''')},
    command_builder = _project_update_command_builder,
)
