"""Module extension for loading DaVinci Configurator Classic 6 as toolchain."""

load(":repo.bzl", "AUTH_PATTERN_ATTRS", "cfg6_local_toolchain", "cfg6_package", "cfg6_remote_toolchain_hub")

def _cfg6_toolchain_impl(module_ctx):
    # todo handle deduplicates / conflicts

    for module in module_ctx.modules:
        for remote_attrs in module.tags.remote:
            package_repos = {}
            version = remote_attrs.version
            if remote_attrs.sha256_linux:
                linux_package_repo_name = "cfg{version}_linux_remote".format(version = version)
                url = remote_attrs.url_linux
                if url:
                    if not version in url:
                        print("Potential version mismatch: '{version}' not found in url '{url}'".format(version = version, url = url))  # buildifier: disable=print
                else:
                    url = "https://packages.vehub.vector.com/apt/pool/generic/vector-davinci-configurator-classic/{version}/vector-davinci-configurator-classic-{version}.deb".format(version = version)
                cfg6_package(
                    name = linux_package_repo_name,
                    os = "linux",
                    url = url,
                    sha256 = remote_attrs.sha256_linux,
                )
                package_repos["linux_package_repo"] = linux_package_repo_name

            if remote_attrs.sha256_windows:
                windows_package_repo_name = "cfg{version}_windows_remote".format(version = version)
                url = remote_attrs.url_windows
                if url:
                    if not version in url:
                        print("Potential version mismatch: '{version}' not found in url '{url}'".format(version = version, url = url))  # buildifier: disable=print
                else:
                    url = "https://packages.vehub.vector.com/nuget/flatcontainer/vector-davinci-configurator-classic/{version}/vector-davinci-configurator-classic.{version}.nupkg".format(version = version)
                cfg6_package(
                    name = windows_package_repo_name,
                    os = "windows",
                    url = url,
                    sha256 = remote_attrs.sha256_windows,
                )
                package_repos["windows_package_repo"] = windows_package_repo_name

            if len(package_repos) == 0:
                fail("At least one of sha256_windows or sha256_linux must be specified")

            cfg6_remote_toolchain_hub(
                name = "cfg{version}_remote".format(version = remote_attrs.version),
                **package_repos
            )

        for local_attrs in module.tags.local:
            os = local_attrs.os or module_ctx.os.name
            cfg6_local_toolchain(
                name = "cfg{version}_local".format(version = local_attrs.version),
                path = local_attrs.path,
                os = os,
            )

_remote_toolchain_tag_class = tag_class(
    doc = "DaVinci Configurator Classic Version 6 toolchain loaded from remote archive repository.",
    attrs = dict(
        AUTH_PATTERN_ATTRS,
        version = attr.string(doc = "Version of the release.", mandatory = True),
        url_windows = attr.string(doc = "Url to Cfg6 nupkg for Windows."),
        sha256_windows = attr.string(doc = "Cfg6 SHA256 archive checksum for Windows."),
        url_linux = attr.string(doc = "Url to Cfg6 deb package for Windows."),
        sha256_linux = attr.string(doc = "Cfg6 SHA256 archive checksum for Linux."),
    ),
)

_local_toolchain_tag_class = tag_class(
    doc = "DaVinci Configurator Classic Version 6 toolchain locally installed.",
    attrs = {
        "version": attr.string(doc = "Version of the release.", mandatory = True),
        "path": attr.string(mandatory = True, doc = "Absolute root path to the installation."),
        "os": attr.string(),
    },
)

cfg6_toolchain = module_extension(
    doc = "Module extension for using DaVinci projects in the Bazel pipeline.",
    implementation = _cfg6_toolchain_impl,
    tag_classes = {
        "remote": _remote_toolchain_tag_class,
        "local": _local_toolchain_tag_class,
    },
)
