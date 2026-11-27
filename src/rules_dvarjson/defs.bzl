"""
Bazel ruleset for working with [DaVinci AUTOSAR JSON](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/tools/davinci-autosar-json/index.html).
"""

load(":rules.bzl",
    _dvarjson_archive = "dvarjson_archive",
    _local_dvarjson = "local_dvarjson",
    _dvarjson_toolchain = "dvarjson_toolchain",
    _evs = "evs",
    _ddm = "ddm",
    _ddm_json = "ddm_json"
)

dvarjson_archive = _dvarjson_archive
local_dvarjson = _local_dvarjson
dvarjson_toolchain = _dvarjson_toolchain
evs = _evs
ddm = _ddm
ddm_json = _ddm_json
