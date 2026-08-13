"""Toolchain definitions for DaVinci Configurator Classic 6."""

TOOLCHAIN_TYPE = Label("//:toolchain_type")

Cfg6ToolchainInfo = provider("dvcfg6 toolchain", fields = ["cli_exe", "core_exe", "xpro_exe", "gui_exe", "files"])

def _cfg6_local_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            cfg6 = Cfg6ToolchainInfo(
                cli_exe = ctx.attr.cli_exe,
                core_exe = ctx.attr.core_exe,
                xpro_exe = ctx.attr.xpro_exe,
                gui_exe = ctx.attr.gui_exe,
                files = None,
            ),
        ),
    ]

cfg6_local_toolchain = rule(
    implementation = _cfg6_local_toolchain_impl,
    attrs = {
        "cli_exe": attr.string(mandatory = True),
        "core_exe": attr.string(mandatory = True),
        "xpro_exe": attr.string(mandatory = True),
        "gui_exe": attr.string(),
    },
)

def _cfg6_hermetic_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            cfg6 = Cfg6ToolchainInfo(
                cli_exe = ctx.file.cli_exe,
                core_exe = ctx.file.core_exe,
                xpro_exe = ctx.file.xpro_exe,
                gui_exe = ctx.file.gui_exe,
                files = depset(ctx.files.files),
            ),
        ),
    ]

cfg6_hermetic_toolchain = rule(
    implementation = _cfg6_hermetic_toolchain_impl,
    attrs = {
        "cli_exe": attr.label(allow_single_file = True, mandatory = True),
        "core_exe": attr.label(allow_single_file = True, mandatory = True),
        "xpro_exe": attr.label(allow_single_file = True, mandatory = True),
        "gui_exe": attr.label(allow_single_file = True),
        "files": attr.label_list(allow_files = True, doc = "Files of a hermetic DaVinci Cfg6 installation."),
    },
)
