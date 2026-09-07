load("@rules_cfg6//:rules.bzl", "default_http_archive_attrs", "download_and_extract")

def _evo1_archive_impl(repository_ctx):
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
            strip_prefix = "opt/vector-davinci-configurator-classic"
        )
    repository_ctx.delete("_download_")
    repository_ctx.file("BUILD.bazel")
    ext = ".exe" if repository_ctx.os.name.startswith("windows") else ""
    repository_ctx.file("defs.bzl", 'evo1_gui = "{}"'.format(str(repository_ctx.path("_/dvcfgui-b/dvcfgui-b" + ext)).replace("\\", "/")))

evo1_archive = repository_rule(
    doc = "Rule for using a DaVinci Configurator Classic Version 6 Evo1 GUI .nupkg or .deb archive.",
    attrs = { "nupkg_" + k: v for k, v in default_http_archive_attrs(".nupkg", "url").items() } | default_http_archive_attrs(".deb", "nupkg_url"),
    implementation = _evo1_archive_impl
)
