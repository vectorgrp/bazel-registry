"""
Bazel dependency to use and download a dedicated [DaVinci Configurator Classic](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/index.html) version.
"""

load("@rules_ecu_config//:ecu_config.bzl", "ECU_CONFIG_ATTRS", "create_ecu_config_repos")

def _ecu_config_impl(module_ctx):
    create_ecu_config_repos(module_ctx, lambda _: "@cfg6//:defs.bzl")

ecu_config = module_extension(
    doc = "Module extension for using DaVinci projects in the Bazel pipeline.",
    implementation = _ecu_config_impl,
    tag_classes = {
        "project": tag_class(
            doc = """Creates a DaVinci project repo for configuring an ECU and generating the BSW code.

Import the repo with `use_repo(ecu_config, "MyProject")`.""",
            attrs = { k: v for k, v in ECU_CONFIG_ATTRS.items() if k != "cfg6_defs" }
        )
    }
)
