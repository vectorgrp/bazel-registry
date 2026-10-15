load("@rules_java//java/common:java_common.bzl", "java_common")
load("@rules_java//java/common:java_info.bzl", "JavaInfo")
load("@rules_kotlin//kotlin/internal:defs.bzl", "KtJvmInfo", _KT_TOOLCHAIN_TYPE = "TOOLCHAIN_TYPE")
load("@rules_kotlin//kotlin/internal:opts.bzl", "KotlincOptions", "kotlinc_options_to_flags")

_JAVA_TOOLCHAIN_TYPE = "@bazel_tools//tools/jdk:toolchain_type"

def _compiler_jar(kotlin_home):
    for f in kotlin_home.files.to_list():
        if f.basename == "kotlin-compiler.jar" and f.dirname.endswith("/lib"):
            return f
    fail("kotlin_home holds no lib/kotlin-compiler.jar.")

def _kotlinc_flags(kt, kotlinc_opts):
    """The kotlinc options flags, plus the toolchain's version flags the options do not set."""
    options = kotlinc_opts[KotlincOptions] if kotlinc_opts else kt.kotlinc_options
    option_flags = kotlinc_options_to_flags(options) if options else []
    toolchain_flags = [("-{}=".format(f.replace("_", "-")), getattr(kt, f)) for f in ["jvm_target", "api_version", "language_version"]]
    return option_flags + [k + v for k, v in toolchain_flags if not [f for f in option_flags if f.startswith(k)]]

def _kt_jvm_info(ctx, kt, module_name, output_jar, source_jar, java_info):
    # Field for field as kt_jvm_library fills it (rules_kotlin kotlin/internal/jvm/compile.bzl),
    # so IDE sync sees a Kotlin target with its module name, language version and options.
    return KtJvmInfo(
        srcs = ctx.files.srcs,
        module_name = module_name,
        module_jars = [],
        language_version = kt.api_version,
        exported_compiler_plugins = depset(),
        outputs = struct(
            jdeps = None,
            jars = [struct(
                class_jar = output_jar,
                ijar = output_jar,
                source_jars = [source_jar],
            )],
        ),
        transitive_compile_time_jars = java_info.transitive_compile_time_jars,
        transitive_source_jars = java_info.transitive_source_jars,
        annotation_processing = None,
        additional_generated_source_jars = [],
        all_output_jars = [output_jar],
    )

def _kt_jar_library_impl(ctx):
    if not ctx.files.srcs:
        fail("kt_jar_library {} has no sources.".format(ctx.label))

    kt = ctx.toolchains[_KT_TOOLCHAIN_TYPE]
    java_runtime = ctx.attr._java_runtime[java_common.JavaRuntimeInfo]
    compiler_jar = _compiler_jar(kt.kotlin_home)
    module_name = ctx.attr.module_name or ctx.label.name

    deps = [d[JavaInfo] for d in ctx.attr.deps] + [kt.jvm_stdlibs]
    classpath = depset(transitive = [d.transitive_compile_time_jars for d in deps])

    output_jar = ctx.actions.declare_file(ctx.label.name + ".jar")

    args = ctx.actions.args()
    args.set_param_file_format("multiline")
    args.use_param_file("@%s", use_always = True)

    # A .jar destination makes kotlinc write the classes into the archive directly.
    args.add("-d", output_jar)
    args.add("-module-name", module_name)
    args.add("-no-stdlib")
    args.add("-no-reflect")
    args.add_joined("-classpath", classpath, join_with = ctx.configuration.host_path_separator)
    args.add_all(_kotlinc_flags(kt, ctx.attr.kotlinc_opts))
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        executable = java_runtime.java_executable_exec_path,
        arguments = [
            # kotlinc stamps every jar entry with 1980-01-01 00:00 in the JVM's local time zone.
            # UTC keeps the jar bytes identical across machines.
            "-Duser.timezone=UTC",
            "-cp",
            compiler_jar.path,
            "org.jetbrains.kotlin.cli.jvm.K2JVMCompiler",
            args,
        ],
        inputs = depset(ctx.files.srcs, transitive = [classpath, kt.kotlin_home.files, java_runtime.files]),
        outputs = [output_jar],
        mnemonic = "KotlinCompileToJar",
        progress_message = "Compiling Kotlin straight to jar %{{label}} ({} files)".format(len(ctx.files.srcs)),
        toolchain = _KT_TOOLCHAIN_TYPE,
    )

    source_jar = java_common.pack_sources(
        ctx.actions,
        output_source_jar = ctx.actions.declare_file(ctx.label.name + "-sources.jar"),
        sources = ctx.files.srcs,
        java_toolchain = ctx.toolchains[_JAVA_TOOLCHAIN_TYPE].java,
    )

    java_info = JavaInfo(
        output_jar = output_jar,
        compile_jar = output_jar,
        source_jar = source_jar,
        deps = deps,
    )

    return [
        java_info,
        _kt_jvm_info(ctx, kt, module_name, output_jar, source_jar, java_info),
        DefaultInfo(files = depset([output_jar])),
    ]

kt_jar_library = rule(
    doc = """Kotlin JVM library compiled straight to jar.

Generated foundation layer file names may exceed the 255-character limit of NTFS and ext4.
This rule runs the compiler with `-d <out>.jar`, which makes it write every class straight
into the archive.

The produced jar must never be extracted.""",
    attrs = {
        "srcs": attr.label_list(doc = "Kotlin sources, compiled as one compilation unit.", allow_files = [".kt"]),
        "deps": attr.label_list(doc = "Compile and runtime dependencies.", providers = [JavaInfo]),
        "kotlinc_opts": attr.label(doc = "`kt_kotlinc_options` target. Defaults to the options of the Kotlin toolchain.", providers = [KotlincOptions]),
        "module_name": attr.string(doc = "Kotlin module name (the `META-INF/<name>.kotlin_module` entry). Defaults to the target name."),
        "_java_runtime": attr.label(default = "@bazel_tools//tools/jdk:current_host_java_runtime", cfg = "exec", providers = [java_common.JavaRuntimeInfo]),
    },
    implementation = _kt_jar_library_impl,
    toolchains = [_KT_TOOLCHAIN_TYPE, _JAVA_TOOLCHAIN_TYPE],
    provides = [JavaInfo, KtJvmInfo],
)
