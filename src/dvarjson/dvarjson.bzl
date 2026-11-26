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

_DvarjsonToolProvider = provider()

def _dvarjson_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            dvarjson = _DvarjsonToolProvider(
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
