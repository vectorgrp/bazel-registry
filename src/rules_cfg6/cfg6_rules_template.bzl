load("@rules_cfg6//:defs.bzl",
    _script_jar = "script_jar",
    _app_design = "app_design",
    _extract_evs = "extract_evs",
    _arxml_patch = "arxml_patch",
    _merged_arxml = "merged_arxml"
)

script_jar = macro(
    doc = "Rule for setting up a PAI project.",
    inherit_attrs = _script_jar,
    attrs = {
        "pai_version": None
    },
    implementation = lambda **kwargs: _script_jar(pai_version = "CFG6_PAI_VERSION", **kwargs)
)

app_design = macro(
    doc = """Macro for setting up an AppDesign project. The following targets are provided:

- `<name>_dbg`: executable bazel target for running/debugging the AppDesign code in the IDE.
- `<name>`: The resulting `.arxml` file produced by the code.
""",
    inherit_attrs = _app_design,
    attrs = {
        "pai_version": None
    },
    implementation = lambda **kwargs: _app_design(pai_version = "CFG6_PAI_VERSION", **kwargs)
)

extract_evs = macro(
    doc = "Macro for extracting a single EvaluatedVariantSet from an .arxml file containing multiple EvaluatedVariantSets.",
    inherit_attrs = _extract_evs,
    attrs = {
        "pai": None,
        "pai_version": None
    },
    implementation = lambda **kwargs: _extract_evs(pai_version = "CFG6_PAI_VERSION", pai = Label(":pai_neverlink"), **kwargs)
)

arxml_patch = macro(
    doc = "Macro for creating a task to be used in rule `script_patched_arxml`.",
    inherit_attrs = _arxml_patch,
    attrs = {
        "pai_version": None
    },
    implementation = lambda **kwargs: _arxml_patch(pai_version = "CFG6_PAI_VERSION", **kwargs)
)

merged_arxml = macro(
    doc = "Macro for merging .arxml files.",
    inherit_attrs = _merged_arxml,
    attrs = {
        "pai": None,
        "pai_version": None
    },
    implementation = lambda **kwargs: _merged_arxml(pai_version = "CFG6_PAI_VERSION", pai = Label(":pai_neverlink"), **kwargs)
)
