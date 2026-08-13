"""Rules for generating a DaVinci Configurator Classic 6 project to embedded sources."""

load("//:private/project_provider.bzl", "Cfg6ProjectInfo", "UPSTREAM_ATTR", "get_bsw_pkg_root", "get_project_root")
load("//toolchain:defs.bzl", "TOOLCHAIN_TYPE")

def _dvcfg6_generation(ctx):
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

    generate_bash = """
set -euo pipefail

dvcfg_exe="$(realpath $1)"
project_dir="$2"
sip_root_dir="$3"
gendata_base_dir="$4"
output_dir="$5"
shift 5

tmp_dir=$(mktemp -d || mktemp -d -t bazel-tmp)

# Copy project and on Linux sip to writable location in tmp_dir
tmp_project_dir="$tmp_dir/project/deep/ly/nest/ed"
mkdir -p "$tmp_project_dir"
cp -LRTf "$project_dir/" "$tmp_project_dir"
chmod -R +w "$tmp_project_dir"
if [ `uname` == "Linux" ]; then
    tmp_sip_root_dir="$tmp_dir/sip"
    cp -LRTf "$sip_root_dir/" "$tmp_sip_root_dir"
else
    # Windows
    tmp_sip_root_dir="$sip_root_dir"
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
"$dvcfg_exe" project generate -p "$tmp_project_dir" -b "$tmp_sip_root_dir" $@

# Redact generation date
find "$tmp_project_dir/$gendata_base_dir/" -type f \\( -name "*.c" -o -name "*.h" -o -name "*.lsl" \\) -exec \\
    sed -i -e "s/*\\s*Generation Time:.*/*   Generation Time: REDACTED/" -e "s/**  DATE, TIME\\s*:.*/**  DATE, TIME: REDACTED/" {} \\;

mv -T "$tmp_project_dir/$gendata_base_dir/" "$output_dir"
rm -rf \\"$tmp_dir\\" || true
    """

    args = ctx.actions.args().add(toolchain.cli_exe).add(project_in_root_dir).add(bsw_pkg_root_dir).add(ctx.attr.gendata_base).add(intermediate_output_dir.path)

    args.add_joined("-x", ctx.attr.excluded, join_with = ",")
    args.add("-t", ctx.attr.target)

    inputs = [project_in.project_files, project_in.bsw_pkg_files]
    if toolchain.files:
        inputs.append(toolchain.files)
    ctx.actions.run_shell(
        command = generate_bash,
        arguments = [args],
        outputs = [intermediate_output_dir],
        inputs = depset(transitive = inputs),
        toolchain = TOOLCHAIN_TYPE,
        mnemonic = "DaVinciCfg6",
    )

    # copy files out of intermediate_output_dir
    output_files = ctx.outputs.output_files
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

cfg6_generation = rule(
    doc = "Rule for generating embedded source files via DaVinci Configurator Classic 6.",
    implementation = _dvcfg6_generation,
    attrs = dict(
        UPSTREAM_ATTR,
        gendata_base = attr.string(mandatory = True, doc = "Directory where dvcfg6 writes generate files to. Relative to dv project root."),
        excluded = attr.string_list(default = [], doc = "Excluded components."),
        target = attr.string(default = "REAL", values = ["REAL", "VTT"]),
        output_files = attr.output_list(mandatory = True),
    ),
    toolchains = [TOOLCHAIN_TYPE],
)

def _swct_generation_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "/Output/Source/Templates")
    folder = out.dirname
    folder = folder[:folder.rfind("/", 0, folder.rfind("/"))]
    ctx.actions.run_shell(
        outputs = [out],
        inputs = [ctx.file.upstream],
        #command = "{unpack} && {command}".format(
        #    command = _format_command(
        #        ctx,
        #        folder,
        #        '"{dvcfg}" project generate-swct -b "{bsw_pkg}" -p "{project}"{components}{args}{keep_tmp}{no_save}',
        #        components = (' -c "' + '","'.join(ctx.attr.components) + '"') if ctx.attr.components else "",
        #        args = (' -a "' + '","'.join(ctx.attr.args) + '"') if ctx.attr.args else "",
        #        keep_tmp = " --keep-temp-files" if ctx.attr.keep_tmp_files else "",
        #        no_save = " --no-save" if ctx.attr.no_save else "",
        #    ),
        #),
        use_default_shell_env = True,
    )

cfg6_swct_generation = rule(
    doc = "Rule for generating SWC templates and contract phase headers.",
    attrs = dict(
        UPSTREAM_ATTR,
        components = attr.string_list(doc = "Software components for which a template and/or contract phase header will be generated, given by name specified in the project settings."),
        args = attr.string_list(doc = 'Arguments for certain generators given in the form "<module>:<arg>" where <module> is a module definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte").'),
        keep_tmp_files = attr.bool(doc = "Keep temporary files created during generation."),
        no_save = attr.bool(doc = "Prevent saving the project to disk."),
    ),
    implementation = _swct_generation_impl,
    toolchains = [TOOLCHAIN_TYPE],
)
