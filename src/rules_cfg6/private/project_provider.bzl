Cfg6ProjectInfo = provider(fields = ["project_files", "bsw_pkg_files"])

UPSTREAM_ATTR = {
    "upstream": attr.label(mandatory = True, providers = [Cfg6ProjectInfo]),
}

def get_project_root(project_info):
    for file in project_info.project_files.to_list():
        if file.is_directory:
            return file.path
        elif file.extension == "dvjson":
            return file.dirname
    fail("dvjson missing in project files.")

def get_project_root_short_path(project_info):
    for file in project_info.project_files.to_list():
        if file.is_directory:
            return file.short_path
        elif file.extension == "dvjson":
            return file.short_path.rpartition("/")[0]
    fail("dvjson missing in project files.")

def get_bsw_pkg_root(project_info):
    # xxx find root of bsw pkg
    for file in project_info.bsw_pkg_files.to_list():
        if "/Components" in file.dirname:
            return file.dirname.rpartition("/Components")[0]

    fail("Could not find root of bsw pkg")

def get_bsw_pkg_root_short_path(project_info):
    # xxx find root of bsw pkg
    for file in project_info.bsw_pkg_files.to_list():
        if "/Components" in file.short_path:
            return file.short_path.rpartition("/Components")[0]

    fail("Could not find root of bsw pkg")
