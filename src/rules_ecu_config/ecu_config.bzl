load(":defs.bzl", "ecu_config_repo")
load(":rules.bzl", _ECU_CONFIG_ATTRS = "ECU_CONFIG_ATTRS")

ECU_CONFIG_ATTRS = dict(_ECU_CONFIG_ATTRS, name = attr.string(doc = "The name of the resulting repo.", mandatory = True))

def create_ecu_config_repos(module_ctx, get_cfg6_defs):
    for mod in module_ctx.modules:
        for proj in mod.tags.project:
            ecu_config_repo(
                name = proj.name,
                cfg6_defs = get_cfg6_defs(proj),
                bsw_pkg = proj.bsw_pkg,
                dvjson = proj.dvjson,
                creation_file = proj.creation_file,
                settings_patch_template = proj.settings_patch_template,
                settings_patch_substitutions = proj.settings_patch_substitutions,
                project_archive = proj.project_archive,
                project_archive_dvjson = proj.project_archive_dvjson,
                project_archive_type = proj.project_archive_type,
                evs = proj.evs,
                extract = proj.extract,
                modules = proj.modules,
                diag_modules = proj.diag_modules,
                update_switches = proj.update_switches,
                as_code = proj.as_code
            )

def _ecu_config_impl(module_ctx):
    create_ecu_config_repos(module_ctx, lambda proj: proj.cfg6_defs)

ecu_config = module_extension(
    doc = "Module extension for using DaVinci projects in the Bazel pipeline.",
    implementation = _ecu_config_impl,
    tag_classes = {
        "project": tag_class(
            doc = """Creates a DaVinci project repo for configuring an ECU and generating the BSW code.

Import the repo with `use_repo(ecu_config, "MyProject")`.""",
            attrs = ECU_CONFIG_ATTRS
        )
    }
)
