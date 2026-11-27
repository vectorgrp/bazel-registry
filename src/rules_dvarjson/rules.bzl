load("@rules_cfg6//:rules.bzl", "default_http_archive_attrs", "download_and_extract")

DvarjsonToolProvider = provider()

def _dvarjson_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            dvarjson = DvarjsonToolProvider(
                cli = ctx.attr.cli
            )
        )
    ]

dvarjson_toolchain = rule(
    implementation = _dvarjson_toolchain_impl,
    attrs = {
        "cli": attr.string(mandatory = True)
    }
)

def _dvarjson_repo_files(repository_ctx):
    repository_ctx.template(
        "BUILD.bazel",
        Label(":dvarjson_BUILD_template.bzl"),
        substitutions = {
            "CLI": str(repository_ctx.path("_/dvarjson{}".format(".bat" if repository_ctx.os.name.startswith("windows") else ""))),
        }
    )

def _dvarjson_archive_impl(repository_ctx):
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
            strip_prefix = "opt/vector/dvarjson"
        )
    repository_ctx.delete("_download_")
    _dvarjson_repo_files(repository_ctx)

dvarjson_archive = repository_rule(
    doc = "Rule for using a dvarjson .nupkg or .deb archive.",
    attrs = dict({ "nupkg_" + k: v for k, v in default_http_archive_attrs(".nupkg", "url").items() }.items(), **default_http_archive_attrs(".deb", "nupkg_url")),
    implementation = _dvarjson_archive_impl
)

def _local_dvarjson_impl(repository_ctx):
    repository_ctx.symlink(repository_ctx.attr.path, "_")
    repository_ctx.watch(repository_ctx.attr.path)
    _dvarjson_repo_files(repository_ctx)

local_dvarjson = repository_rule(
    doc = "Rule for using a local dvarjson installation.",
    attrs = {
        "path": attr.string(doc = "Path of the dvarjson install folder.", mandatory = True)
    },
    implementation = _local_dvarjson_impl
)

def _dvarjson_convert(ctx, type):
    out = ctx.actions.declare_file(ctx.label.name + ".arxml")
    ctx.actions.run_shell(
        outputs = [out],
        inputs = [ctx.file.json],
        command = '"{cli}" {type} convert -i "{json}" -o "{arxml}" -r'.format(
            cli = ctx.toolchains[":toolchain_type"].dvarjson.cli,
            type = type,
            json = ctx.file.json.path,
            arxml = out.path
        ),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out]))]

def _evs_impl(ctx):
    return _dvarjson_convert(ctx, "evs")

evs = rule(
    doc = "Rule for transforming an EvaluatedVariantSet .json file to .arxml.",
    attrs = {
        "json": attr.label(doc = "The EVS .json file.", allow_single_file = [".json"], mandatory = True)
    },
    implementation = _evs_impl,
    toolchains = [":toolchain_type"]
)

def _ddm_json_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".json")
    cdd = ctx.file.cdd
    bsw = ctx.file.bsw_pkg
    patch = ctx.file.patch_file
    prefix = "../"
    for i in range(out.dirname.replace("\\", "/").count("/")):
        prefix += "../"
    ctx.actions.run_shell(
        outputs = [out],
        inputs = [cdd, bsw] + [patch] if patch else [],
        command = "echo '{content}' > '{out}'".format(
            content = json.encode(
                {
                    "$schema": "dvarjson://schema/ddm-1.schema.json",
                    "diagnosticData": {
                        "bsw": prefix + bsw.path.replace("\\", "/"),
                        "cdd": prefix + cdd.path.replace("\\", "/"),
                        "ecu": ctx.attr.ecu,
                        "variant": ctx.attr.variant,
                        "importDIDsAndRIDsAsSingleSignal": ctx.attr.did_and_rid_as_single_signal,
                        "genericLegacyDiagnosticImport": ctx.attr.generic_legacy_import,
                        "diagnosticDescriptionPatchFile": (prefix + patch.path.replace("\\", "/")) if patch else None
                    }
                }
            ),
            out = out.path
        ),
        use_default_shell_env = True
    )
    return [DefaultInfo(files = depset([out]), runfiles = ctx.runfiles(files = [bsw, cdd] + [patch] if patch else []))]

ddm_json = rule(
    doc = "Rule for creating a DDM .json file.",
    attrs = {
        "cdd": attr.label(doc = "The .cdd file.", allow_single_file = [".cdd"], mandatory = True),
        "bsw_pkg": attr.label(doc = "Path to the BSW package folder.", allow_single_file = True, mandatory = True),
        "ecu": attr.string(doc = "ECU name as defined in the given .cdd file.", mandatory = True),
        "variant": attr.string(doc = "Diagnostic variant name as defined in the given .cdd file.", mandatory = True),
        "did_and_rid_as_single_signal": attr.bool(default = False),
        "generic_legacy_import": attr.bool(default = False),
        "patch_file": attr.label(allow_single_file = True)
    },
    implementation = _ddm_json_impl
)

def _ddm_impl(ctx):
    return _dvarjson_convert(ctx, "ddm")

ddm = rule(
    doc = "Rule for extracting a diagnostic module configuration from .cdd using a DDM .json file.",
    attrs = {
        "json": attr.label(doc = "The DDM .json file.", allow_single_file = [".json"], mandatory = True)
    },
    implementation = _ddm_impl,
    toolchains = [":toolchain_type"]
)
