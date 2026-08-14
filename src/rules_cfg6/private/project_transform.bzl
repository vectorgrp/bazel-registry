"""Rule builder for dvcfg6 project transformation step rules."""

load("//private:project_provider.bzl", "Cfg6ProjectInfo", "UPSTREAM_ATTR", "get_bsw_pkg_root", "get_project_root")
load("//toolchain:defs.bzl", "TOOLCHAIN_TYPE")

_PROJECT_TRANSFORM_LAUNCHER_SCRIPT = """
set -euo pipefail

dvcfg_exe="$(realpath $1)"
in_project_dir="$2"
out_project_dir="$3"
bsw_pkg_dir="$4"
command="$5"
shift 5

tmp_dir=$(mktemp -d || mktemp -d -t bazel-tmp)

cp -LRTf "$in_project_dir/" "$out_project_dir"

# Create fake home/appdata directory
fakehome="$tmp_dir/fakehome"
mkdir "$fakehome"
export USER=nobody
export HOME="$fakehome"
export LOCALAPPDATA="$fakehome"
export APPDATA="$fakehome"
export DVCFG_JVM_ARGS="-Duser.home=$fakehome"
export JAVA_OPTS="-Duser.home=$fakehome"

trap "\\"$dvcfg_exe\\" stop -p \\"$out_project_dir\\" || true" EXIT
"$dvcfg_exe" $command -p "$out_project_dir" -b "$bsw_pkg_dir" $@

rm -rf "$tmp_dir" || true
    """

def cfg6_project_transform_rule(*, command_builder, attrs = {}, **kwargs):
    """Rule builder for dvcfg6 project transformation step rules."""

    def impl_wrapper(ctx):
        project_in = ctx.attr.upstream[Cfg6ProjectInfo]
        command_info = command_builder(ctx)

        project_in_root_dir = get_project_root(project_in)
        bsw_pkg_root_dir = get_bsw_pkg_root(project_in)

        project_out = ctx.actions.declare_directory(ctx.label.name + "/project_out")
        toolchain = ctx.toolchains[TOOLCHAIN_TYPE].cfg6
        inputs = []
        transitive_inputs = [project_in.project_files, project_in.bsw_pkg_files]
        if toolchain.files:
            transitive_inputs.append(toolchain.files)

        if hasattr(command_info, "inputs"):
            if hasattr(command_info.inputs, "to_list"):
                transitive_inputs.append(command_info.inputs)
            else:
                inputs = [command_info.inputs]

        outputs = [project_out]
        if hasattr(command_info, "outputs"):
            outputs.extend(command_info.outputs)
        arguments = [
            ctx.actions.args().add(toolchain.cli_exe).add(project_in_root_dir).add(project_out.path).add(bsw_pkg_root_dir),
            command_info.command,
        ]
        if hasattr(command_info, "args"):
            arguments.append(command_info.args)

        ctx.actions.run_shell(
            command = _PROJECT_TRANSFORM_LAUNCHER_SCRIPT,
            arguments = arguments,
            outputs = outputs,
            inputs = depset(inputs, transitive = transitive_inputs),
            toolchain = TOOLCHAIN_TYPE,
            mnemonic = "DaVinciCfg6",
        )

        return [
            Cfg6ProjectInfo(
                project_files = depset([project_out]),
                bsw_pkg_files = project_in.bsw_pkg_files,
            ),
            DefaultInfo(files = depset(command_info.outputs if hasattr(command_info, "outputs") else [project_out])),
        ]

    return rule(
        implementation = impl_wrapper,
        attrs = dict(
            UPSTREAM_ATTR,
            **attrs
        ),
        provides = [Cfg6ProjectInfo],
        toolchains = [TOOLCHAIN_TYPE],
        **kwargs
    )
