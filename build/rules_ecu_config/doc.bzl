"""
Bazel ruleset for configuring ECU projects.
"""

load("//src/rules_ecu_config:ecu_config.bzl",
    _ecu_config = "ecu_config"
)

ecu_config = _ecu_config
