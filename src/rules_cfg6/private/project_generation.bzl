"""Rule builder for dvcfg6 code generation rules."""

load("//private:project_provider.bzl", "Cfg6ProjectInfo", "UPSTREAM_ATTR", "get_bsw_pkg_root", "get_project_root")
load("//toolchain:defs.bzl", "TOOLCHAIN_TYPE")

_PROJECT_GENERATE_LAUNCHER_SCRIPT = """
set -euo pipefail

dvcfg_exe="$(realpath $1)"
project_dir="$2"
bsw_pkg_dir="$3"
command="$4"
gendata_base_dir="$5"
output_dir="$6"
shift 6

tmp_dir=$(mktemp -d || mktemp -d -t bazel-tmp)

# Copy project and on Linux sip to writable location in tmp_dir
tmp_project_dir="$tmp_dir/project/deep/ly/nest/ed"
mkdir -p "$tmp_project_dir"
cp -LRTf "$project_dir/" "$tmp_project_dir"
chmod -R +w "$tmp_project_dir"
if [ `uname` == "Linux" ]; then
    tmp_bsw_pkg_dir="$tmp_dir/sip"
    cp -LRTf "$bsw_pkg_dir/" "$tmp_bsw_pkg_dir"
else
    # Windows
    tmp_bsw_pkg_dir="$bsw_pkg_dir"
    export OS=Windows # Required for tresos
fi

# Create fake home/appdata directory
fakehome="$tmp_dir/fakehome"
mkdir "$fakehome"
export USER=nobody
export HOME="$fakehome"
export LOCALAPPDATA="$fakehome"
export APPDATA="$fakehome"
export DVCFG_JVM_ARGS="-Duser.home=$fakehome"
export JAVA_OPTS="-Duser.home=$fakehome"

trap "\\"$dvcfg_exe\\" stop -p \\"$tmp_project_dir\\" || true" EXIT
"$dvcfg_exe" $command -p "$tmp_project_dir" -b "$tmp_bsw_pkg_dir" --no-save $@

# Redact generation date
find "$tmp_project_dir/$gendata_base_dir/" -type f \\( -name "*.c" -o -name "*.h" -o -name "*.lsl" \\) -exec \\
    sed -i -e "s/*\\s*Generation Time:.*/*   Generation Time: REDACTED/" -e "s/**  DATE, TIME\\s*:.*/**  DATE, TIME: REDACTED/" {} \\;

mv -T "$tmp_project_dir/$gendata_base_dir/" "$output_dir"
rm -rf "$tmp_dir" || true
"""

def cfg6_generation_rule(command_builder, attrs = {}, **kwargs):
    def _impl(ctx):
        # Generation involves two actions:
        # 1. Run DaVinci generate on the inputs project and sip with a single intermediate directory as output.
        #    Copy both inputs to a filesystem location where DaVinci is able to read-write in them.
        #    Also dereference symlinks along the way
        # 2. Copy the requested generated files out of the intermediate directory to the final location.
        #    This is split into a second action to prevent cache invalidations / reexecutions of DaVinci, when the set of requested generated files changes.
        intermediate_output_dir = ctx.actions.declare_directory(ctx.label.name + "/output")
        toolchain = ctx.toolchains[TOOLCHAIN_TYPE].cfg6
        project_in = ctx.attr.upstream[Cfg6ProjectInfo]

        project_in_root_dir = get_project_root(project_in)
        bsw_pkg_root_dir = get_bsw_pkg_root(project_in)

        command = command_builder(ctx)

        args = ctx.actions.args().add(toolchain.cli_exe).add(project_in_root_dir).add(bsw_pkg_root_dir).add(command.command).add(ctx.attr.gendata_base).add(intermediate_output_dir.path)

        inputs = [project_in.project_files, project_in.bsw_pkg_files]
        if toolchain.files:
            inputs.append(toolchain.files)
        ctx.actions.run_shell(
            command = _PROJECT_GENERATE_LAUNCHER_SCRIPT,
            arguments = [args, command.args],
            outputs = [intermediate_output_dir],
            inputs = depset(transitive = inputs),
            toolchain = TOOLCHAIN_TYPE,
            mnemonic = "DaVinciCfg6",
        )

        # copy files out of intermediate_output_dir
        output_files = ctx.outputs.output_files
        if output_files:
            output_dir_path = "{}/{}/".format(ctx.genfiles_dir.path, ctx.label.package)
            for output_file in output_files:
                if not output_file.path.startswith(output_dir_path):
                    fail("{} not in expected directory {}".format(output_file, output_dir_path))
            ctx.actions.run_shell(
                command = 'cp -TR "$1/" "$2" || true',
                arguments = [ctx.actions.args().add(intermediate_output_dir.path).add(output_dir_path)],
                inputs = [intermediate_output_dir],
                outputs = output_files,
            )
        return [
            DefaultInfo(
                files = depset([intermediate_output_dir]),
            ),
        ]

    return rule(
        implementation = _impl,
        attrs = dict(
            UPSTREAM_ATTR,
            gendata_base = attr.string(mandatory = True, doc = "Directory where dvcfg6 writes generate files to. Relative to dv project root."),
            output_files = attr.output_list(mandatory = False),
            **attrs
        ),
        toolchains = [TOOLCHAIN_TYPE],
        **kwargs
    )
