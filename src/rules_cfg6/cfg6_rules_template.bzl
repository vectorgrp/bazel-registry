load("@rules_cfg6//:defs.bzl", _sac = "sac", _script_jar = "script_jar")

def _call_with_pai_version(function, **kwargs):
    function(
        pai_version = "CFG6_PAI_VERSION",
        **kwargs
    )

script_jar = macro(
    doc = "Rule for setting up a PAI project.",
    inherit_attrs = _script_jar,
    attrs = {
        "pai_version": None,
    },
    implementation = lambda **kwargs: _call_with_pai_version(_script_jar, **kwargs),
)

sac = macro(
    doc = """Macro for setting up SaC. The following targets are provided:

- `<name>_dbg`: executable bazel target for running/debugging the SaC code in the IDE.
- `<name>`: The resulting `.arxml` file produced by the code.
""",
    inherit_attrs = _sac,
    attrs = {
        "pai_version": None,
    },
    implementation = lambda **kwargs: _call_with_pai_version(_sac, **kwargs),
)
