load("@rules_cfg6//:defs.bzl",
    "as_code_eac",
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

def _eac_jar_impl(name, plugins, arg, **kwargs):
    jar_name = name + "_jar"
    script_jar(
        name = jar_name,
        plugins = plugins + [Label(":eac_annotation_processor")],
        script_classes = ["com.vector.eac.EaC"],
        **kwargs
    )
    as_code_eac(
        name = name,
        jar = native.package_relative_label(jar_name),
        arg = arg,
        visibility = ["//visibility:public"]
    )

eac_jar = macro(
    doc = """Macro for setting up an EaC project providing the following targets:

- `<name>` to apply it to a project.
- `<name>_jar` to build the .jar file.
- `<name>_dbg` to run/debug the code in the IDE.""",
    inherit_attrs = script_jar,
    attrs = {
        "script_classes": None,
        "plugins": attr.label_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/java#java_library)", configurable = False),
        "arg": attr.label(doc = 'Optional argument. Use rule `load("@rules_cfg6//:defs.bazl", "as_code_arg")` to define the argument.')
    },
    implementation = _eac_jar_impl
)
