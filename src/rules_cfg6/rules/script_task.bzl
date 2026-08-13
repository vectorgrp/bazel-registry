"""Rules for defining and executing script tasks on arxml files."""
ScriptTaskInfo = provider("Parametrized script task", fields = ["script", "name", "args", "file_args"])

def _script_task_impl(ctx):
    return [
        DefaultInfo(files = depset([ctx.file.script])),
        ScriptTaskInfo(
            script = ctx.file.script,
            name = ctx.attr.task_name if ctx.attr.task_name else ctx.label.name,
            args = ctx.attr.args,
            file_args = ctx.attr.file_args,
        ),
    ]

cfg6_script_task = rule(
    doc = "Rule for selecting a script task from a script and optionally provide command line arguments for the task.",
    attrs = {
        "script": attr.label(doc = 'Location of the script (".dv.groovy" file, ".jar" file or folder).', allow_single_file = True, mandatory = True),
        "task_name": attr.string(doc = "The task name (defaults to rule name)."),
        "args": attr.string_list(doc = "Optional arguments for the script task."),
        "file_args": attr.string_keyed_label_dict(doc = "Optional file arguments for the script task (keys are arg names).", allow_files = True),
    },
    implementation = _script_task_impl,
)

def _script_patched_arxml_impl(ctx):
    toolchain = ctx.toolchains[TOOLCHAIN_TYPE].cfg6
    inputs = [ctx.file.input]
    if toolchain.files:
        inputs.extend(toolchain.files)
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")

    task_infos = [task[ScriptTaskInfo] for task in ctx.attr.tasks]
    scripts = {task.script: True for task in task_infos}.keys()
    inputs.extend(scripts)

    args = ctx.actions.args().add("run-script")
    args.add("-i", ctx.file.input)

    args.add_all("-e", ctx.files.evs)
    inputs.extend(ctx.files.evs)

    args.add_joined("-l", scripts, join_with = ",")
    args.add("-t", [task.name for task in task_infos], join_with = ",")
    for task_info in task_infos:
        args.add("-a", task_info.task_name)
        all_task_info_args = []
        all_task_into_args.extend(task_info.args)
        for arg, value in task_info.file_args.items():
            all_task_info_args.append(arg)
            value_file = single_file_from_target(value)
            inputs.append(value_file)
            all_task_info_args.append(value_file.path)
        args.add("-a", " ".join([json.encode(arg) for arg in all_task_info_args]))

    args.add(out.path)

    ctx.actions.run(
        executable = toolchain.xpro_exe,
        arguments = args,
        inputs = depset(inputs),
        outputs = [out],
        toolchains = [TOOLCHAIN_TYPE],
    )
    return [DefaultInfo(files = depset([out]))]

cfg6_script_patched_arxml = rule(
    doc = "Rule for patching an .arxml file by applying a script task.",
    attrs = {
        "input": attr.label(doc = "The .arxml file to patch.", allow_single_file = [".arxml"], default = Label("//:empty.arxml")),
        "evs": attr.label_list(doc = "The .arxml files containing the EvaluatedVariantSet (required for variant input only).", allow_files = [".arxml"]),
        "tasks": attr.label_list(doc = "The tasks to execute (see [script_task](#script_task)).", providers = [ScriptTaskInfo], allow_empty = False, mandatory = True),
    },
    implementation = _script_patched_arxml_impl,
    toolchains = [TOOLCHAIN_TYPE],
)
