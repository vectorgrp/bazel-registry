"""Rule builder for dvcfg6 code generation rules."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("//private:project_provider.bzl", "Cfg6ProjectInfo", "UPSTREAM_ATTR", "get_bsw_pkg_root", "get_project_root")
load("//toolchain:defs.bzl", "TOOLCHAIN_TYPE")
load(":remote_caching.bzl", "RemoteCacheInfo")

_JQ_TOOLCHAIN_TYPE = Label("@jq.bzl//jq/toolchain:type")

_PROJECT_GENERATE_LAUNCHER_SCRIPT = """
set -eo pipefail

dvcfg_exe="$(realpath $1)"
project_dir="$2"
bsw_pkg_dir="$3"
command="$4"
output_dir="$5"
shift 5

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

if [[ ! -z "$DVCFG_CACHE_CONFIG_LOCATION" ]]; then
    # copy to tmp location as cfg6 is not able to dereference symlinks
    cp -LRTf "$DVCFG_CACHE_CONFIG_LOCATION" "$tmp_dir/cache"
    export DVCFG_CACHE_CONFIG_LOCATION="$tmp_dir/cache"
fi

# Create fake home/appdata directory
fakehome="$tmp_dir/fakehome"
mkdir "$fakehome"
export USER=nobody
export HOME="$fakehome"
export LOCALAPPDATA="$fakehome"
export APPDATA="$fakehome"
export DVCFG_JVM_ARGS="-Duser.home=$fakehome $EXTRA_JVM_ARGS"
export JAVA_OPTS="-Duser.home=$fakehome $EXTRA_JVM_ARGS"

# Redirect genData/genDataVtt/source folders of the general settings (referenced via the .dvjson) into output_dir
dvjson=$(find "$tmp_project_dir" -maxdepth 1 -name "*.dvjson" | head -n 1)
general_json="$tmp_project_dir/$("$JQ_BIN" -r '.general' "$dvjson")"
mkdir -p "$output_dir/genData" "$output_dir/genDataVtt" "$output_dir/source"
# Settings paths are resolved relative to the settings file, so pass absolute paths.
# On Windows convert msys paths (/c/foo) to native drive paths (C:/foo), as msys does not translate file contents.
abs_output_dir=$(realpath "$output_dir")
case `uname` in
    MINGW*|MSYS*|CYGWIN*) abs_output_dir=$(cygpath -m "$abs_output_dir");;
esac
"$JQ_BIN" --arg gendata "$abs_output_dir/genData" --arg gendatavtt "$abs_output_dir/genDataVtt" --arg source "$abs_output_dir/source" \\
    '.folders.genData = $gendata | .folders.genDataVtt = $gendatavtt | .folders.source = $source' "$general_json" > "$general_json.tmp"
mv -f "$general_json.tmp" "$general_json"

trap "\\"$dvcfg_exe\\" stop -p \\"$tmp_project_dir\\" --force; rm -rf \\"$tmp_dir\\" || true" EXIT
"$dvcfg_exe" $command -p "$tmp_project_dir" -b "$tmp_bsw_pkg_dir" --no-save $@

# Redact generation date
find "$output_dir" -type f \\( -name "*.c" -o -name "*.h" -o -name "*.lsl" \\) -exec \\
    sed -i -e "s/*\\s*Generation Time:.*/*   Generation Time: REDACTED/" -e "s/**  DATE, TIME\\s*:.*/**  DATE, TIME: REDACTED/" {} \\;
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

        jq_bin = ctx.toolchains[_JQ_TOOLCHAIN_TYPE].jqinfo.bin
        env = {"JQ_BIN": jq_bin.path}
        args = ctx.actions.args().add(toolchain.cli_exe).add(project_in_root_dir).add(bsw_pkg_root_dir).add(command.command).add(intermediate_output_dir.path)

        inputs = [project_in.project_files, project_in.bsw_pkg_files]
        if toolchain.files:
            inputs.append(toolchain.files)

        remote_cache_info = ctx.attr._remote_cache[RemoteCacheInfo]
        if remote_cache_info.enabled:
            # We need to provide the directory instead of the actual config file
            env["DVCFG_CACHE_CONFIG_LOCATION"] = remote_cache_info.config_file.path.rpartition("/")[0]
            inputs.append(depset([remote_cache_info.config_file]))

        if ctx.attr._extra_jvm_args:
            env["EXTRA_JVM_ARGS"] = ctx.attr._extra_jvm_args[BuildSettingInfo].value

        ctx.actions.run_shell(
            command = _PROJECT_GENERATE_LAUNCHER_SCRIPT,
            arguments = [args, command.args],
            env = env,
            inputs = depset(transitive = inputs),
            tools = [jq_bin],
            outputs = [intermediate_output_dir],
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
            output_files = attr.output_list(mandatory = False),
            _remote_cache = attr.label(providers = [RemoteCacheInfo], default = Label("//:remote_cache")),
            _extra_jvm_args = attr.label(providers = [BuildSettingInfo], default = Label("//:extra_jvm_args")),
            **attrs
        ),
        toolchains = [TOOLCHAIN_TYPE, _JQ_TOOLCHAIN_TYPE],
        **kwargs
    )
