"""
Bazel ruleset for working with [DaVinci AUTOSAR JSON](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/tools/davinci-autosar-json/index.html).
"""

load(":rules.bzl",
    _evs = "evs",
    _ddm = "ddm",
    _ddm_json = "ddm_json"
)

evs = _evs
ddm = _ddm
ddm_json = _ddm_json
