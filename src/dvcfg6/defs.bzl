load("@cfg6//:defs.bzl", _pai_version = "pai_version")
load("@dvcfg6_bridge_gui//:defs.bzl", _evo1_gui = "evo1_gui")

"""
The PAI version of DaVinci Configurator Classic Version 6.
"""
pai_version = _pai_version

"""
The Evo1 GUI executable of the @dvcfg6_bridge_gui archive, re-exported for the `evo1` attribute of edit_project.
"""
evo1_gui = _evo1_gui
