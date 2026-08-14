"""Rule builder for dvcfg6 project transformation step rules."""

Cfg6ProjectInfo = provider("dvcfg6 project with bsw", fields = ["project_files", "bsw_pkg_files"])

UPSTREAM_ATTR = {
    "upstream": attr.label(mandatory = True, providers = [Cfg6ProjectInfo]),
}

def get_project_root(project_info):
    """Resolve root path of dvcfg6 project.

    Args:
        project_info: Cfg6ProjectInfo provider
    Returns:
        root path of project directory relative to execution root / workspace
    """
    for file in project_info.project_files.to_list():
        if file.is_directory:
            return file.path
        elif file.extension == "dvjson":
            return file.dirname
    fail("dvjson missing in project files.")

def get_project_root_short_path(project_info):
    """Resolve root short path of dvcfg6 project.

    Args:
        project_info: Cfg6ProjectInfo provider
    Returns:
        root path of project directory relative to runfiles root
    """
    for file in project_info.project_files.to_list():
        if file.is_directory:
            return file.short_path
        elif file.extension == "dvjson":
            return file.short_path.rpartition("/")[0]
    fail("dvjson missing in project files.")

def get_bsw_pkg_root(project_info):
    """Resolve root path of bsw package.

    Args:
        project_info: Cfg6ProjectInfo provider
    Returns:
        root path of bsw package relative to execution root / workspace
    """
    for file in project_info.bsw_pkg_files.to_list():
        if "/Components" in file.dirname:
            return file.dirname.rpartition("/Components")[0]

    fail("Could not find root of bsw pkg")

def get_bsw_pkg_root_short_path(project_info):
    """Resolve root short path of bsw package.

    Args:
        project_info: Cfg6ProjectInfo provider
    Returns:
        root path of bsw package relative to runfiles root
    """

    # xxx find root of bsw pkg
    for file in project_info.bsw_pkg_files.to_list():
        if "/Components" in file.short_path:
            return file.short_path.rpartition("/Components")[0]

    fail("Could not find root of bsw pkg")
