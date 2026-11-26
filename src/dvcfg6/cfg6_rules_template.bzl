load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rules_java//java:defs.bzl", "java_library")
load("@rules_java//java:java_single_jar.bzl", "java_single_jar")
load("@rules_java//java/common/rules:java_library.bzl", "JAVA_LIBRARY_ATTRS")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@dvcfg6//:cfg6.bzl", "ScriptTaskProvider", "script", "export_env", "run_shell", "runfiles")

def _script_jar_impl(name, script_classes, allow_beta, tags, visibility, **kwargs):
    lib_name = name + "_lib"
    java_library(
        name = lib_name,
        **kwargs
    )
    java_single_jar(
        name = name,
        deps = [lib_name],
        deploy_manifest_lines = [
            "DvCfg-AutomationInterfaceJars-Compile-Version: CFG6_PAI_VERSION",
            "Automation-Classes: " + ",".join(script_classes),
            "DvCfg-AutomationInterface-AllowBetaApiUsage: " + ("true" if allow_beta else "false")
        ],
        tags = tags,
        visibility = visibility
    )

script_jar = macro(
    doc = "Internal macro for setting up a PAI project.",
    attrs = dict({ k: v for k, v in JAVA_LIBRARY_ATTRS.items() if not k.startswith("_") },
        script_classes = attr.string_list(doc = "ScriptFactory class names.", mandatory = True, allow_empty = False, configurable = False),
        tags = attr.string_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/common-definitions#common-attributes)", configurable = False),
        allow_beta = attr.bool(doc = "Whether to allow usage of beta PAI APIs.", configurable = False)
    ),
    implementation = _script_jar_impl
)

_ENV_FLAG_ATTR = { "_env_flag": attr.label(default = "@dvcfg6//:env", providers = [BuildSettingInfo]) }
_DBG_SCRIPT_NAME_POSTFIX = "_dbg_script"
_SCRIPT_PATCHED_ARXML_ATTRS = {
    "srcs": attr.label_list(doc = "The .arxml files to be patched.", allow_files = [".arxml"], default = [Label("empty.arxml")]),
    "tasks": attr.label_list(doc = 'The tasks to execute (see [script_task](#script_task)).', providers = [ScriptTaskProvider], allow_empty = False, mandatory = True)
}
_APP_DESIGN_ATTRS = dict(
    _SCRIPT_PATCHED_ARXML_ATTRS,
    task_name = attr.string(default = "AppDesign")
)
_TOOLCHAIN = Label("@dvcfg6//:toolchain_type")
_CFG6_TOOLCHAIN = [_TOOLCHAIN]

def _app_design_dbg_script_impl(ctx):
    args_dict, args = _task_args(ctx)
    dict = args_dict | { "xpro": ctx.toolchains[_TOOLCHAIN].cfg6.xpro, "input| -e ": ctx.attr.srcs, "-l": ctx.attr.tasks, "task": ctx.attr.task_name, "pkg": ctx.label.package, "name": ctx.label.name[:-len(_DBG_SCRIPT_NAME_POSTFIX)] }
    s = script(ctx, ctx.label.name + ".sh", export_env(ctx) + "{xpro} run-script -i {input} {-l} -t '{task}'" + args + ' "$BUILD_WORKSPACE_DIRECTORY/{pkg}/{name}.arxml"', False, dict)
    return [DefaultInfo(executable = s, runfiles = runfiles(ctx, dict))]

app_design_dbg_script = rule(
    attrs = _APP_DESIGN_ATTRS | _ENV_FLAG_ATTR,
    implementation = _app_design_dbg_script_impl,
    toolchains = _CFG6_TOOLCHAIN
)

def _script_patched_arxml_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    args_dict, args = _task_args(ctx)
    dict = args_dict | {
        "xpro": ctx.toolchains[_TOOLCHAIN].cfg6.xpro,
        "src": ctx.files.srcs[0].path,
        "evs":  " -e '{}'".format("','".join([file.path for file in ctx.files.srcs[1:]])) if len(ctx.files.srcs) > 1 else "",
        "scripts|,": ctx.attr.tasks,
        "tasks": "','".join([_task_name(task) for task in ctx.attr.tasks]),
        "out": out.path,
        "_": ctx.attr.srcs
    }
    return [run_shell(ctx, out, "{xpro} run-script -i '{src}'{evs} -l '{scripts}' -t '{tasks}'" + args + " '{out}'", dict, { "DVCFG_EXCLUSIVE_LABEL": str(ctx.label) })]

script_patched_arxml = rule(
    doc = "Rule for patching .arxml file content by applying a script task.",
    attrs = _SCRIPT_PATCHED_ARXML_ATTRS | _ENV_FLAG_ATTR,
    implementation = _script_patched_arxml_impl,
    toolchains = _CFG6_TOOLCHAIN
)

def _script_task_impl(ctx):
    return [
        DefaultInfo(files = depset([ctx.file.script])),
        ScriptTaskProvider(task_name = ctx.attr.task_name or ctx.label.name, args = ctx.attr.args, file_args = ctx.attr.file_args)
    ]

script_task = rule(
    doc = "Rule for selecting a script task from a script and optionally provide command line arguments for the task.",
    attrs = {
        "script": attr.label(doc = 'Location of the script (".dv.groovy" file, ".jar" file or folder).', allow_single_file = True, mandatory = True),
        "task_name": attr.string(doc = "The task name (defaults to rule name)."),
        "args": attr.string_list(doc = "Optional arguments for the script task."),
        "file_args": attr.string_keyed_label_dict(doc = "Optional file arguments for the script task (keys are arg names).", allow_files = True)
    },
    implementation = _script_task_impl
)

def _app_design_impl(name, code, script_classes, task_name, file_args, allow_beta, **kwargs):
    script_jar_name = name + "_script_jar"
    script_jar(
        name = script_jar_name,
        script_classes = script_classes,
        runtime_deps = code,
        allow_beta = allow_beta
    )
    script_task_name = name + "_script_task"
    script_task(
        name = script_task_name,
        script = script_jar_name,
        task_name = task_name,
        file_args = file_args
    )
    tasks = [script_task_name]
    script_patched_arxml(
        name = name,
        tasks = tasks,
        **kwargs
    )
    dbg_script_name = name + _DBG_SCRIPT_NAME_POSTFIX
    app_design_dbg_script(
        name = dbg_script_name,
        tasks = tasks,
        task_name = task_name,
        srcs = kwargs["srcs"],
        tags = ["no-ide"]
    )
    sh_binary(
        name = name + "_dbg",
        srcs = [dbg_script_name],
        use_bash_launcher = True,
        tags = ["dvcfg-dev"]
    )

app_design = macro(
    doc = "Internal macro for setting up an AppDesign project.",
    inherit_attrs = script_patched_arxml,
    attrs = dict(_APP_DESIGN_ATTRS,
        tasks = None,
        code = JAVA_LIBRARY_ATTRS["runtime_deps"],
        script_classes = attr.string_list(default = ["AppDesign"], configurable = False),
        file_args = attr.string_keyed_label_dict(doc = "Optional file arguments (keys are arg names).", allow_files = True),
        allow_beta = attr.bool(doc = "Whether to allow usage of beta PAI APIs.", configurable = False)
    ),
    implementation = _app_design_impl
)

def _arxml_patcher_src_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".java")
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = out,
        substitutions = {
            "ArxmlPatcher": ctx.label.name,
            "// CALL": ctx.attr.call
        }
    )
    return [DefaultInfo(files = depset([out]))]

_CALL_ATTR = attr.string(doc = "The task call. Must be self-contained (i.e. not requiring any imports). E.g.: call a zero-argument public static void method using a fully qualified class name.", mandatory = True)

arxml_patcher_src = rule(
    doc = "Internal rule for creating a .java file defining a task to be used in `script_patched_arxml`.",
    attrs = {
        "call": _CALL_ATTR,
        "_template": attr.label(default = Label("ArxmlPatcher.java"), allow_single_file = True)
    },
    implementation = _arxml_patcher_src_impl
)

def _arxml_patch_impl(name, srcs, call, visibility, **kwargs):
    arxml_patcher_src_name = name + "_arxml_patcher_src"
    arxml_patcher_src(
        name = arxml_patcher_src_name,
        call = call
    )
    script_jar_name = name + "_script_jar"
    script_jar(
        name = script_jar_name,
        script_classes = [arxml_patcher_src_name],
        srcs = srcs + [arxml_patcher_src_name],
        **kwargs
    )
    script_task(
        name = name,
        script = script_jar_name,
        task_name = "patch",
        visibility = visibility
    )

def _task_name(task):
    return task[ScriptTaskProvider].task_name.replace('"', '\\"')

def _task_args(ctx):
    dict = {}
    cmd = ""
    for task in ctx.attr.tasks:
        task_provider = task[ScriptTaskProvider]
        args = " ".join(['\\"' + arg.replace('"', '\\\\"') + '\\"' for arg in task_provider.args])
        dict = dict | { k + '|\\" \\"--{}='.format(k): v for k, v in task_provider.file_args.items() }
        for k in task_provider.file_args.keys():
            args = args + (" " if args else "") + '\\"--{k}={{{k}}}\\"'.format(k = k)
        if args:
            cmd += ' -a "{}" -a "{}"'.format(_task_name(task), args)
    return dict, cmd

arxml_patch = macro(
    doc = "Macro for creating a task to be used in rule `script_patched_arxml`.",
    inherit_attrs = script_jar,
    attrs = {
        "script_classes": None,
        "srcs": attr.label_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/java#java_library)", configurable = False),
        "call": _CALL_ATTR
    },
    implementation = _arxml_patch_impl
)

_PAI_NEVERLINK = [Label(":pai_neverlink")]

def _extract_evs_impl(name, short_name_path, **kwargs):
    arxml_patch_name = name + "_arxml_patch"
    arxml_patch(
        name = arxml_patch_name,
        srcs = [Label("EvsExtractor.java")],
        call = 'EvsExtractor.run("{}")'.format(short_name_path),
        deps = _PAI_NEVERLINK,
    )
    script_patched_arxml(
        name = name,
        tasks = [arxml_patch_name],
        **kwargs
    )

_PATCHER_MACRO_ATTRS = { "srcs": _SCRIPT_PATCHED_ARXML_ATTRS["srcs"] }

extract_evs = macro(
    doc = "Internal macro for extracting a single EvaluatedVariantSet from an .arxml file containing multiple EvaluatedVariantSets.",
    attrs = dict(_PATCHER_MACRO_ATTRS, short_name_path = attr.string(doc = "The short name path of the EvaluatedVariantSet to extract.", mandatory = True, configurable = False)),
    implementation = _extract_evs_impl
)

def _merged_arxml_impl(name, **kwargs):
    arxml_patch_name = name + "_no_patch"
    arxml_patch(
        name = arxml_patch_name,
        call = "// JUST MERGE - NO PATCH",
        deps = _PAI_NEVERLINK,
    )
    script_patched_arxml(
        name = name,
        tasks = [arxml_patch_name],
        **kwargs
    )

merged_arxml = macro(
    doc = "Internal macro for merging .arxml files.",
    attrs = _PATCHER_MACRO_ATTRS,
    implementation = _merged_arxml_impl
)

def _eac_jar_impl(name, plugins, **kwargs):
    script_jar(
        name = name,
        plugins = plugins + [Label(":eac_annotation_processor")],
        script_classes = ["com.vector.eac.EaC"],
        **kwargs
    )

eac_jar = macro(
    doc = "Macro for setting up an EaC .jar",
    inherit_attrs = script_jar,
    attrs = {
        "script_classes": None,
        "plugins": attr.label_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/java#java_library)", configurable = False),
    },
    implementation = _eac_jar_impl
)
