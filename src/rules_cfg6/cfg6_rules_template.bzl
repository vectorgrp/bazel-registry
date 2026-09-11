load("@rules_cfg6//:defs.bzl",
    _script_jar = "script_jar",
    _sac = "sac",
    _extract_evs = "extract_evs",
    _arxml_patch = "arxml_patch",
    _merged_arxml = "merged_arxml"
)

def _call_with_pai_version(function, **kwargs):
    function(
        pai_version = "CFG6_PAI_VERSION",
        **kwargs
    )

script_jar = macro(
    doc = "Rule for setting up a PAI project.",
    inherit_attrs = _script_jar,
    attrs = {
        "pai_version": None
    },
    implementation = lambda **kwargs: _call_with_pai_version(_script_jar, **kwargs)
)

sac = macro(
    doc = """Macro for setting up SaC. The following targets are provided:

- `<name>_dbg`: executable bazel target for running/debugging the SaC code in the IDE.
- `<name>`: The resulting `.arxml` file produced by the code.
""",
    inherit_attrs = _sac,
    attrs = {
        "pai_version": None
    },
    implementation = lambda **kwargs: _call_with_pai_version(_sac, **kwargs)
)

extract_evs = macro(
    doc = "Macro for extracting a single EvaluatedVariantSet from an .arxml file containing multiple EvaluatedVariantSets.",
    inherit_attrs = _extract_evs,
    attrs = {
        "pai": None,
        "pai_version": None
    },
    implementation = lambda **kwargs: _call_with_pai_version(_extract_evs, pai = Label(":pai_neverlink"), **kwargs)
)

arxml_patch = macro(
    doc = "Macro for creating a task to be used in rule `script_patched_arxml`.",
    inherit_attrs = _arxml_patch,
    attrs = {
        "pai_version": None
    },
    implementation = lambda **kwargs: _call_with_pai_version(_arxml_patch, **kwargs)
)

merged_arxml = macro(
    doc = "Macro for merging .arxml files.",
    inherit_attrs = _merged_arxml,
    attrs = {
        "pai": None,
        "pai_version": None
    },
    implementation = lambda **kwargs: _call_with_pai_version(_merged_arxml, pai = Label(":pai_neverlink"), **kwargs)
)
