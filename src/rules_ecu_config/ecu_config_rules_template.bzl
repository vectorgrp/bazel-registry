load("@rules_cfg6//:defs.bzl", "as_code_eac", _edit_project = "edit_project", _generate_foundation_layer = "generate_foundation_layer", _run_on_project = "run_on_project")
load("@rules_ecu_config//:defs.bzl", "dbg_as_code_script")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("CFG6_DEFS", "script_jar")

as_code_jars = AS_CODE_JARS

_PROJECT_NAME = (lambda name : "@" + name[name.rfind("+") + 1:])(str(Label("project"))[1:])

def _dbg_target(name, jars):
    script_name = name + "_dbg_script"
    dbg_as_code_script(
        name = script_name,
        tags = ["no-ide"],
        jars = jars,
        bsw_pkg = "BSW",
        dvjson = "DVJSON",
        upstream = [Label("as_code_upstream"), Label("spawn_dev_cfg6")]
    )
    sh_binary(
        name = name + "_dbg",
        tags = ["application"],
        srcs = [native.package_relative_label(script_name)],
        use_bash_launcher = True,
        visibility = ["//visibility:public"]
    )

def _eac_jar_impl(name, plugins, arg, **kwargs):
    jar_name = name + "_jar"
    script_jar(
        name = jar_name,
        plugins = plugins + ["CFG6_EAC_AP"],
        script_classes = ["com.vector.eac.EaC"],
        **kwargs
    )
    as_code_eac(
        name = name,
        jar = native.package_relative_label(jar_name + "_deploy.jar"),
        arg = arg,
        visibility = ["//visibility:public"]
    )
    canonical_name = str(native.package_relative_label(name))
    jars = []
    for jar in as_code_jars:
        jars.append(jar)
        if jar == canonical_name:
            _dbg_target(name, jars)
            return
    # the jar is not for production but a utility jar so we generate a standalone debub target
    _dbg_target(name, [canonical_name])

eac_jar = macro(
    doc = """Macro for setting up the follwing EaC targets for `{}` (`<name>` = name provided to the macro):

- `<name>` for use in [as_code](#ecu_config.project-as_code).
- `<name>_jar` for building the actual .jar file.
- `<name>_dbg` for running/debugging the EaC logic in the IDE.
""".format(_PROJECT_NAME),
    inherit_attrs = script_jar,
    attrs = {
        "script_classes": None,
        "plugins": attr.label_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/java#java_library.plugins)", configurable = False),
        "deps": attr.label_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/java#java_library.deps)", configurable = False),
        "tags": attr.string_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/common-definitions#common.tags)", configurable = False),
        "arg": attr.label(doc = '''Optional argument. Use rule `load("@rules_cfg6//:defs.bazl", "as_code_arg")` to define the argument.

For deserializing the argument a dependency to Gson is required. `@dvcfg6//:gson` can be used for this.''')
    },
    implementation = _eac_jar_impl
)

def _edit_project_impl(**kwargs):
    _edit_project(
        bsw_pkg = "BSW",
        dvjson = "DVJSON",
        upstream = Label("GUI_PROJECT"),
        **kwargs
    )

edit_project = macro(
    doc = "Macro for editing `{}` in DaVinci Configurator Classic Version 6 GUI tool.".format(_PROJECT_NAME),
    inherit_attrs = _edit_project,
    attrs = {
        "bsw_pkg": None,
        "dvjson": None,
        "upstream": None
    },
    implementation = _edit_project_impl
)

def _run_on_project_impl(**kwargs):
    _run_on_project(
        bsw_pkg = "BSW",
        dvjson = "DVJSON",
        upstream = Label("GUI_PROJECT"),
        **kwargs
    )

run_on_project = macro(
    doc = "Macro for running DaVinci Configurator Classic Version 6 on `{}`.".format(_PROJECT_NAME),
    inherit_attrs = _run_on_project,
    attrs = {
        "bsw_pkg": None,
        "dvjson": None,
        "upstream": None
    },
    implementation = _run_on_project_impl
)

def _generate_foundation_layer_impl(bsw_pkg = None, **kwargs):
    _generate_foundation_layer(
        bsw_pkg = bsw_pkg if bsw_pkg else "FOUNDATION_LAYER_PKG",
        **kwargs
    )

generate_foundation_layer = macro(
    doc = "Macro for generating the foundation layer API sources for `{}`.".format(_PROJECT_NAME),
    inherit_attrs = _generate_foundation_layer,
    attrs = {
        "bsw_pkg": attr.label(doc = "The BSW package folder (defaults to the ECU's BSW package).", allow_single_file = True),
    },
    implementation = _generate_foundation_layer_impl
)

