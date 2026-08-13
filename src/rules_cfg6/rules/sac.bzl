load("@rules_java//java:defs.bzl", "java_binary")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

_dbg_script_postfix = "_dbg_script"

def _script_jar_impl(pai_version, script_classes, **kwargs):
    java_binary(
        main_class = "com.vector.cfg.WorkaroundForMissinFatJarTarget",
        deploy_manifest_lines = [
            "DvCfg-AutomationInterfaceJars-Compile-Version: " + pai_version,
            "Automation-Classes: " + ",".join(script_classes),
            "DvCfg-AutomationInterface-AllowBetaApiUsage: true",
        ],
        **kwargs
    )

script_jar = macro(
    doc = "Internal macro for setting up a PAI project.",
    attrs = dict(
        {k: v for k, v in JAVA_LIBRARY_ATTRS.items() if not k.startswith("_") and k in BASIC_JAVA_BINARY_ATTRIBUTES},
        pai_version = attr.string(mandatory = True, configurable = False),
        script_classes = attr.string_list(doc = "ScriptFactory class names.", mandatory = True, allow_empty = False, configurable = False),
        tags = attr.string_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/common-definitions#common.tags)", configurable = False),
    ),
    implementation = _script_jar_impl,
)

def _sac_dbg_script_impl(ctx):
    command = '''
if [[ "${{EAC_DEBUG-}}" == "true" ]]; then
    export DVCFG_JVM_ARGS='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n -Djdk.attach.allowAttachSelf=true'
    export IDE_INTEGRATION_PORT="${{EAC_IDE_PORT-}}"
fi

_term() {{
    kill "$child" 2>/dev/null
}}
trap _term SIGINT

"{xpro}" run-script -i "{input}" ''' + ('-e "{evs}" ' if ctx.attr.evs else "") + '''-l "{jar}" -t "{task}" "$BUILD_WORKSPACE_DIRECTORY/{pkg}/{name}.arxml" &

child=$!
wait "$child"
'''
    return _write_script(
        ctx,
        command,
        {
            "input": ctx.attr.input,
            "evs": ctx.attr.evs,
            "jar": ctx.attr.task,
        },
        xpro = ctx.toolchains[TOOLCHAIN_TYPE].cfg6.xpro,
        task = ctx.attr.task[ScriptTaskInfo].task_name,
        pkg = ctx.label.package,
        name = ctx.label.name[:-len(_dbg_script_postfix)],
    )

_sac_dbg_script = rule(
    attrs = {
        "input": attr.label(doc = "The .arxml file to patch.", allow_single_file = [".arxml"], default = Label("empty.arxml")),
        "evs": attr.label_list(doc = "The .arxml files containing the EvaluatedVariantSet (required for variant input only).", allow_files = [".arxml"]),
        "task": attr.label_list(doc = "The task to execute (see [script_task](#script_task)).", providers = [ScriptTaskInfo], allow_empty = False, mandatory = True),
    },
    implementation = _sac_dbg_script_impl,
    toolchains = [TOOLCHAIN_TYPE],
)

def _sac_impl(name, code, script_classes, task_name, pai_version, evs, input, **kwargs):
    script_jar_name = name + "_script_jar"
    script_jar(
        name = script_jar_name,
        script_classes = script_classes,
        runtime_deps = code,
        pai_version = pai_version,
        tags = ["manual"],
    )
    script_task_name = name + "_script_task"
    script_task(
        name = script_task_name,
        script = script_jar_name + "_deploy.jar",
        task_name = task_name,
    )
    script_patched_arxml(
        name = name,
        tasks = [script_task_name],
        **kwargs
    )
    dbg_script_name = name + _dbg_script_postfix
    _sac_dbg_script(
        name = dbg_script_name,
        task = script_task_name,
        input = input,
        evs = evs,
    )
    sh_binary(
        name = name + "_dbg",
        srcs = [dbg_script_name],
        use_bash_launcher = True,
    )

cfg6_sac = macro(
    doc = "Internal macro for setting up SaC.",
    inherit_attrs = script_patched_arxml,
    attrs = dict(
        _SAC_ATTRS,
        tasks = None,
        code = JAVA_LIBRARY_ATTRS["runtime_deps"],
        script_classes = attr.string_list(default = ["SaC"], configurable = False),
    ),
    implementation = _sac_impl,
)
