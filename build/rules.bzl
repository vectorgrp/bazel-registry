load("@rules_pkg//pkg/private/zip:zip.bzl", "pkg_zip")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

_REGISTRY_RELEASE = "3.0.0"

_STARDOC_HEADER = "<!-- Generated with Stardoc: http://skydoc.bazel.build -->"

def module_build_props(version):
    name = native.package_name()
    name = name[name.rindex("/") + 1:]
    return (
        name,
        version,
        {
            _STARDOC_HEADER: """{header}

# {name} v{version}

```starlark
bazep_dep(name = "{name}", version = "{version}")
```""".format(header = _STARDOC_HEADER, name = name, version = version)
        }
    )

def _versioned_module_bazel_impl(ctx):
    target = ctx.actions.declare_file("MODULE.bazel")
    ctx.actions.expand_template(
        template = ctx.file.module_bazel,
        output = target,
        substitutions = ctx.attr.substitutions
    )
    return [DefaultInfo(files = depset([target]))]

versioned_module_bazel = rule(
    attrs = {
        "module_bazel": attr.label(allow_single_file = ["MODULE.bazel"], mandatory = True),
        "substitutions": attr.string_dict(mandatory = True)
    },
    implementation = _versioned_module_bazel_impl
)

def _append_files_impl(srcs, out, **kwargs):
    native.genrule(
        srcs = srcs,
        outs = [out],
        cmd = 'cat "$(location {})" > "$@"'.format(
            ')" "$(location '.join([str(src) for src in srcs])
        ),
        **kwargs
    )

append_files = macro(
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True, allow_empty = False, configurable = False),
        "out": attr.string(mandatory = True, configurable = False)
    },
    implementation = _append_files_impl
)

def _expand_target(ctx, target):
    return "$(rlocation {})".format(ctx.expand_location("$(rlocationpath {})".format(target.label), [target]))

def _build_module_script_impl(ctx):
    name = ctx.label.package
    name = name[name.rindex("/") + 1:]
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = out,
        is_executable = True,
        content = """
if [ ! -d "{folder}" ]; then
  mkdir -p "{folder}"; cp "{module_bazel}" "{source_json}" "{readme}" "{folder}"
fi
""".format(
            folder = "$BUILD_WORKSPACE_DIRECTORY/modules/" + name + "/" + ctx.attr.version,
            module_bazel = _expand_target(ctx, ctx.attr.module_bazel),
            source_json = _expand_target(ctx, ctx.attr.source_json),
            readme = _expand_target(ctx, ctx.attr.readme)
        )
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = [ctx.file.module_bazel, ctx.file.source_json, ctx.file.readme]))]

build_module_script = rule(
    attrs = {
        "module_bazel": attr.label(allow_single_file = ["MODULE.bazel"], mandatory = True),
        "source_json": attr.label(allow_single_file = ["source.json"], mandatory = True),
        "readme": attr.label(allow_single_file = ["README.md"], mandatory = True),
        "version": attr.string(mandatory = True)
    },
    implementation = _build_module_script_impl
)

def _build_module_impl(name, version, readme, **kwargs):
    if not native.package_name().endswith("/" + name):
        fail("The module name does not match the name of the package it is defined in.")
    zip_name = "{}-{}.zip".format(name, version)
    module_bazel_label = Label("//src/{}:MODULE.bazel".format(name))
    module_bazel_name = name + "_module_bazel"
    versioned_module_bazel(
        name = module_bazel_name,
        module_bazel = module_bazel_label,
        substitutions = { 'module(name = "' + name: 'module(name = "{}", version = "{}'.format(name, version) }
    )
    pkg_zip_name = name + "_pkg_zip"
    pkg_zip(
        name = pkg_zip_name,
        srcs = [module_bazel_label.same_package_label("srcs")],
        out = zip_name
    )
    source_json_name = name + "_source_json"
    native.genrule(
        name = source_json_name,
        srcs = [pkg_zip_name],
        outs = ["source.json"],
        cmd = 'printf \'{"url":"https://github.com/vectorgrp/bazel-regristry/releases/download/' + _REGISTRY_RELEASE + "/" + zip_name + '","integrity":"sha256-%s"}\' $$(openssl dgst -sha256 -binary "$<" | openssl base64 -A) > "$@"',
    )
    build_module_script_name = name + "_build_module"
    build_module_script(
        name = build_module_script_name,
        module_bazel = module_bazel_name,
        source_json = source_json_name,
        readme = readme,
        version = version,
        tags = ["no-ide"]
    )
    sh_binary(
        name = name + "_build",
        srcs = [build_module_script_name],
        use_bash_launcher = True,
        **kwargs
    )

build_module = macro(
    attrs = {
        "version": attr.string(mandatory = True, configurable = False),
        "readme": attr.label(allow_single_file = ["README.md"], mandatory = True)
    },
    implementation = _build_module_impl
)

def _build_all_modules_script_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = out,
        is_executable = True,
        content = "\n".join([_expand_target(ctx, t) for t in ctx.attr.modules])
    )
    return [DefaultInfo(executable = out, runfiles = ctx.runfiles(files = ctx.files.modules).merge_all([m[DefaultInfo].default_runfiles for m in ctx.attr.modules]))]

build_all_modules_script = rule(
    attrs = {
        "modules": attr.label_list()
    },
    implementation = _build_all_modules_script_impl
)
