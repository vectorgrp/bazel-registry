load("@rules_cfg6//:defs.bzl", _script_jar = "script_jar")

def _script_jar_impl(**kwargs):
    _script_jar(
        pai = Label(":pai"),
        pai_version = "CFG6_PAI_VERSION",
        **kwargs
    )

script_jar = macro(
    doc = "Rule for setting up a PAI project.",
    inherit_attrs = _script_jar,
    attrs = {
        "pai": None,
        "pai_version": None
    },
    implementation = _script_jar_impl
)
