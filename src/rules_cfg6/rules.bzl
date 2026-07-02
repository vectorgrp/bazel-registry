load("@rules_java//java:defs.bzl", "java_binary")
load("@rules_java//java/common/rules:java_library.bzl", "JAVA_LIBRARY_ATTRS")
load("@rules_java//java/common/rules:java_binary.bzl", "BASIC_JAVA_BINARY_ATTRIBUTES")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

def default_http_archive_attrs(archive_name, *mutex_attrs):
    return {
        "url": attr.string(doc = "URL of the {} archive.{}".format(archive_name, " Mutually exclusive with `{}`.".format("`, `".join(mutex_attrs)) if mutex_attrs else ""), mandatory = len(mutex_attrs) == 0),
        "sha256": attr.string(doc = "SHA256 checksum of the {} archive.".format(archive_name)),
        "auth_patterns": attr.string_dict(doc = "Authorization patterns (see [http_archive](https://bazel.build/rules/lib/repo/http#http_archive-auth_patterns)).")
    }

def download_and_extract(repository_ctx, output, **kwargs):
    url = kwargs.get("url")
    if not url:
        url = repository_ctx.attr.url
    sha256 = kwargs.get("sha256")
    if not sha256 and hasattr(repository_ctx.attr, "sha256"):
        sha256 = repository_ctx.attr.sha256
    auth_patterns = kwargs.get("auth_patterns")
    if auth_patterns == None and hasattr(repository_ctx.attr, "auth_patterns"):
        auth_patterns = repository_ctx.attr.auth_patterns
    repository_ctx.download_and_extract(
        url = url,
        sha256 = sha256,
        auth = { url: auth_patterns } if auth_patterns else {},
        output = output
    )

def single_file_from_target(target):
    l = target[DefaultInfo].files.to_list()
    if len(l) != 1:
        fail("Expected exactly one file from {} but got {}.".format(target.label, len(l)))
    return l[0]

def get_bash(repository_ctx):
    return repository_ctx.getenv("BAZEL_SH", "bash")

Cfg6ToolProvider = provider()

ArchiveToolProvider = provider()

EvsShortNamePathProvider = provider()

ModuleImportMergeModeProvider = provider()

VariantNameProvider = provider()

ScriptTaskProvider = provider()

AsCodeTypeProvider = provider()

AsCodeArgProvider = provider()

PipelineProjectProvider = provider()

def _cfg6_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            cfg6 = Cfg6ToolProvider(
                cli = ctx.attr.cli,
                core = ctx.attr.core,
                xpro = ctx.attr.xpro,
                gui = ctx.attr.gui,
                gui_template = ctx.attr.gui_template,
                result_file_cmd = ctx.attr.result_file_cmd
            ),
            archive = ArchiveToolProvider(
                pack = ctx.attr.pack,
                unpack = ctx.attr.unpack
            )
        )
    ]

cfg6_toolchain = rule(
    implementation = _cfg6_toolchain_impl,
    attrs = {
        "cli": attr.string(mandatory = True),
        "core": attr.string(mandatory = True),
        "xpro": attr.string(mandatory = True),
        "gui": attr.string(mandatory = True),
        "gui_template": attr.string(mandatory = True),
        "result_file_cmd": attr.string(mandatory = True),
        "pack": attr.string(mandatory = True),
        "unpack": attr.string(mandatory = True)
    }
)

def _version_from_pai_jar(path):
    result = path.basename
    if (result.startswith("automation-interface-") and result.endswith(".jar")):
        result = result[len("automation-interface-"):len(result) - 4]
        if (result.find("-") == -1):
            return result

def _pai_version(repository_ctx):
    libs_folder = repository_ctx.path("_/dvcfgpai/libs")
    for path in libs_folder.readdir():
        v = _version_from_pai_jar(path)
        if (v):
            return v
    fail("Failed to read PAI version from jars in {}.".format(libs_folder))

def _cli(repository_ctx, ext):
    result = repository_ctx.path("_/dvcfg" + ext)
    return str(result if result.exists else repository_ctx.path("_/dvcfg-b" + ext))

def _gui(repository_ctx, ext, cli):
    result = repository_ctx.path("_/dvcfgui-b/dvcfgui-b" + ext)
    return str(result) if result.exists else cli

def _cfg6_repo_files(repository_ctx):
    is_windows = repository_ctx.os.name.startswith("windows")
    ext = ".exe" if is_windows else ""
    cli = _cli(repository_ctx, ext)
    gui = _gui(repository_ctx, ext, cli)
    if is_windows:
        ret = repository_ctx.execute([get_bash(repository_ctx), "-c", '"{}" -v'.format(cli)])
        if ret.return_code != 0:
            fail("\r\nERROR: Failed to call DaVinci Configurator Classic Version 6 from bash. Please use a bash capable of windows-style paths (e.g. git bash). " + ret.stderr)
    repository_ctx.template(
        "BUILD.bazel",
        Label("cfg6_BUILD_template.bzl"),
        substitutions = {
            "CLI": cli,
            "CORE": str(repository_ctx.path("_/dvcfgcore/dvcfgcore" + ext)),
            "XPRO": str(repository_ctx.path("_/ecuxpro/ecuxpro" + ext)),
            "GUI": gui,
            "TEMPLATE": ('"{dvcfg}" project start --project "{project}" --bsw-package "{bsw_pkg}"' if gui == cli else '"{dvcfg}" --project "{project}" --bsw-package "{bsw_pkg}"') + ' && read -srn 1 -p "Press any key to terminate..."',
            "RESULT_FILE_CMD": 'powershell -NoP -NonI -c \\"[guid]::NewGuid().ToString() > \\"{out}\\"\\"' if is_windows else 'bash -c \\"cat /proc/sys/kernel/random/uuid > \\"{out}\\"\\"',
            "PAI_VERSION": _pai_version(repository_ctx),
            "COMPRESS": 'tar --force-local -zcf "{}" -C "{}" .',
            "UNPACK": 'rm -rf "{folder}" && mkdir -p "{folder}" && tar --force-local -zxf "{archive}" -C "{folder}"'
        }
    )
    repository_ctx.template("defs.bzl", Label("cfg6_defs_template.bzl"))
    repository_ctx.template(
        "rules.bzl",
        Label("cfg6_rules_template.bzl"),
        substitutions = {
            "CFG6_PAI_VERSION": _pai_version(repository_ctx)
        }
    )
    return cli

def _cfg6_archive_impl(repository_ctx):
    if repository_ctx.os.name.startswith("windows"):
        download_and_extract(repository_ctx, "_download_", url = repository_ctx.attr.nupkg_url, sha256 = repository_ctx.attr.nupkg_sha256, auth_patterns = repository_ctx.attr.nupkg_auth_patterns)
        repository_ctx.extract(
            archive = "_download_/tools/archive.zip",
            output = "_"
        )
    else:
        download_and_extract(repository_ctx, "_download_")
        repository_ctx.extract(
            archive = "_download_/data.tar.zst",
            output = "_",
            strip_prefix = "opt/vector-davinci-configurator-classic/evo2/eac"
        )
    repository_ctx.delete("_download_")
    _cfg6_repo_files(repository_ctx)

cfg6_archive = repository_rule(
    doc = "Rule for using a DaVinci Configurator Classic Version 6 .nupkg or .deb archive.",
    attrs = dict({ "nupkg_" + k: v for k, v in default_http_archive_attrs(".nupkg", "url").items() }.items(), **default_http_archive_attrs(".deb", "nupkg_url")),
    implementation = _cfg6_archive_impl
)

def _absolute_path(repository_ctx, s):
    return repository_ctx.path(s) if s.startswith("/") or s.startswith("\\") or (len(s) > 2 and s[1] == ":" and (s[2] == "/" or s[2] == "\\")) else repository_ctx.path(str(repository_ctx.workspace_root) + "/" + s)

def _local_cfg6_impl(repository_ctx):
    path = _absolute_path(repository_ctx , repository_ctx.attr.path)
    repository_ctx.symlink(path, "_")
    cli = _cfg6_repo_files(repository_ctx)
    repository_ctx.watch(repository_ctx.path(cli).realpath)

local_cfg6 = repository_rule(
    doc = "Rule for using a local DaVinci Configurator Classic Version 6 installation.",
    attrs = {
        "path": attr.string(doc = "Path (absolute or relative to workspace root) of the dvcfg install folder.", mandatory = True)
    },
    implementation = _local_cfg6_impl
)

def _generate_bswmd_model_impl(ctx):
    jar = ctx.actions.declare_file("DVCfgAutomationInterfaceBswmdModel_CLASSES-1.0.0.jar")
    ctx.actions.run_shell(
        outputs = [jar],
        command = '"{core}" -application com.vector.cfg.bswmdmgen.app.application && cp "{bsw}/DaVinciConfigurator/DvC6/BswmdModel/DVCfgAutomationInterfaceBswmdModel_CLASSES-1.0.0.jar" "{jar}"'.format(
            core = ctx.toolchains[":toolchain_type"].cfg6.core,
            bsw = ctx.attr.bsw_pkg,
            jar = jar.path
        ),
        env = {
            "JAVA_OPTS": '"-Dcom.vector.cfg.gen.bswmdmodel.option.GenerateSipModel={}"'.format(ctx.attr.bsw_pkg)
        },
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([jar]))]

_BSW_PKG_ATTR = { "bsw_pkg": attr.string(doc = "The BSW package folder.", mandatory = True) }

generate_bswmd_model = rule(
    doc = "Internal rule for generating the BSWMD model API.",
    attrs = _BSW_PKG_ATTR,
    implementation = _generate_bswmd_model_impl,
    toolchains = [":toolchain_type"]
)

def _generate_foundation_layer_script_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        out,
        '"{core}" -application com.vector.cfg.bswmdmgen.app.flApplication -b "{bsw}" --force -o "$BUILD_WORKSPACE_DIRECTORY/{out}"'.format(
            core = ctx.toolchains[":toolchain_type"].cfg6.core,
            bsw = _rlocation(ctx, ctx.attr.bsw_pkg),
            out = ctx.file.output.short_path
        ),
        is_executable = True
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [ctx.file.bsw_pkg]))]

generate_foundation_layer_script = rule(
    attrs = {
        "bsw_pkg": attr.label(doc = "The BSW package folder.", allow_single_file = True, mandatory = True),
        "output": attr.label(doc = "The output folder.", allow_single_file = True, mandatory = True)
    },
    implementation = _generate_foundation_layer_script_impl,
    toolchains = [":toolchain_type"]
)

def _generate_foundation_layer_impl(name, visibility, tags, **kwargs):
    script_name = name + "_script"
    generate_foundation_layer_script(
        name = script_name,
        visibility = ["//visibility:private"],
        tags = ["no-ide"],
        **kwargs
    )
    sh_binary(
        name = name,
        srcs = [script_name],
        use_bash_launcher = True,
        visibility = visibility,
        tags = tags
    )

generate_foundation_layer = macro(
    doc = "Rule for generating the foundation layer API sources.",
    inherit_attrs = generate_foundation_layer_script,
    implementation = _generate_foundation_layer_impl
)

def _script_jar_impl(deps, pai, pai_version, script_classes, **kwargs):
    java_binary(
        deps = deps + [pai],
        main_class = "com.vector.cfg.WorkaroundForMissinFatJarTarget",
        deploy_manifest_lines = [
            "DvCfg-AutomationInterfaceJars-Compile-Version: " + pai_version,
            "Automation-Classes: " + ",".join(script_classes),
            "DvCfg-AutomationInterface-AllowBetaApiUsage: true"
        ],
        **kwargs
    )

script_jar = macro(
    doc = "Rule for setting up a PAI project.",
    attrs = dict({ k: v for k, v in JAVA_LIBRARY_ATTRS.items() if not k.startswith("_") and k in BASIC_JAVA_BINARY_ATTRIBUTES },
        pai = attr.label(doc = "PAI libs target.", mandatory = True, configurable = False),
        pai_version = attr.string(doc = "PAI version.", mandatory = True, configurable = False),
        script_classes = attr.string_list(doc = "ScriptFactory class names.", mandatory = True, allow_empty = False, configurable = False),
        deps = attr.label_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/java#java_library.deps)", configurable = False),
        tags = attr.string_list(doc = "[Inherited rule attribute](https://bazel.build/reference/be/common-definitions#common.tags)", configurable = False)
    ),
    implementation = _script_jar_impl
)

def _select_evs_impl(ctx):
    return [DefaultInfo(files = depset(ctx.files.arxmls)), EvsShortNamePathProvider(evs_path = ctx.attr.evs_path)]

select_evs = rule(
    doc = "Rule for selecting one of multiple EvaluatedVariantSets from the given .arxml files.",
    attrs = {
        "arxmls": attr.label_list(doc = "The .arxml files containing the EvaluatedVariantSet.", allow_files = [".arxml"], allow_empty = False, mandatory = True),
        "evs_path": attr.string(doc = "Short name path of the EvaluatedVariantSet.", mandatory = True)
    },
    implementation = _select_evs_impl,
)

def _cli_cmd(ctx, input_files, cmd, **kwargs):
    out = ctx.actions.declare_file(ctx.label.name)
    cfg6 = ctx.toolchains[":toolchain_type"].cfg6
    ctx.actions.run_shell(
        outputs = [out],
        inputs = [ctx.file.upstream] + input_files,
        command = ('"{cli}" ' + cmd + ' && ' + cfg6.result_file_cmd).format(
            cli = cfg6.cli,
            bsw = ctx.attr.bsw_pkg,
            dvjson = ctx.attr.dvjson,
            out = out.path,
            **kwargs
        ),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out]))]

_STD_CLI_ATTRS = dict(
    _BSW_PKG_ATTR,
    dvjson = attr.string(doc = "The .dvjson file.", mandatory = True),
    upstream = attr.label(doc = "The upstream pipeline target.", allow_single_file = True, mandatory = True)
)

def _import_evs_impl(ctx):
    snp = ""
    snp_provider_targets = [target for target in ctx.attr.evs if EvsShortNamePathProvider in target]
    if snp_provider_targets:
        snp = " '-s {}'".format(snp_provider_targets[0][EvsShortNamePathProvider].evs_path)
    arxml_files = [file for target in ctx.attr.evs for file in target[DefaultInfo].files.to_list()]
    return _cli_cmd(ctx, arxml_files, 'import evs{snp} -b "{bsw}" -p "{dvjson}" "{evs}"',
        snp = snp,
        evs = '","'.join([file.path for file in arxml_files])
    )

import_evs = rule(
    doc = "Internal rule for adding an EvaluatedVariantSet to the DaVinci project.",
    attrs = dict(_STD_CLI_ATTRS, evs = attr.label_list(doc = "The .arxml files containing the EvaluatedVariantSet.", allow_files = [".arxml"], allow_empty = False, mandatory = True)),
    implementation = _import_evs_impl,
    toolchains = [":toolchain_type"]
)

def _derive_ecuc_impl(ctx):
    return _cli_cmd(ctx, ctx.files.extract, 'project derive-ecuc -b "{bsw}" -p "{dvjson}" --force "{extract}"',
        extract = '" "'.join([extract.path for extract in ctx.files.extract])
    )

derive_ecuc = rule(
    doc = "Internal rule for adding an ECU extract to the DaVinci project.",
    attrs = dict(_STD_CLI_ATTRS, extract = attr.label_list(doc = "The .arxml files containing the ECU extract.", allow_files = [".arxml"], allow_empty = False, mandatory = True)),
    implementation = _derive_ecuc_impl,
    toolchains = [":toolchain_type"]
)

def _replace_modules_impl(ctx):
    return [DefaultInfo(files = depset(ctx.files.arxmls)), ModuleImportMergeModeProvider(replace = True)]

replace_modules = rule(
    doc = "Rule for specifying module configurations to be imported in replace mode.",
    attrs = {
        "arxmls": attr.label_list(doc = "The .arxml files containing the module configurations.", allow_files = [".arxml"], allow_empty = False, mandatory = True)
    },
    implementation = _replace_modules_impl,
)

def _import_modules_impl(ctx):
    upstream = ctx.file.upstream
    i = 0
    cfg6 = ctx.toolchains[":toolchain_type"].cfg6
    for module in ctx.attr.modules:
        replace = " -r" if ModuleImportMergeModeProvider in module else ""
        for file in module[DefaultInfo].files.to_list():
            out = ctx.actions.declare_file("{}_{}".format(ctx.label.name, i))
            i += 1
            ctx.actions.run_shell(
                outputs = [out],
                inputs = [upstream, file],
                command = ('"{cli}" import module -b "{bsw}" -p "{dvjson}"{replace} "{file}" && ' + cfg6.result_file_cmd).format(
                    cli = cfg6.cli,
                    bsw = ctx.attr.bsw_pkg,
                    dvjson = ctx.attr.dvjson,
                    replace = replace,
                    file = file.path,
                    out = out.path
                ),
                use_default_shell_env = True
            )
            upstream = out
    return [DefaultInfo(files = depset([upstream]))]

import_modules = rule(
    doc = "Rule for importing module configurations into the DaVinci project.",
    attrs = dict(_STD_CLI_ATTRS, modules = attr.label_list(doc = 'The .arxml files containing the module configurations (use [replace_modules](#replace_modules) to import in replace mode).', allow_files = [".arxml"], allow_empty = False, mandatory = True)),
    implementation = _import_modules_impl,
    toolchains = [":toolchain_type"]
)

def _variant_arxmls_impl(ctx):
    return [DefaultInfo(files = depset(ctx.files.arxmls)), VariantNameProvider(variant = ctx.attr.variant)]

variant_arxmls = rule(
    doc = 'Rule for specifying which post-build selectable variant the given .arxml files are associated with (e.g.: when [importing diagnostic modules](#import_diag_modules)).',
    attrs = {
        "variant": attr.string(doc = "The name of the variant.", mandatory = True),
        "arxmls": attr.label_list(doc = "The .arxml files.", allow_files = [".arxml"], allow_empty = False, mandatory = True)
    },
    implementation = _variant_arxmls_impl,
)

def _import_diag_modules_impl(ctx):
    variant_to_modules = {}
    for target in ctx.attr.modules:
        variant = target[VariantNameProvider].variant if VariantNameProvider in target else ""
        arxml_files = target[DefaultInfo].files.to_list()
        if variant in variant_to_modules:
            variant_to_modules[variant].extend(arxml_files)
        else:
            variant_to_modules[variant] = arxml_files
    if len(variant_to_modules) == 1:
        files = '-f "{}"'.format('","'.join([arxml.path for list in variant_to_modules.values() for arxml in list]))
    else:
        if "" in variant_to_modules:
            fail("These diagnostic modules are not assigned to a variant: " + ", ".join([arxml.owner for arxml in variant_to_modules[""]]))
        files = " ".join(['-f {}="{}"'.format(variant, '","'.join([arxml.path for arxml in arxmls])) for variant, arxmls in variant_to_modules.items()])
    return _cli_cmd(ctx, ctx.files.modules, 'import diagnostic-modules -b "{bsw}" -p "{dvjson}" --force {files}',
        files = files
    )

import_diag_modules = rule(
    doc = "Rule for importing diagnostic module configurations into the DaVinci project.",
    attrs = dict(_STD_CLI_ATTRS, modules = attr.label_list(doc = "The .arxml files containing the diagnostic module configurations.", allow_files = [".arxml"], allow_empty = False, mandatory = True)),
    implementation = _import_diag_modules_impl,
    toolchains = [":toolchain_type"]
)

def _update_project_impl(ctx):
    return _cli_cmd(ctx, [], 'project update -b "{bsw}" -p "{dvjson}"{switches}',
        switches = " -{}".format(ctx.attr.switches) if ctx.attr.switches else ""
    )

update_project = rule(
    doc = "Internal rule for updating the DaVinci project when input files have changed.",
    attrs = dict(_STD_CLI_ATTRS, switches = attr.string(doc = '''String consisting of all switches to apply when running the "project update" command (defaults to "" meaning perform all updates). E.g.: "asr" will only run "automatic reference correction", "solve all" and "RTE config update". The following switches are available:<br/>
`a`: Perform automatic correction of unresolved or inconsistent references.<br/>
`s`: Perform 'solve all' by executing all recommended solving actions of the project.<br/>
`c`: Apply changes from project input files.<br/>
`r`: Apply changes to the RTE configuration.<br/>
`e`: Apply changes from evaluated variant set.
''')),
    implementation = _update_project_impl,
    toolchains = [":toolchain_type"]
)

_PRIMITIVE_TYPE = type("")
_LIST_TYPE = type([])
_OBJECT_TYPE = type({})

def _file_string(ctx, target):
    return '"{}/{}"'.format("$(pwd -W)" if ctx.toolchains[":toolchain_type"].cfg6.cli.endswith(".exe") else "$PWD", single_file_from_target(target).path.replace("\\", "/"))

def _arg_to_string(ctx, arg):
    t = type(arg)
    if t == _PRIMITIVE_TYPE:
        return arg
    if t == _LIST_TYPE:
        return "[" + ",".join([_arg_to_string_1(ctx, e) for e in arg]) + "]"
    if t == _OBJECT_TYPE:
        return "{" + ",".join(['"{}":{}'.format(k, _arg_to_string_1(ctx, v)) for k, v in arg.items()]) + "}"
    return _file_string(ctx, arg)

def _arg_to_string_1(ctx, arg):
    t = type(arg)
    if t == _PRIMITIVE_TYPE:
        return arg
    if t == _LIST_TYPE:
        return "[" + ",".join([_arg_to_string_2(ctx, e) for e in arg]) + "]"
    if t == _OBJECT_TYPE:
        return "{" + ",".join(['"{}":{}'.format(k, _arg_to_string_2(ctx, v)) for k, v in arg.items()]) + "}"
    return _file_string(ctx, arg)

def _arg_to_string_2(ctx, arg):
    t = type(arg)
    if t == _PRIMITIVE_TYPE:
        return arg
    if t == _LIST_TYPE:
        return "[" + ",".join([_arg_to_string_3(ctx, e) for e in arg]) + "]"
    if t == _OBJECT_TYPE:
        return "{" + ",".join(['"{}":{}'.format(k, _arg_to_string_3(ctx, v)) for k, v in arg.items()]) + "}"
    return _file_string(ctx, arg)

def _arg_to_string_3(ctx, arg):
    t = type(arg)
    if t == _PRIMITIVE_TYPE:
        return arg
    if t == _LIST_TYPE:
        return "[" + ",".join([_arg_to_string_4(ctx, e) for e in arg]) + "]"
    if t == _OBJECT_TYPE:
        return "{" + ",".join(['"{}":{}'.format(k, _arg_to_string_4(ctx, v)) for k, v in arg.items()]) + "}"
    return _file_string(ctx, arg)

def _arg_to_string_4(ctx, arg):
    t = type(arg)
    if t == _PRIMITIVE_TYPE:
        return arg
    if t == _LIST_TYPE:
        return "[" + ",".join([_arg_to_string_5(ctx, e) for e in arg]) + "]"
    if t == _OBJECT_TYPE:
        return "{" + ",".join(['"{}":{}'.format(k, _arg_to_string_5(ctx, v)) for k, v in arg.items()]) + "}"
    return _file_string(ctx, arg)

def _arg_to_string_5(ctx, arg):
    t = type(arg)
    if t == _LIST_TYPE or t == _OBJECT_TYPE:
        fail("Maximum nesting level for JSON arguments is 5.")
    if t == _PRIMITIVE_TYPE:
        return arg
    return _file_string(ctx, arg)

def _jar_to_string(ctx, jar):
    path = single_file_from_target(jar).path
    arg = jar[AsCodeTypeProvider].arg
    return '{}//{}'.format(path, _arg_to_string(ctx, arg[AsCodeArgProvider].arg).replace('"', '\\"')) if arg else path

def _as_code_impl(ctx):
    arg_input_files = [file for default_info in [jar[AsCodeTypeProvider].arg[DefaultInfo] for jar in ctx.attr.jars if jar[AsCodeTypeProvider].arg] for file in default_info.files.to_list()]
    return _cli_cmd(ctx, ctx.files.jars + arg_input_files, 'eac -b "{bsw}" -p "{dvjson}" -c "{jars}"', jars = '" -c "'.join([_jar_to_string(ctx, jar) for jar in ctx.attr.jars]))

as_code = rule(
    doc = "Internal rule for adding EaC logic to the DaVinci project.",
    attrs = dict(_STD_CLI_ATTRS, jars = attr.label_list(doc = 'The EaC .jar files (see [as_code_eac](#as_code_eac)).', providers = [AsCodeTypeProvider], allow_empty = False, mandatory = True)),
    implementation = _as_code_impl,
    toolchains = [":toolchain_type"]
)

def _as_code_arg_impl(ctx):
    args = [arg for arg in [ctx.attr.value, ctx.attr.values, ctx.attr.file, ctx.attr.files, ctx.attr.list, ctx.attr.object] if arg]
    if len(args) != 1:
        fail("Exactly one argument must be provided.")
    if ctx.attr.value or ctx.attr.values:
        return [AsCodeArgProvider(arg = args[0])]
    if ctx.attr.file:
        return [DefaultInfo(files = depset([ctx.file.file])), AsCodeArgProvider(arg = ctx.attr.file)]
    if ctx.attr.files:
        return [DefaultInfo(files = depset(ctx.files.files)), AsCodeArgProvider(arg = ctx.attr.files)]
    if ctx.attr.list:
        return [DefaultInfo(files = depset(transitive = [target[DefaultInfo].files for target in ctx.attr.list])), AsCodeArgProvider(arg = [target[AsCodeArgProvider].arg for target in ctx.attr.list])]
    return [DefaultInfo(files = depset(transitive = [target[DefaultInfo].files for target in ctx.attr.object.values()])), AsCodeArgProvider(arg = { key: target[AsCodeArgProvider].arg for key, target in ctx.attr.object.items() })]

as_code_arg = rule(
    doc = "Rule for specifying arguments for the EaC code.",
    attrs = {
        "value": attr.string(doc = 'A primitive JSON value (e.g.: `true`, `false`, `123`, `"string"`, `null`). Use `"${ENV_VAR-}"` to provide environment variable values as strings.'),
        "values": attr.string_list(doc = "A list of values (see [value](#as_code_arg.value))."),
        "file": attr.label(allow_single_file = True, doc = "A file argument (available to the code as String containing the absolute file path)."),
        "files": attr.label_list(doc = "A list of files (available to the code as Strings containing the absolute file paths)."),
        "list": attr.label_list(doc = "A list of `as_code_arg` labels.", providers = [AsCodeArgProvider]),
        "object": attr.string_keyed_label_dict(doc = "An `as_code_arg`-label-valued JSON object.", providers = [AsCodeArgProvider])
    },
    implementation = _as_code_arg_impl
)

_UPSTREAM_ATTR = { "upstream": attr.label(doc = "The upstream pipeline target.", providers = [PipelineProjectProvider], allow_single_file = [".tar.gz"], mandatory = True) }

_STD_EXPORT_ATTRS = dict(
    _UPSTREAM_ATTR,
    binding_time = attr.string(doc = "Binding time to use for the export."),
    split_pre_build_variants = attr.bool(doc = "Generate separate output for each pre-build variant."),
    split_post_build_variants = attr.bool(doc = "Generate separate output for each post-build variant."),
    args = attr.string_list(doc = "Exporter-specific arguments.")
)

def _apply_bswmd_impl(ctx):
    return _cli_cmd(ctx, [], 'project apply-bswmd -b "{bsw}" -p "{dvjson}"')

apply_bswmd = rule(
    doc = "Internal rule for applying pre config, recommended config and BSWMD defaults to the ECU configuration derived from the ECU extract.",
    attrs = _STD_CLI_ATTRS,
    implementation = _apply_bswmd_impl,
    toolchains = [":toolchain_type"]
)

def _run_export_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "/export")
    ctx.actions.run_shell(
        outputs = [out],
        inputs = [ctx.file.upstream],
        command = "{unpack} && {command}".format(
            unpack = _unpack(ctx, out.dirname),
            command = _format_command(ctx, out.dirname, '"{dvcfg}" export run -b "{bsw}" -p "{dvjson}" -o "{out}" -e "{exporter}"{binding_time}{split_pre}{split_post}{args}',
                out = out.path,
                exporter = ctx.attr.exporter,
                binding_time = ' --binding-time "{}"'.format(ctx.attr.binding_time) if ctx.attr.binding_time else "",
                split_pre = " --split-pre-build-variants" if ctx.attr.split_pre_build_variants else "",
                split_post = " --split-post-build-variants" if ctx.attr.split_post_build_variants else "",
                args = (" " + " ".join(ctx.attr.args)) if ctx.attr.args else ""
            )),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out]))]

run_export = rule(
    doc = "Rule for exporting data from the DaVinci project.",
    attrs = dict(_STD_EXPORT_ATTRS, exporter = attr.string(doc = "Exporter ID. A list of all IDs is available via the `export list` command of the DaVinci Configurator Classic CLI.", mandatory = True)),
    implementation = _run_export_impl,
    toolchains = [":toolchain_type"]
)

def _export_flat_extract_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "/flat_extract")
    ctx.actions.run_shell(
        outputs = [out],
        inputs = [ctx.file.upstream],
        command = "{unpack} && {command}".format(
            unpack = _unpack(ctx, out.dirname),
            command = _format_command(ctx, out.dirname, '"{dvcfg}" export run -b "{bsw}" -p "{dvjson}" -o "{out}" -e "{exporters}"{binding_time}{split_pre}{split_post}{args}',
                out = out.path,
                exporters = '" -e "'.join(ctx.attr.exporters),
                binding_time = ' --binding-time "{}"'.format(ctx.attr.binding_time) if ctx.attr.binding_time else "",
                split_pre = " --split-pre-build-variants" if ctx.attr.split_pre_build_variants else "",
                split_post = " --split-post-build-variants" if ctx.attr.split_post_build_variants else "",
                args = (" " + " ".join(ctx.attr.args)) if ctx.attr.args else ""
            )),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out]))]

export_flat_extract = rule(
    doc = "Rule for exporting a flat ECU extract from the DaVinci project.",
    attrs = dict(_STD_EXPORT_ATTRS, exporters = attr.string_list(doc = "Exporter IDs. A list of all IDs is available via the `export list` command of the DaVinci Configurator Classic CLI.", allow_empty = False, mandatory = True)),
    implementation = _export_flat_extract_impl,
    toolchains = [":toolchain_type"]
)

def _format_command(ctx, folder, cmd, **kwargs):
    pipeline_project_provider = ctx.attr.upstream[PipelineProjectProvider]
    return cmd.format(
        dvcfg = kwargs.get("dvcfg", default = ctx.toolchains[":toolchain_type"].cfg6.cli),
        project = kwargs.get("project", default = folder + "/" + pipeline_project_provider.dvjson),
        bsw_pkg = kwargs.get("bsw_pkg", default = pipeline_project_provider.bsw_pkg),
        **kwargs
    )

def _unpack(ctx, folder):
    return ctx.toolchains[":toolchain_type"].archive.unpack.format(archive = ctx.file.upstream.path, folder = folder)

def _generate_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "/Output/Source/GenData" + ("Vtt" if ctx.attr.type == "VTT" else ""))
    folder = out.dirname
    folder = folder[:folder.rfind("/", 0, folder.rfind("/"))]
    ctx.actions.run_shell(
        outputs = [out],
        inputs = [ctx.file.upstream],
        command = "{unpack} && {command}".format(
            unpack = _unpack(ctx, folder),
            command = _format_command(ctx, folder, '"{dvcfg}" project generate -b "{bsw_pkg}" -p "{project}"{modules}{excluded}{ext}{type}{keep_tmp}{clean}{no_save}',
                modules = (" '-m=" + ",".join(ctx.attr.modules) + "'") if ctx.attr.modules else "",
                excluded = (" '-x=" + ",".join(ctx.attr.excluded) + "'") if ctx.attr.excluded else "",
                ext = (' --ext-steps "' + '","'.join(ctx.attr.ext_steps) + '"') if ctx.attr.ext_steps else "",
                type = ' -t "{}"'.format(ctx.attr.type) if ctx.attr.type else "",
                keep_tmp = " --keep-temp-files" if ctx.attr.keep_tmp_files else "",
                clean = " --clean-generate" if ctx.attr.skip_up_to_date_checks else "",
                no_save = " --no-save" if ctx.attr.no_save else ""
            )),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out]))]

generate = rule(
    doc = "Rule for generating the BSW code.",
    attrs = dict(
        _UPSTREAM_ATTR,
        modules = attr.string_list(doc = 'Modules to generate, given either by definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte"). "from-project" generates the modules selected in the project settings and can be combined with explicitly state modules. Defaults to generating all modules.'),
        excluded = attr.string_list(doc = 'Modules to exclude from generation, given either by definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte").'),
        ext_steps = attr.string_list(doc = "External generation steps to execute, given by name. Defaults to executing all steps. Use a single empty string to disable any steps."),
        type = attr.string(doc = 'Generation target ("REAL" or "VTT").', values = ["REAL", "VTT"]),
        keep_tmp_files = attr.bool(doc = "Keep temporary files created during generation."),
        skip_up_to_date_checks = attr.bool(doc = "Run validation and generation without performing up-to-date checks."),
        no_save = attr.bool(doc = "Prevent saving the project to disk.")
    ),
    implementation = _generate_impl,
    toolchains = [":toolchain_type"]
)

def _generate_swct_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "/Output/Source/Templates")
    folder = out.dirname
    folder = folder[:folder.rfind("/", 0, folder.rfind("/"))]
    ctx.actions.run_shell(
        outputs = [out],
        inputs = [ctx.file.upstream],
        command = "{unpack} && {command}".format(
            unpack = _unpack(ctx, folder),
            command = _format_command(ctx, folder, '"{dvcfg}" project generate-swct -b "{bsw_pkg}" -p "{project}"{components}{args}{keep_tmp}{no_save}',
                components = (' -c "' + '","'.join(ctx.attr.components) + '"') if ctx.attr.components else "",
                args = (' -a "' + '","'.join(ctx.attr.args) + '"') if ctx.attr.args else "",
                keep_tmp = " --keep-temp-files" if ctx.attr.keep_tmp_files else "",
                no_save = " --no-save" if ctx.attr.no_save else ""
            )),
        use_default_shell_env = True
    )

generate_swct = rule(
    doc = "Rule for generating SWC templates and contract phase headers.",
    attrs = dict(
        _UPSTREAM_ATTR,
        components = attr.string_list(doc = "Software components for which a template and/or contract phase header will be generated, given by name specified in the project settings."),
        args = attr.string_list(doc = 'Arguments for certain generators given in the form "<module>:<arg>" where <module> is a module definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte").'),
        keep_tmp_files = attr.bool(doc = "Keep temporary files created during generation."),
        no_save = attr.bool(doc = "Prevent saving the project to disk.")
    ),
    implementation = _generate_swct_impl,
    toolchains = [":toolchain_type"]
)

def _as_code_eac_impl(ctx):
    return [DefaultInfo(files = depset([ctx.file.jar])), AsCodeTypeProvider(type = "eac", arg = ctx.attr.arg)]

as_code_eac = rule(
    doc = "Rule for marking up a .jar for EaC usage.",
    attrs = {
        "jar": attr.label(doc = 'The EaC .jar file.', allow_single_file = [".jar"], mandatory = True),
        "arg": attr.label(doc = 'Optional argument (see [as_code_arg](#as_code_arg)).', providers = [AsCodeArgProvider])
    },
    implementation = _as_code_eac_impl
)

def _system_extract_impl(ctx):
    name = ctx.label.name
    out = ctx.actions.declare_file(name + ".arxml")
    sysd = ctx.files.sysd
    ctx.actions.run_shell(
        outputs = [out],
        inputs = sysd,
        command = '"{xpro}" extract-sysd -i "{sysd}" -e {ecu} "{out}"'.format(
            xpro = ctx.toolchains[":toolchain_type"].cfg6.xpro,
            sysd = '" -i "'.join([file.path for file in sysd]),
            ecu = ctx.attr.ecu if ctx.attr.ecu else name,
            out = out.path
        ),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out]))]

system_extract = rule(
    doc = "Rule for extracting a given ECU from a system description.",
    attrs = {
        "sysd": attr.label_list(doc = "The system description .arxml files from which to extract the given ECU.", allow_files = [".arxml"], allow_empty = False, mandatory = True),
        "ecu": attr.string(doc = "The ECU to extract from the given system description (defaults to rule name).")
    },
    implementation = _system_extract_impl,
    toolchains = [":toolchain_type"]
)

def _merged_extract_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    ctx.actions.run_shell(
        outputs = [out],
        inputs = ctx.files.srcs,
        command = '"{xpro}" merge -i "{input}" "{out}"'.format(
            xpro = ctx.toolchains[":toolchain_type"].cfg6.xpro,
            input = '" -i "'.join([f.path for f in ctx.files.srcs]),
            out = out.path
        ),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out]))]

merged_extract = rule(
    doc = "Rule for merging multiple .arxml files into an ECU extract.",
    attrs = {
        "srcs": attr.label_list(doc = "The .arxml files to merge into one ECU extract.", allow_files = [".arxml"], allow_empty = False, mandatory = True),
    },
    implementation = _merged_extract_impl,
    toolchains = [":toolchain_type"]
)

def _variant_extract_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    ctx.actions.run_shell(
        outputs = [out],
        inputs = ctx.files.evs + [ctx.file.config] + [target[DefaultInfo].files.to_list()[0] for target in ctx.attr.extracts.keys()],
        command = '"{xpro}" variant-merge -m "{config}" -e "{evs}" {extracts} "{out}"'.format(
            xpro = ctx.toolchains[":toolchain_type"].cfg6.xpro,
            config = ctx.file.config.path,
            evs = '","'.join([file.path for file in ctx.files.evs]),
            extracts = " ".join(['-f {}="{}"'.format(variant, extract[DefaultInfo].files.to_list()[0].path) for extract, variant in ctx.attr.extracts.items()]),
            out = out.path
        ),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset(ctx.files.evs + [out]))]

variant_extract = rule(
    doc = "Rule for creating a variant ECU extract from invariant extracts.",
    attrs = {
        "evs": attr.label_list(doc = "The .arxml files containing the EvaluatedVariantSet.", allow_files = [".arxml"], allow_empty = False, mandatory = True),
        "extracts": attr.label_keyed_string_dict(doc = 'One extract for each variant in the EvaluatedVariantSet. E.g.: { ":ExtractA": "VariantA", ... }', allow_files = [".arxml"], allow_empty = False, mandatory = True),
        "config": attr.label(doc = "The merge configuration .xml file.", allow_single_file = [".xml"], mandatory = True)
    },
    implementation = _variant_extract_impl,
    toolchains = [":toolchain_type"]
)

def _task_name(task):
    return task[ScriptTaskProvider].task_name.replace('"', '\\"')

def _task_args(ctx):
    result = ""
    for task in ctx.attr.tasks:
        task_provider = task[ScriptTaskProvider]
        args = " ".join(['\\"' + arg.replace('"', '\\\\"') + '\\"' for arg in task_provider.args])
        file_args = " ".join(['\\"{}\\" \\"{}\\"'.format(arg.replace('"', '\\\\"'), single_file_from_target(value).path) for arg, value in task_provider.file_args.items()])
        if file_args:
            args = args + " " + file_args
        if args:
            result += ' -a "{}" -a "{}"'.format(_task_name(task), args)
    return result

def _script_patched_arxml_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    scripts = {single_file_from_target(task): True for task in ctx.attr.tasks}.keys()
    file_args = [single_file_from_target(target) for task in ctx.attr.tasks for target in task[ScriptTaskProvider].file_args.values()]
    ctx.actions.run_shell(
        outputs = [out],
        inputs =  scripts + file_args + [ctx.file.input] + [ctx.file.evs] if ctx.file.evs else [],
        command = '"{xpro}" run-script -i "{input}"{evs} -l"{scripts}" -t"{tasks}"{args} "{out}"'.format(
            xpro = ctx.toolchains[":toolchain_type"].cfg6.xpro,
            input = ctx.file.input.path,
            evs =  ' -e "{}"'.format(ctx.file.evs.path) if ctx.file.evs else "",
            scripts = '","'.join({single_file_from_target(task).path: True for task in ctx.attr.tasks}.keys()),
            tasks = '","'.join([_task_name(task) for task in ctx.attr.tasks]),
            args = _task_args(ctx),
            out = out.path
        ),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out]))]

script_patched_arxml = rule(
    doc = "Rule for patching an .arxml file by applying a script task.",
    attrs = {
        "input": attr.label(doc = "The .arxml file to patch.", allow_single_file = [".arxml"], mandatory = True),
        "evs": attr.label(doc = "The .arxml file containing the EvaluatedVariantSet (required for variant input only).", allow_single_file = [".arxml"]),
        "tasks": attr.label_list(doc = 'The tasks to execute (see [script_task](#script_task)).', providers = [ScriptTaskProvider], allow_empty = False, mandatory = True)
    },
    implementation = _script_patched_arxml_impl,
    toolchains = [":toolchain_type"]
)

def _downstream_project_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".tar.gz")
    dvjson = ctx.attr.dvjson
    i = dvjson.rfind("/")
    ctx.actions.run_shell(
        outputs = [out],
        inputs =  [ctx.file.upstream],
        command = ctx.toolchains[":toolchain_type"].archive.pack.format(out.path, dvjson[:i])
    )
    return [DefaultInfo(files = depset([out])), PipelineProjectProvider(dvjson = dvjson[i + 1:], bsw_pkg = ctx.attr.bsw_pkg)]

downstream_project = rule(
    doc = "Internal rule for creating the `project` target of an ECU configuration repo.",
    attrs = _STD_CLI_ATTRS,
    implementation = _downstream_project_impl,
    toolchains = [":toolchain_type"]
)

def _archived_project_impl(ctx):
    return [DefaultInfo(files = depset([ctx.file.archive])), PipelineProjectProvider(dvjson = ctx.attr.dvjson, bsw_pkg = ctx.attr.bsw_pkg)]

archived_project = rule(
    doc = "Rule for using an archived DaVinci project.",
    attrs = dict(
        _BSW_PKG_ATTR,
        dvjson = attr.string(doc = "The name of the .dvjson file in the archive.", mandatory = True),
        archive = attr.label(doc = "The archive file.", allow_single_file = True, mandatory = True)
    ),
    implementation = _archived_project_impl,
    toolchains = [":toolchain_type"]
)

def _dvcfg_cli_step_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".tar.gz")
    folder = out.dirname + "/" + ctx.label.name
    ctx.actions.run_shell(
        outputs = [out],
        inputs =  [file for target in ctx.attr.inputs.values() for file in target[DefaultInfo].files.to_list()] + [ctx.file.upstream],
        command = "{unpack} && {command} && {pack}".format(
            unpack = _unpack(ctx, folder),
            command = _format_command(ctx, folder, ctx.attr.command, **{ key: single_file_from_target(target).path for key, target in ctx.attr.inputs.items() }),
            pack = ctx.toolchains[":toolchain_type"].archive.pack.format(out.path, folder)
        ),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out])), ctx.attr.upstream[PipelineProjectProvider]]

dvcfg_cli_step = rule(
    doc = "Internal rule for running a generic CLI command on a DaVinci project.",
    attrs = dict(
        _UPSTREAM_ATTR,
        command = attr.string(doc = "Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.command)). Use `{dvcfg}` for the DaVinci Configurator Classic CLI executable, `{project}` for the .dvjson file and `{bsw_pkg}` for the BSW package folder.", mandatory = True),
        inputs = attr.string_keyed_label_dict(doc = 'Input files (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.inputs)). Use `{key}` to access file `input["key"]` in `command`.', allow_files = True),
    ),
    implementation = _dvcfg_cli_step_impl,
    toolchains = [":toolchain_type"]
)

def _rlocation(ctx, target):
    return "$(rlocation {})".format(ctx.expand_location("$(rlocationpath {})".format(target.label), [target]))

def _dvcfg_cli_executable_script_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "/" + ctx.label.name + ".sh")
    ctx.actions.write(
        out,
        "{unpack} && {command}".format(
            unpack = ctx.toolchains[":toolchain_type"].archive.unpack.format(archive = _rlocation(ctx, ctx.attr.upstream), folder = "upstream"),
            command = _format_command(ctx, "upstream", ctx.attr.command, **{ key: _rlocation(ctx, target) for key, target in ctx.attr.inputs.items() })
        ),
        is_executable = True
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [ctx.file.upstream] + [file for target in ctx.attr.inputs.values() for file in target[DefaultInfo].files.to_list()]))]

dvcfg_cli_executable_script = rule(
    doc = "Internal rule for creating a generic executable on a DaVinci project.",
    attrs = dict(
        _UPSTREAM_ATTR,
        command = attr.string(doc = "Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.command)). Use `{dvcfg}` for the DaVinci Configurator Classic CLI executable, `{project}` for the .dvjson file and `{bsw_pkg}` for the BSW package folder.", mandatory = True),
        inputs = attr.string_keyed_label_dict(doc = 'Input files (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.inputs)). Use `{key}` to access file `input["key"]` in `command`.', allow_files = True),
    ),
    implementation = _dvcfg_cli_executable_script_impl,
    toolchains = [":toolchain_type"]
)

def _pipeline_executable_impl(name, visibility, tags, **kwargs):
    script_name = name + "_script"
    dvcfg_cli_executable_script(
        name = script_name,
        visibility = ["//visibility:private"],
        tags = ["no-ide"],
        **kwargs
    )
    sh_binary(
        name = name,
        srcs = [script_name],
        use_bash_launcher = True,
        visibility = visibility,
        tags = tags
    )

pipeline_executable = macro(
    doc = "Macro for creating a generic executable on a DaVinci project.",
    inherit_attrs = dvcfg_cli_executable_script,
    implementation = _pipeline_executable_impl
)

def _script_task_impl(ctx):
    return [
        DefaultInfo(files = depset([ctx.file.script])),
        ScriptTaskProvider(task_name = ctx.attr.task_name if ctx.attr.task_name else ctx.label.name, args = ctx.attr.args, file_args = ctx.attr.file_args)
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

def _gui_script_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    cfg6 = ctx.toolchains[":toolchain_type"].cfg6
    evo1 = ctx.attr.evo1
    template = '"{dvcfg}" --project "{project}" --bsw-package "{bsw_pkg}" && read -srn 1 -p "Press any key to terminate..."' if evo1 else cfg6.gui_template
    ctx.actions.write(
        out,
        template.format(
            dvcfg = evo1 if evo1 else cfg6.gui,
            project = ctx.attr.dvjson,
            bsw_pkg = ctx.attr.bsw_pkg
        ),
        is_executable = True
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [ctx.file.upstream]))]

gui_script = rule(
    doc = "Internal rule for generating a launcher script for DaVinci Configurator Classic Version 6 GUI tool.",
    attrs = dict(_STD_CLI_ATTRS, evo1 = attr.string(doc = "The DaVinci Configurator Classic Version 6 Evo1 GUI executable for opening the project (absolute path).")),
    implementation = _gui_script_impl,
    toolchains = [":toolchain_type"]
)

def _edit_project_impl(name, visibility, tags, **kwargs):
    script_name = name + "_script"
    gui_script(
        name = script_name,
        visibility = ["//visibility:private"],
        tags = ["no-ide"],
        **kwargs
    )
    sh_binary(
        name = name,
        srcs = [script_name],
        visibility = visibility,
        tags = tags
    )

edit_project = macro(
    doc = "Macro for editing the project of an `ecu_config` repo in DaVinci Configurator Classic Version 6 GUI tool.",
    inherit_attrs = gui_script,
    implementation = _edit_project_impl
)

def _run_script_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        out,
        ctx.attr.command.format(
            dvcfg = ctx.toolchains[":toolchain_type"].cfg6.cli,
            project = ctx.attr.dvjson,
            bsw_pkg = ctx.attr.bsw_pkg,
            **{ key: _rlocation(ctx, target) for key, target in ctx.attr.inputs.items() }
        ),
        is_executable = True
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [ctx.file.upstream] + [file for target in ctx.attr.inputs.values() for file in target[DefaultInfo].files.to_list()]))]

run_script = rule(
    doc = "Internal rule for running DaVinci Configurator Classic Version 6 on a DaVinci project.",
    attrs = dict(
        _STD_CLI_ATTRS,
        command = attr.string(doc = "Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.command)). Use `{dvcfg}` for the DaVinci Configurator Classic CLI executable, `{project}` for the .dvjson file and `{bsw_pkg}` for the BSW package folder.", mandatory = True),
        inputs = attr.string_keyed_label_dict(doc = 'Input files (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.inputs)). Use `{key}` to access file `input["key"]` in `command`.', allow_files = True),
    ),
    implementation = _run_script_impl,
    toolchains = [":toolchain_type"]
)

def _run_on_project_impl(name, visibility, tags, **kwargs):
    script_name = name + "_script"
    run_script(
        name = script_name,
        visibility = ["//visibility:private"],
        tags = ["no-ide"],
        **kwargs
    )
    sh_binary(
        name = name,
        srcs = [script_name],
        use_bash_launcher = True,
        visibility = visibility,
        tags = tags
    )

run_on_project = macro(
    doc = "Macro for running DaVinci Configurator Classic Version 6 on the project of an `ecu_config` repo.",
    inherit_attrs = run_script,
    implementation = _run_on_project_impl
)

def _validation_report_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "/validation_report.html")
    ctx.actions.run_shell(
        outputs = [out],
        inputs = [ctx.file.upstream],
        command = "{unpack} && {command}".format(
            unpack = _unpack(ctx, out.dirname),
            command = _format_command(ctx, out.dirname, '"{dvcfg}" project validate -b "{bsw_pkg}" -p "{project}" --fail-on NONE --report "{out}"', out = out.path)
        ),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out]))]

validation_report = rule(
    doc = "Rule for creating a validating report for a DaVinci project.",
    attrs = _UPSTREAM_ATTR,
    implementation = _validation_report_impl,
    toolchains = [":toolchain_type"]
)

def _view_result_script_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "/" + ctx.label.name + ".sh")
    ctx.actions.write(
        out,
        "{unpack} && {open}".format(
            unpack = ctx.toolchains[":toolchain_type"].archive.unpack.format(archive = _rlocation(ctx, ctx.attr.upstream), folder = "upstream"),
            open = _format_command(ctx, "upstream", ctx.toolchains[":toolchain_type"].cfg6.gui_template)
        ),
        is_executable = True
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [ctx.file.upstream]))]

view_result_script = rule(
    doc = "Internal rule for viewing the result of a `pipeline_step` in DaVinci Configurator Classic Version 6 GUI tool.",
    attrs = _UPSTREAM_ATTR,
    implementation = _view_result_script_impl,
    toolchains = [":toolchain_type"]
)

def _pipeline_step_impl(name, upstream, **kwargs):
    dvcfg_cli_step(
        name = name,
        upstream = upstream,
        **kwargs
    )
    script_name = name + "_view_script"
    view_result_script(
        name = script_name,
        upstream = name,
        tags = ["no-ide"]
    )
    sh_binary(
        name = name + "_view_result",
        srcs = [script_name],
        use_bash_launcher = True,
        tags = ["no-ide"]
    )

pipeline_step = macro(
    doc = "Macro for running a generic CLI command on a DaVinci project. The macro automatically adds target `<name>_view_result` for viewing the result in DaVinci Configurator Classic Version 6 GUI tool.",
    inherit_attrs = dvcfg_cli_step,
    implementation = _pipeline_step_impl
)
