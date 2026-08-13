def single_file_from_target(target):
    files = target[DefaultInfo].files.to_list()
    if len(files) != 1:
        fail("Expected exactly one file from {} but got {}.".format(target.label, len(files)))
    return files[0]
