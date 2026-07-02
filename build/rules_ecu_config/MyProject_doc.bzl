"""
# DaVinci Project Repo

The following targets and rules are available from a DaVinci project repo:

- Use `bazel run @MyProject//:edit_project` to edit the project in DaVinci Configurator Classic Version 6.
"""

load("@MyProject//:defs.bzl",
    _eac_jar = "eac_jar",
    _edit_project = "edit_project",
    _run_on_project = "run_on_project"
)

eac_jar = _eac_jar
edit_project = _edit_project
run_on_project = _run_on_project
