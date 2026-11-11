<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# rules_cfg6 v4.0.0

```starlark
bazep_dep(name = "rules_cfg6", version = "4.0.0")
```

Bazel ruleset for working with [DaVinci Configurator Classic Version 6](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/index.html).

<a id="cfg6_toolchain"></a>

## cfg6_toolchain

<pre>
load("@rules_cfg6//:defs.bzl", "cfg6_toolchain")

cfg6_toolchain(<a href="#cfg6_toolchain-name">name</a>, <a href="#cfg6_toolchain-cfg6_files">cfg6_files</a>, <a href="#cfg6_toolchain-cli">cli</a>, <a href="#cfg6_toolchain-core">core</a>, <a href="#cfg6_toolchain-differ">differ</a>, <a href="#cfg6_toolchain-settings_patcher">settings_patcher</a>, <a href="#cfg6_toolchain-xpro">xpro</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cfg6_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cfg6_toolchain-cfg6_files"></a>cfg6_files |  All files of the CFG6 installation, declared as tools of every action using one of the executables.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="cfg6_toolchain-cli"></a>cli |  The DaVinci Configurator CLI executable.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="cfg6_toolchain-core"></a>core |  The DaVinci Configurator core executable.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="cfg6_toolchain-differ"></a>differ |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="cfg6_toolchain-settings_patcher"></a>settings_patcher |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="cfg6_toolchain-xpro"></a>xpro |  The ECU extract processor executable.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="derive_ecuc"></a>

## derive_ecuc

<pre>
load("@rules_cfg6//:defs.bzl", "derive_ecuc")

derive_ecuc(<a href="#derive_ecuc-name">name</a>, <a href="#derive_ecuc-srcs">srcs</a>, <a href="#derive_ecuc-bsw_pkg">bsw_pkg</a>, <a href="#derive_ecuc-settings">settings</a>)
</pre>

Derive an ECU configuration from the given input files.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="derive_ecuc-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="derive_ecuc-srcs"></a>srcs |  Input files (ECU extract and - for post-build selectable only - EvaluatedVariantSet).   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="derive_ecuc-bsw_pkg"></a>bsw_pkg |  The BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="derive_ecuc-settings"></a>settings |  Optional configuration file.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |


<a id="expand_file_paths"></a>

## expand_file_paths

<pre>
load("@rules_cfg6//:defs.bzl", "expand_file_paths")

expand_file_paths(<a href="#expand_file_paths-name">name</a>, <a href="#expand_file_paths-substitutions">substitutions</a>, <a href="#expand_file_paths-template">template</a>)
</pre>

Expand file paths in a template.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="expand_file_paths-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="expand_file_paths-substitutions"></a>substitutions |  Files whose paths to expand in the template.   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="expand_file_paths-template"></a>template |  The UTF-8 encoded template file.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |


<a id="from_scratch"></a>

## from_scratch

<pre>
load("@rules_cfg6//:defs.bzl", "from_scratch")

from_scratch(<a href="#from_scratch-name">name</a>, <a href="#from_scratch-bsw_pkg">bsw_pkg</a>, <a href="#from_scratch-settings">settings</a>)
</pre>

Create a new DaVinci Configurator Classic Version 6 project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="from_scratch-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="from_scratch-bsw_pkg"></a>bsw_pkg |  The BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="from_scratch-settings"></a>settings |  Optional JSON file for overriding default project settings. E.g., for setting `allowMergeConflicts` in the `General.json` file to `true` and removing the mapping for the `Dcm` module from the `moduleDefinitionMappings` array in the `Ifp.json` file:<br><br><pre><code class="language-json">{&#10;  "general": {&#10;    "allowMergeConflicts": true&#10;  },&#10;  "ifp": {&#10;    "moduleDefinitionMappings": [&#10;      { "__delete__": true, "moduleConfigName": "Dcm" }&#10;    ]&#10;  }&#10;}</code></pre><br><br>Each object-typed property is merged into the settings file referenced by the .dvjson file with the corresponding key:<br><br>- Object-typed properties are merged recursively. - Primitive-typed properties are overwritten with the given value (use `null` to delete the property). - Arrays with primitive-typed elements are merged as duplicate-free unions. - Objects in arrays are identified by a key property:   - In `General.json`, `useCases` are identified by their `vector` property.   - In `Ifp.json`, `moduleDefinitionMappings` are identified by their `moduleConfigName` (see example) and `comControllerMappings` by their `clusterPath`.   - Use the `__delete__` property (see example) to remove an object from the array.<br><br>Some settings might point to generated files. Use [expand_file_paths](#expand_file_paths) for these.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |


<a id="hybrid"></a>

## hybrid

<pre>
load("@rules_cfg6//:defs.bzl", "hybrid")

hybrid(<a href="#hybrid-name">name</a>, <a href="#hybrid-srcs">srcs</a>, <a href="#hybrid-bsw_pkg">bsw_pkg</a>, <a href="#hybrid-derived">derived</a>)
</pre>

Use an existing DaVinci Configurator Classic Version 6 project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="hybrid-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="hybrid-srcs"></a>srcs |  The files of a checked-in project that invalidate this target when they change:<br><br>- The .dvjson file (always required). - All settings .json files (referenced by the .dvjson file).<br><br>All of these files must be contained below the parent folder of the .dvjson file.<br><br>Usually a `hybrid` target is extended using [apply_command](#apply_command). All checked-in project files must be listed as inputs of the `apply_command` target that needs to re-run when they change.<br><br>Typically, it is the `project update` command that needs to be re-executed when any files in the `./Config` folder have been modified:<br><br><pre><code class="language-starlark">apply_command(&#10;    name = "project",&#10;    project = ":upstream",&#10;    command = '{dvcfg} project update {-p} {-b}',&#10;    # changes in any file inside the ./Config folder invalidate this target&#10;    # instable ReferenceCorrectionData.arxml is excluded&#10;    inputs = { "user_ecuc": glob(include = ["Config/**"], exclude = ["Config/StructuredExtract/BswConfig/ReferenceCorrectionData.arxml"]) }&#10;)</code></pre><br><br>Modifications to the files invalidate the target even if they are not used in the actual CLI call.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="hybrid-bsw_pkg"></a>bsw_pkg |  The BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="hybrid-derived"></a>derived |  Optional GNU tar exclude patterns listing all derived project files/folders.   | List of strings | optional |  `["./Output"]`  |


<a id="kt_jar_library"></a>

## kt_jar_library

<pre>
load("@rules_cfg6//:defs.bzl", "kt_jar_library")

kt_jar_library(<a href="#kt_jar_library-name">name</a>, <a href="#kt_jar_library-deps">deps</a>, <a href="#kt_jar_library-srcs">srcs</a>, <a href="#kt_jar_library-kotlinc_opts">kotlinc_opts</a>, <a href="#kt_jar_library-module_name">module_name</a>)
</pre>

Kotlin JVM library compiled straight to jar.

Generated foundation layer file names may exceed the 255-character limit of NTFS and ext4.
This rule runs the compiler with `-d <out>.jar`, which makes it write every class straight
into the archive.

The produced jar must never be extracted.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="kt_jar_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="kt_jar_library-deps"></a>deps |  Compile and runtime dependencies.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="kt_jar_library-srcs"></a>srcs |  Kotlin sources, compiled as one compilation unit.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="kt_jar_library-kotlinc_opts"></a>kotlinc_opts |  `kt_kotlinc_options` target. Defaults to the options of the Kotlin toolchain.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="kt_jar_library-module_name"></a>module_name |  Kotlin module name (the `META-INF/<name>.kotlin_module` entry). Defaults to the target name.   | String | optional |  `""`  |


<a id="merged_extract"></a>

## merged_extract

<pre>
load("@rules_cfg6//:defs.bzl", "merged_extract")

merged_extract(<a href="#merged_extract-name">name</a>, <a href="#merged_extract-src">src</a>)
</pre>

Rule for merging multiple .arxml files into an ECU extract.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="merged_extract-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="merged_extract-src"></a>src |  The .arxml files to merge into one ECU extract.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="project_file"></a>

## project_file

<pre>
load("@rules_cfg6//:defs.bzl", "project_file")

project_file(<a href="#project_file-name">name</a>, <a href="#project_file-out">out</a>, <a href="#project_file-default_content">default_content</a>, <a href="#project_file-path">path</a>, <a href="#project_file-project">project</a>)
</pre>

Get a file from a project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="project_file-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="project_file-out"></a>out |  Optional name for the created file (defaults to label name).   | String | optional |  `""`  |
| <a id="project_file-default_content"></a>default_content |  Optional default content to return in case the project does not contain a file at the given path. Omit this to let the action fail in case the file is missing.   | String | optional |  `"\x00"`  |
| <a id="project_file-path"></a>path |  The path of the file relative to the project folder.   | String | required |  |
| <a id="project_file-project"></a>project |  The project from which to get the file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="project_folder"></a>

## project_folder

<pre>
load("@rules_cfg6//:defs.bzl", "project_folder")

project_folder(<a href="#project_folder-name">name</a>, <a href="#project_folder-path">path</a>, <a href="#project_folder-project">project</a>)
</pre>

Get a folder from a project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="project_folder-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="project_folder-path"></a>path |  The path of the folder relative to the project folder.   | String | optional |  `""`  |
| <a id="project_folder-project"></a>project |  The project from which to get the folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="script_patched_arxml"></a>

## script_patched_arxml

<pre>
load("@rules_cfg6//:defs.bzl", "script_patched_arxml")

script_patched_arxml(<a href="#script_patched_arxml-name">name</a>, <a href="#script_patched_arxml-srcs">srcs</a>, <a href="#script_patched_arxml-tasks">tasks</a>)
</pre>

Rule for patching .arxml file content by applying a script task.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="script_patched_arxml-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="script_patched_arxml-srcs"></a>srcs |  The .arxml files to be patched.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `["@rules_cfg6//:empty.arxml"]`  |
| <a id="script_patched_arxml-tasks"></a>tasks |  The tasks to execute (see [script_task](#script_task)).   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |


<a id="script_task"></a>

## script_task

<pre>
load("@rules_cfg6//:defs.bzl", "script_task")

script_task(<a href="#script_task-name">name</a>, <a href="#script_task-args">args</a>, <a href="#script_task-file_args">file_args</a>, <a href="#script_task-script">script</a>, <a href="#script_task-task_name">task_name</a>)
</pre>

Rule for selecting a script task from a script and optionally provide command line arguments for the task.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="script_task-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="script_task-args"></a>args |  Optional arguments for the script task.   | List of strings | optional |  `[]`  |
| <a id="script_task-file_args"></a>file_args |  Optional file arguments for the script task (keys are arg names).   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="script_task-script"></a>script |  Location of the script (".dv.groovy" file, ".jar" file or folder).   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="script_task-task_name"></a>task_name |  The task name (defaults to rule name).   | String | optional |  `""`  |


<a id="system_extract"></a>

## system_extract

<pre>
load("@rules_cfg6//:defs.bzl", "system_extract")

system_extract(<a href="#system_extract-name">name</a>, <a href="#system_extract-src">src</a>, <a href="#system_extract-ecu">ecu</a>)
</pre>

Rule for extracting a given ECU from a system description.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="system_extract-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="system_extract-src"></a>src |  The system description .arxml files from which to extract the given ECU.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="system_extract-ecu"></a>ecu |  The ECU to extract from the given system description (defaults to rule name).   | String | optional |  `""`  |


<a id="variant_extract"></a>

## variant_extract

<pre>
load("@rules_cfg6//:defs.bzl", "variant_extract")

variant_extract(<a href="#variant_extract-name">name</a>, <a href="#variant_extract-srcs">srcs</a>, <a href="#variant_extract-config">config</a>, <a href="#variant_extract-evs">evs</a>)
</pre>

Rule for creating a variant ECU extract from invariant extracts.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="variant_extract-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="variant_extract-srcs"></a>srcs |  One extract file for each variant in the EvaluatedVariantSet. E.g.: { "VariantA": ":ExtractA", ... }   | Dictionary: String -> Label | required |  |
| <a id="variant_extract-config"></a>config |  The merge configuration .xml file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="variant_extract-evs"></a>evs |  The .arxml files containing the EvaluatedVariantSet.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="encode_eac_arg"></a>

## encode_eac_arg

<pre>
load("@rules_cfg6//:defs.bzl", "encode_eac_arg")

encode_eac_arg(<a href="#encode_eac_arg-arg">arg</a>)
</pre>

JSON-encoding for EaC command line arguments.

If the code takes a command line argument use this method to obtain a correctly encoded string to use in the command line call running the code.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="encode_eac_arg-arg"></a>arg |  the argument passed to the code as JSON (using `json.encode`).   |  none |

**RETURNS**

a string containing the JSON-encoded argument.
  Insert this in the command line running the code directly after (no spaces) the path to the .jar file. E.g.:
  ```
  apply_command(
      name = "as_code",
      project = ":upstream",
      command = "{dvcfg} eac {-b} {-p} {-c}" + encode_eac_arg({ "my": "arg" }),
      inputs = { "-c": ":jar" },
  )
  ```


<a id="app_design"></a>

## app_design

<pre>
load("@rules_cfg6//:defs.bzl", "app_design")

app_design(*, <a href="#app_design-name">name</a>, <a href="#app_design-srcs">srcs</a>, <a href="#app_design-aspect_hints">aspect_hints</a>, <a href="#app_design-code">code</a>, <a href="#app_design-compatible_with">compatible_with</a>, <a href="#app_design-deprecation">deprecation</a>, <a href="#app_design-exec_compatible_with">exec_compatible_with</a>,
           <a href="#app_design-exec_group_compatible_with">exec_group_compatible_with</a>, <a href="#app_design-exec_properties">exec_properties</a>, <a href="#app_design-features">features</a>, <a href="#app_design-package_metadata">package_metadata</a>, <a href="#app_design-pai_version">pai_version</a>,
           <a href="#app_design-restricted_to">restricted_to</a>, <a href="#app_design-script_classes">script_classes</a>, <a href="#app_design-tags">tags</a>, <a href="#app_design-target_compatible_with">target_compatible_with</a>, <a href="#app_design-task_name">task_name</a>, <a href="#app_design-testonly">testonly</a>,
           <a href="#app_design-toolchains">toolchains</a>, <a href="#app_design-visibility">visibility</a>)
</pre>

Internal macro for setting up an AppDesign project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="app_design-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="app_design-srcs"></a>srcs |  The .arxml files to be patched.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `["@rules_cfg6//:empty.arxml"]`  |
| <a id="app_design-aspect_hints"></a>aspect_hints |  <a href="https://bazel.build/reference/be/common-definitions#common.aspect_hints">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="app_design-code"></a>code |  Libraries to make available to the final binary or test at runtime only. Like ordinary <code>deps</code>, these will appear on the runtime classpath, but unlike them, not on the compile-time classpath. Dependencies needed only at runtime should be listed here. Dependency-analysis tools should ignore targets that appear in both <code>runtime_deps</code> and <code>deps</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="app_design-compatible_with"></a>compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="app_design-deprecation"></a>deprecation |  <a href="https://bazel.build/reference/be/common-definitions#common.deprecation">Inherited rule attribute</a>   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="app_design-exec_compatible_with"></a>exec_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="app_design-exec_group_compatible_with"></a>exec_group_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_group_compatible_with">Inherited rule attribute</a>   | Dictionary: String -> List of labels; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="app_design-exec_properties"></a>exec_properties |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_properties">Inherited rule attribute</a>   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `None`  |
| <a id="app_design-features"></a>features |  <a href="https://bazel.build/reference/be/common-definitions#common.features">Inherited rule attribute</a>   | List of strings | optional |  `None`  |
| <a id="app_design-package_metadata"></a>package_metadata |  <a href="https://bazel.build/reference/be/common-definitions#common.package_metadata">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="app_design-pai_version"></a>pai_version |  -   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="app_design-restricted_to"></a>restricted_to |  <a href="https://bazel.build/reference/be/common-definitions#common.restricted_to">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="app_design-script_classes"></a>script_classes |  -   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `["AppDesign"]`  |
| <a id="app_design-tags"></a>tags |  <a href="https://bazel.build/reference/be/common-definitions#common.tags">Inherited rule attribute</a>   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="app_design-target_compatible_with"></a>target_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.target_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="app_design-task_name"></a>task_name |  -   | String | optional |  `"AppDesign"`  |
| <a id="app_design-testonly"></a>testonly |  <a href="https://bazel.build/reference/be/common-definitions#common.testonly">Inherited rule attribute</a>   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="app_design-toolchains"></a>toolchains |  <a href="https://bazel.build/reference/be/common-definitions#common.toolchains">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="app_design-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="apply_command"></a>

## apply_command

<pre>
load("@rules_cfg6//:defs.bzl", "apply_command")

apply_command(*, <a href="#apply_command-name">name</a>, <a href="#apply_command-command">command</a>, <a href="#apply_command-dev_target">dev_target</a>, <a href="#apply_command-env">env</a>, <a href="#apply_command-inputs">inputs</a>, <a href="#apply_command-project">project</a>, <a href="#apply_command-visibility">visibility</a>)
</pre>

Extend a project by running a command on it (see [here](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/references/cli/index.html) for available commnds). E.g.:

- `{dvcfg} project update {-b} {-p}` updates the project (e.g. on input file changes).
- `{dvcfg} project validate {-b} {-p} --fail-on NONE` creates a validation report. [project_file](#project_file) with `path = "Output/Log/ValidationOutput.json"` yields the report.
- `{dvcfg} project generate {-b} {-p}` generates BSW code. [project_folder](#project_folder) with `path = "Output/Source/GenData"` yields the generation result.
- `{dvcfg} project generate-swct {-b} {-p}` generates SWC templates. [project_folder](#project_folder) with `path = "Output/Source/Templates"` yields the generation result.
- `{dvcfg} automation run {-b} {-p} {-l} -t MyTask` runs a PAI task (see `inputs` on how to provide the script location `{-l}`).
- `{dvcfg} export run {-b} {-p} -o "{project_dir}" -e everything` exports the entire AUTOSAR model. [project_file](#project_file) with `path = "Exported_everything.arxml"` yields the result.

`{dvcfg}` is expanded to the path of the DaVinci Configurator 6 CLI executable.
Use `{-p}` for the project and `{-b}` for the BSW package.
`{project_dir}` is expanded to the project folder (unquoted; useful for specifying output locations).

The `{diff}` command can be used to compare the states of a project before and after a command has been applied. E.g., a command like

```
{dvcfg} eac {-b} {-p} ...
{diff} eac.jsonl

{dvcfg} project update {-b} {-p}
{diff} update.jsonl
```

applies EaC and then updates the project. Additionally two JSONL files are created inside the project:

- `eac.jsonl` contains the comparison of the project before and after EaC has been applied.
- `update.jsonl` contains the comparison of the project after EaC has been applied and after the project has been updated.

The `{diff}` command can also be used with a second argument:

```
{diff} diff.jsonl {theirs}
```

If used like this, `input` is expected to contain an entry like `{ "theirs": ":some_project" }` where `:some_project`
is a target pointing to another DaVinci project.

Use [project_file](#project_file) with the same path as has been procided to `{diff}` to extract the created JSONL reports.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="apply_command-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="apply_command-command"></a>command |  Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell)). Separate multiple CLI calls with newline or semicolon.   | String | required |  |
| <a id="apply_command-dev_target"></a>dev_target |  Setting this to `True` results in a convenience development target `<name>_dev` for manually running/debugging the command.   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="apply_command-env"></a>env |  Optional environment variables.   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="apply_command-inputs"></a>inputs |  Inputs used in `command`. The following rules apply:<br><br>- Dictionary keys starting with `-` (minus): `inputs = { "-f": "<label>" }` and `command = "... {-f} ..."` yield a resulting command line like this: `... -f <file1> -f <file2> ...` (i.e., all files are listed with the preceeding switch). - Dictionary keys containing `\|` (pipe): `inputs = { "files\|,": "<label>" }` and `command = "... -f {files} ..."` yield a resulting command line like this: `... -f <file1>,<file2> ...` (i.e, all files are listed, joined by the given separator). - Pipe and separator are optional defaulting to a single space separator, i.e.: `inputs = { "files": "<label>" }` and `command = "import {files}"` yield a resulting command line like this: `import <file1> <file2> ...`.   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="apply_command-project"></a>project |  The project to which to apply the command.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="apply_command-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="arxml_patch"></a>

## arxml_patch

<pre>
load("@rules_cfg6//:defs.bzl", "arxml_patch")

arxml_patch(*, <a href="#arxml_patch-name">name</a>, <a href="#arxml_patch-deps">deps</a>, <a href="#arxml_patch-srcs">srcs</a>, <a href="#arxml_patch-data">data</a>, <a href="#arxml_patch-resources">resources</a>, <a href="#arxml_patch-add_exports">add_exports</a>, <a href="#arxml_patch-add_opens">add_opens</a>, <a href="#arxml_patch-allow_beta">allow_beta</a>, <a href="#arxml_patch-bootclasspath">bootclasspath</a>,
            <a href="#arxml_patch-call">call</a>, <a href="#arxml_patch-exported_plugins">exported_plugins</a>, <a href="#arxml_patch-exports">exports</a>, <a href="#arxml_patch-javabuilder_jvm_flags">javabuilder_jvm_flags</a>, <a href="#arxml_patch-javacopts">javacopts</a>, <a href="#arxml_patch-licenses">licenses</a>, <a href="#arxml_patch-neverlink">neverlink</a>,
            <a href="#arxml_patch-pai_version">pai_version</a>, <a href="#arxml_patch-plugins">plugins</a>, <a href="#arxml_patch-proguard_specs">proguard_specs</a>, <a href="#arxml_patch-resource_strip_prefix">resource_strip_prefix</a>, <a href="#arxml_patch-runtime_deps">runtime_deps</a>, <a href="#arxml_patch-tags">tags</a>,
            <a href="#arxml_patch-visibility">visibility</a>)
</pre>

Macro for creating a task to be used in rule `script_patched_arxml`.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="arxml_patch-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="arxml_patch-deps"></a>deps |  The list of libraries to link into this library. See general comments about <code>deps</code> at <a href="${link common-definitions#typical-attributes}">Typical attributes defined by most build rules</a>. <p>   The jars built by <code>java_library</code> rules listed in <code>deps</code> will be on   the compile-time classpath of this rule. Furthermore the transitive closure of their   <code>deps</code>, <code>runtime_deps</code> and <code>exports</code> will be on the   runtime classpath. </p> <p>   By contrast, targets in the <code>data</code> attribute are included in the runfiles but   on neither the compile-time nor runtime classpath. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="arxml_patch-srcs"></a>srcs |  [Inherited rule attribute](https://bazel.build/reference/be/java#java_library)   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="arxml_patch-data"></a>data |  The list of files needed by this library at runtime. See general comments about <code>data</code> at <a href="${link common-definitions#typical-attributes}">Typical attributes defined by most build rules</a>. <p>   When building a <code>java_library</code>, Bazel doesn't put these files anywhere; if the   <code>data</code> files are generated files then Bazel generates them. When building a   test that depends on this <code>java_library</code> Bazel copies or links the   <code>data</code> files into the runfiles area. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="arxml_patch-resources"></a>resources |  A list of data files to include in a Java jar. <p> Resources may be source files or generated files. </p><br><br><p> If resources are specified, they will be bundled in the jar along with the usual <code>.class</code> files produced by compilation. The location of the resources inside of the jar file is determined by the project structure. Bazel first looks for Maven's <a href="https://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html">standard directory layout</a>, (a "src" directory followed by a "resources" directory grandchild). If that is not found, Bazel then looks for the topmost directory named "java" or "javatests" (so, for example, if a resource is at <code>&lt;workspace root&gt;/x/java/y/java/z</code>, the path of the resource will be <code>y/java/z</code>. This heuristic cannot be overridden, however, the <code>resource_strip_prefix</code> attribute can be used to specify a specific alternative directory for resource files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="arxml_patch-add_exports"></a>add_exports |  Allow this library to access the given <code>module</code> or <code>package</code>. <p> This corresponds to the javac and JVM --add-exports= flags.   | List of strings | optional |  `None`  |
| <a id="arxml_patch-add_opens"></a>add_opens |  Allow this library to reflectively access the given <code>module</code> or <code>package</code>. <p> This corresponds to the javac and JVM --add-opens= flags.   | List of strings | optional |  `None`  |
| <a id="arxml_patch-allow_beta"></a>allow_beta |  Whether to allow usage of beta PAI APIs.   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="arxml_patch-bootclasspath"></a>bootclasspath |  Restricted API, do not use!   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="arxml_patch-call"></a>call |  The task call. Must be self-contained (i.e. not requiring any imports). E.g.: call a zero-argument public static void method using a fully qualified class name.   | String | required |  |
| <a id="arxml_patch-exported_plugins"></a>exported_plugins |  The list of <code><a href="#${link java_plugin}">java_plugin</a></code>s (e.g. annotation processors) to export to libraries that directly depend on this library. <p>   The specified list of <code>java_plugin</code>s will be applied to any library which   directly depends on this library, just as if that library had explicitly declared these   labels in <code><a href="${link java_library.plugins}">plugins</a></code>. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="arxml_patch-exports"></a>exports |  Exported libraries. <p>   Listing rules here will make them available to parent rules, as if the parents explicitly   depended on these rules. This is not true for regular (non-exported) <code>deps</code>. </p> <p>   Summary: a rule <i>X</i> can access the code in <i>Y</i> if there exists a dependency   path between them that begins with a <code>deps</code> edge followed by zero or more   <code>exports</code> edges. Let's see some examples to illustrate this. </p> <p>   Assume <i>A</i> depends on <i>B</i> and <i>B</i> depends on <i>C</i>. In this case   C is a <em>transitive</em> dependency of A, so changing C's sources and rebuilding A will   correctly rebuild everything. However A will not be able to use classes in C. To allow   that, either A has to declare C in its <code>deps</code>, or B can make it easier for A   (and anything that may depend on A) by declaring C in its (B's) <code>exports</code>   attribute. </p> <p>   The closure of exported libraries is available to all direct parent rules. Take a slightly   different example: A depends on B, B depends on C and D, and also exports C but not D.   Now A has access to C but not to D. Now, if C and D exported some libraries, C' and D'   respectively, A could only access C' but not D'. </p> <p>   Important: an exported rule is not a regular dependency. Sticking to the previous example,   if B exports C and wants to also use C, it has to also list it in its own   <code>deps</code>. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="arxml_patch-javabuilder_jvm_flags"></a>javabuilder_jvm_flags |  Restricted API, do not use!   | List of strings | optional |  `None`  |
| <a id="arxml_patch-javacopts"></a>javacopts |  Extra compiler options for this library. Subject to <a href="make-variables.html">"Make variable"</a> substitution and <a href="common-definitions.html#sh-tokenization">Bourne shell tokenization</a>. <p>These compiler options are passed to javac after the global compiler options.</p>   | List of strings | optional |  `None`  |
| <a id="arxml_patch-licenses"></a>licenses |  -   | List of strings | optional |  `None`  |
| <a id="arxml_patch-neverlink"></a>neverlink |  Whether this library should only be used for compilation and not at runtime. Useful if the library will be provided by the runtime environment during execution. Examples of such libraries are the IDE APIs for IDE plug-ins or <code>tools.jar</code> for anything running on a standard JDK. <p>   Note that <code>neverlink = True</code> does not prevent the compiler from inlining material   from this library into compilation targets that depend on it, as permitted by the Java   Language Specification (e.g., <code>static final</code> constants of <code>String</code>   or of primitive types). The preferred use case is therefore when the runtime library is   identical to the compilation library. </p> <p>   If the runtime library differs from the compilation library then you must ensure that it   differs only in places that the JLS forbids compilers to inline (and that must hold for   all future versions of the JLS). </p>   | Boolean | optional |  `None`  |
| <a id="arxml_patch-pai_version"></a>pai_version |  -   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="arxml_patch-plugins"></a>plugins |  Java compiler plugins to run at compile-time. Every <code>java_plugin</code> specified in this attribute will be run whenever this rule is built. A library may also inherit plugins from dependencies that use <code><a href="#java_library.exported_plugins">exported_plugins</a></code>. Resources generated by the plugin will be included in the resulting jar of this rule.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="arxml_patch-proguard_specs"></a>proguard_specs |  Files to be used as Proguard specification. These will describe the set of specifications to be used by Proguard. If specified, they will be added to any <code>android_binary</code> target depending on this library.<br><br>The files included here must only have idempotent rules, namely -dontnote, -dontwarn, assumenosideeffects, and rules that start with -keep. Other options can only appear in <code>android_binary</code>'s proguard_specs, to ensure non-tautological merges.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="arxml_patch-resource_strip_prefix"></a>resource_strip_prefix |  The path prefix to strip from Java resources. <p> If specified, this path prefix is stripped from every file in the <code>resources</code> attribute. It is an error for a resource file not to be under this directory. If not specified (the default), the path of resource file is determined according to the same logic as the Java package of source files. For example, a source file at <code>stuff/java/foo/bar/a.txt</code> will be located at <code>foo/bar/a.txt</code>. </p>   | String | optional |  `None`  |
| <a id="arxml_patch-runtime_deps"></a>runtime_deps |  Libraries to make available to the final binary or test at runtime only. Like ordinary <code>deps</code>, these will appear on the runtime classpath, but unlike them, not on the compile-time classpath. Dependencies needed only at runtime should be listed here. Dependency-analysis tools should ignore targets that appear in both <code>runtime_deps</code> and <code>deps</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="arxml_patch-tags"></a>tags |  [Inherited rule attribute](https://bazel.build/reference/be/common-definitions#common-attributes)   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="arxml_patch-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="copy_files"></a>

## copy_files

<pre>
load("@rules_cfg6//:defs.bzl", "copy_files")

copy_files(*, <a href="#copy_files-name">name</a>, <a href="#copy_files-aspect_hints">aspect_hints</a>, <a href="#copy_files-compatible_with">compatible_with</a>, <a href="#copy_files-deprecation">deprecation</a>, <a href="#copy_files-env">env</a>, <a href="#copy_files-exec_compatible_with">exec_compatible_with</a>,
           <a href="#copy_files-exec_group_compatible_with">exec_group_compatible_with</a>, <a href="#copy_files-exec_properties">exec_properties</a>, <a href="#copy_files-features">features</a>, <a href="#copy_files-from_to">from_to</a>, <a href="#copy_files-package_metadata">package_metadata</a>,
           <a href="#copy_files-restricted_to">restricted_to</a>, <a href="#copy_files-tags">tags</a>, <a href="#copy_files-target_compatible_with">target_compatible_with</a>, <a href="#copy_files-testonly">testonly</a>, <a href="#copy_files-toolchains">toolchains</a>, <a href="#copy_files-visibility">visibility</a>)
</pre>

Copy files/folders (e.g. build results) to the workspace or any other location.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="copy_files-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="copy_files-aspect_hints"></a>aspect_hints |  <a href="https://bazel.build/reference/be/common-definitions#common.aspect_hints">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="copy_files-compatible_with"></a>compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="copy_files-deprecation"></a>deprecation |  <a href="https://bazel.build/reference/be/common-definitions#common.deprecation">Inherited rule attribute</a>   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="copy_files-env"></a>env |  Optional environment variables.   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `None`  |
| <a id="copy_files-exec_compatible_with"></a>exec_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="copy_files-exec_group_compatible_with"></a>exec_group_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_group_compatible_with">Inherited rule attribute</a>   | Dictionary: String -> List of labels; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="copy_files-exec_properties"></a>exec_properties |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_properties">Inherited rule attribute</a>   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `None`  |
| <a id="copy_files-features"></a>features |  <a href="https://bazel.build/reference/be/common-definitions#common.features">Inherited rule attribute</a>   | List of strings | optional |  `None`  |
| <a id="copy_files-from_to"></a>from_to |  Files/folders to copy (label -> destination). E.g.:<br><br><pre><code class="language-starlark">files = {&#10;    ":file": "destination/file.txt",        # file -&gt; to given path&#10;    ":file": "destination/",                # file -&gt; into given folder&#10;    ":folder": "destination/",              # folder -&gt; into given folder (yields gen/&lt;folder name&gt;)&#10;    ":folder": "destination",               # folder -&gt; to given path&#10;}</code></pre><br><br>- A destination ending with `/` denotes a folder to copy into, otherwise the path of the file/folder to create (requires the label to provide a single file/folder). - Relative destinations are resolved relative to the workspace root. - Existing destination files are overwritten, existing destination folders are merged.   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: Label -> String</a> | required |  |
| <a id="copy_files-package_metadata"></a>package_metadata |  <a href="https://bazel.build/reference/be/common-definitions#common.package_metadata">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="copy_files-restricted_to"></a>restricted_to |  <a href="https://bazel.build/reference/be/common-definitions#common.restricted_to">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="copy_files-tags"></a>tags |  <a href="https://bazel.build/reference/be/common-definitions#common.tags">Inherited rule attribute</a>   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="copy_files-target_compatible_with"></a>target_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.target_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="copy_files-testonly"></a>testonly |  <a href="https://bazel.build/reference/be/common-definitions#common.testonly">Inherited rule attribute</a>   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="copy_files-toolchains"></a>toolchains |  <a href="https://bazel.build/reference/be/common-definitions#common.toolchains">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="copy_files-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="dvjson"></a>

## dvjson

<pre>
load("@rules_cfg6//:defs.bzl", "dvjson")

dvjson(*, <a href="#dvjson-name">name</a>, <a href="#dvjson-bsw_pkg">bsw_pkg</a>, <a href="#dvjson-visibility">visibility</a>)
</pre>

Macro for declaring a DaVinci project.

Best instantiated within an otherwise empty package, like this:

```starlark
load("@rules_cfg6//:defs.bzl", "dvjson")
dvjson(
    name = "myecu",
    bsw_pkg = "@sip_myecu//:bsw_pkg",
)
```

Now `bazel run //:myecu` will create a new project
See [hybrid](#hybrid) on how to use this project in the pipeline.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="dvjson-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="dvjson-bsw_pkg"></a>bsw_pkg |  The BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="dvjson-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="extract_evs"></a>

## extract_evs

<pre>
load("@rules_cfg6//:defs.bzl", "extract_evs")

extract_evs(*, <a href="#extract_evs-name">name</a>, <a href="#extract_evs-srcs">srcs</a>, <a href="#extract_evs-pai">pai</a>, <a href="#extract_evs-pai_version">pai_version</a>, <a href="#extract_evs-short_name_path">short_name_path</a>, <a href="#extract_evs-visibility">visibility</a>)
</pre>

Internal macro for extracting a single EvaluatedVariantSet from an .arxml file containing multiple EvaluatedVariantSets.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="extract_evs-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="extract_evs-srcs"></a>srcs |  The .arxml files to be patched.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `["@rules_cfg6//:empty.arxml"]`  |
| <a id="extract_evs-pai"></a>pai |  -   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="extract_evs-pai_version"></a>pai_version |  -   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="extract_evs-short_name_path"></a>short_name_path |  The short name path of the EvaluatedVariantSet to extract.   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="extract_evs-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="generate_foundation_layer"></a>

## generate_foundation_layer

<pre>
load("@rules_cfg6//:defs.bzl", "generate_foundation_layer")

generate_foundation_layer(*, <a href="#generate_foundation_layer-name">name</a>, <a href="#generate_foundation_layer-aspect_hints">aspect_hints</a>, <a href="#generate_foundation_layer-bsw_pkg">bsw_pkg</a>, <a href="#generate_foundation_layer-compatible_with">compatible_with</a>, <a href="#generate_foundation_layer-deprecation">deprecation</a>,
                          <a href="#generate_foundation_layer-exec_compatible_with">exec_compatible_with</a>, <a href="#generate_foundation_layer-exec_group_compatible_with">exec_group_compatible_with</a>, <a href="#generate_foundation_layer-exec_properties">exec_properties</a>, <a href="#generate_foundation_layer-features">features</a>,
                          <a href="#generate_foundation_layer-filter">filter</a>, <a href="#generate_foundation_layer-output">output</a>, <a href="#generate_foundation_layer-package_metadata">package_metadata</a>, <a href="#generate_foundation_layer-restricted_to">restricted_to</a>, <a href="#generate_foundation_layer-tags">tags</a>,
                          <a href="#generate_foundation_layer-target_compatible_with">target_compatible_with</a>, <a href="#generate_foundation_layer-testonly">testonly</a>, <a href="#generate_foundation_layer-toolchains">toolchains</a>, <a href="#generate_foundation_layer-visibility">visibility</a>)
</pre>

Rule for generating the foundation layer API sources.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="generate_foundation_layer-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="generate_foundation_layer-aspect_hints"></a>aspect_hints |  <a href="https://bazel.build/reference/be/common-definitions#common.aspect_hints">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="generate_foundation_layer-bsw_pkg"></a>bsw_pkg |  The BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="generate_foundation_layer-compatible_with"></a>compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="generate_foundation_layer-deprecation"></a>deprecation |  <a href="https://bazel.build/reference/be/common-definitions#common.deprecation">Inherited rule attribute</a>   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="generate_foundation_layer-exec_compatible_with"></a>exec_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="generate_foundation_layer-exec_group_compatible_with"></a>exec_group_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_group_compatible_with">Inherited rule attribute</a>   | Dictionary: String -> List of labels; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="generate_foundation_layer-exec_properties"></a>exec_properties |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_properties">Inherited rule attribute</a>   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `None`  |
| <a id="generate_foundation_layer-features"></a>features |  <a href="https://bazel.build/reference/be/common-definitions#common.features">Inherited rule attribute</a>   | List of strings | optional |  `None`  |
| <a id="generate_foundation_layer-filter"></a>filter |  Optional filter file containing the definition-references of all modules to be generated, separated by newlines. If this is not provided all modules of the BSW package are generated.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="generate_foundation_layer-output"></a>output |  The destination folder for generated sources.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="generate_foundation_layer-package_metadata"></a>package_metadata |  <a href="https://bazel.build/reference/be/common-definitions#common.package_metadata">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="generate_foundation_layer-restricted_to"></a>restricted_to |  <a href="https://bazel.build/reference/be/common-definitions#common.restricted_to">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="generate_foundation_layer-tags"></a>tags |  <a href="https://bazel.build/reference/be/common-definitions#common.tags">Inherited rule attribute</a>   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="generate_foundation_layer-target_compatible_with"></a>target_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.target_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="generate_foundation_layer-testonly"></a>testonly |  <a href="https://bazel.build/reference/be/common-definitions#common.testonly">Inherited rule attribute</a>   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="generate_foundation_layer-toolchains"></a>toolchains |  <a href="https://bazel.build/reference/be/common-definitions#common.toolchains">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="generate_foundation_layer-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="list_project_files"></a>

## list_project_files

<pre>
load("@rules_cfg6//:defs.bzl", "list_project_files")

list_project_files(*, <a href="#list_project_files-name">name</a>, <a href="#list_project_files-aspect_hints">aspect_hints</a>, <a href="#list_project_files-compatible_with">compatible_with</a>, <a href="#list_project_files-deprecation">deprecation</a>, <a href="#list_project_files-exec_compatible_with">exec_compatible_with</a>,
                   <a href="#list_project_files-exec_group_compatible_with">exec_group_compatible_with</a>, <a href="#list_project_files-exec_properties">exec_properties</a>, <a href="#list_project_files-features">features</a>, <a href="#list_project_files-package_metadata">package_metadata</a>, <a href="#list_project_files-project">project</a>,
                   <a href="#list_project_files-restricted_to">restricted_to</a>, <a href="#list_project_files-tags">tags</a>, <a href="#list_project_files-target_compatible_with">target_compatible_with</a>, <a href="#list_project_files-testonly">testonly</a>, <a href="#list_project_files-toolchains">toolchains</a>, <a href="#list_project_files-visibility">visibility</a>)
</pre>

List all files contained in a project (paths relative to the project folder, usable as `path` in [project_file](#project_file)). Run with `bazel run`.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="list_project_files-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="list_project_files-aspect_hints"></a>aspect_hints |  <a href="https://bazel.build/reference/be/common-definitions#common.aspect_hints">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="list_project_files-compatible_with"></a>compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="list_project_files-deprecation"></a>deprecation |  <a href="https://bazel.build/reference/be/common-definitions#common.deprecation">Inherited rule attribute</a>   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="list_project_files-exec_compatible_with"></a>exec_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="list_project_files-exec_group_compatible_with"></a>exec_group_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_group_compatible_with">Inherited rule attribute</a>   | Dictionary: String -> List of labels; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="list_project_files-exec_properties"></a>exec_properties |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_properties">Inherited rule attribute</a>   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `None`  |
| <a id="list_project_files-features"></a>features |  <a href="https://bazel.build/reference/be/common-definitions#common.features">Inherited rule attribute</a>   | List of strings | optional |  `None`  |
| <a id="list_project_files-package_metadata"></a>package_metadata |  <a href="https://bazel.build/reference/be/common-definitions#common.package_metadata">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="list_project_files-project"></a>project |  The project whose files to list.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="list_project_files-restricted_to"></a>restricted_to |  <a href="https://bazel.build/reference/be/common-definitions#common.restricted_to">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="list_project_files-tags"></a>tags |  <a href="https://bazel.build/reference/be/common-definitions#common.tags">Inherited rule attribute</a>   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="list_project_files-target_compatible_with"></a>target_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.target_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="list_project_files-testonly"></a>testonly |  <a href="https://bazel.build/reference/be/common-definitions#common.testonly">Inherited rule attribute</a>   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="list_project_files-toolchains"></a>toolchains |  <a href="https://bazel.build/reference/be/common-definitions#common.toolchains">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="list_project_files-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="merged_arxml"></a>

## merged_arxml

<pre>
load("@rules_cfg6//:defs.bzl", "merged_arxml")

merged_arxml(*, <a href="#merged_arxml-name">name</a>, <a href="#merged_arxml-srcs">srcs</a>, <a href="#merged_arxml-pai">pai</a>, <a href="#merged_arxml-pai_version">pai_version</a>, <a href="#merged_arxml-visibility">visibility</a>)
</pre>

Internal macro for merging .arxml files.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="merged_arxml-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="merged_arxml-srcs"></a>srcs |  The .arxml files to be patched.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `["@rules_cfg6//:empty.arxml"]`  |
| <a id="merged_arxml-pai"></a>pai |  -   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="merged_arxml-pai_version"></a>pai_version |  -   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="merged_arxml-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="open"></a>

## open

<pre>
load("@rules_cfg6//:defs.bzl", "open")

open(*, <a href="#open-name">name</a>, <a href="#open-evo1">evo1</a>, <a href="#open-project">project</a>, <a href="#open-visibility">visibility</a>)
</pre>

Open a project in DaVinci Configurator Classic Version 6.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="open-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="open-evo1"></a>evo1 |  Optional absolute path to a DaVinci Configurator Classic Version 6 Evo1 GUI launcher.   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `""`  |
| <a id="open-project"></a>project |  The project to open.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="open-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="run_command"></a>

## run_command

<pre>
load("@rules_cfg6//:defs.bzl", "run_command")

run_command(*, <a href="#run_command-name">name</a>, <a href="#run_command-aspect_hints">aspect_hints</a>, <a href="#run_command-command">command</a>, <a href="#run_command-compatible_with">compatible_with</a>, <a href="#run_command-deprecation">deprecation</a>, <a href="#run_command-env">env</a>, <a href="#run_command-exec_compatible_with">exec_compatible_with</a>,
            <a href="#run_command-exec_group_compatible_with">exec_group_compatible_with</a>, <a href="#run_command-exec_properties">exec_properties</a>, <a href="#run_command-features">features</a>, <a href="#run_command-inputs">inputs</a>, <a href="#run_command-package_metadata">package_metadata</a>, <a href="#run_command-project">project</a>,
            <a href="#run_command-restricted_to">restricted_to</a>, <a href="#run_command-tags">tags</a>, <a href="#run_command-target_compatible_with">target_compatible_with</a>, <a href="#run_command-testonly">testonly</a>, <a href="#run_command-toolchains">toolchains</a>, <a href="#run_command-visibility">visibility</a>)
</pre>

Run a command on a project (see [here](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/references/cli/index.html) for available commnds).
See [apply_command](#apply_command) for some examples.
When running on an hybrid project, the resulting project is written back to the workspace.
Use `$BUILD_WORKSPACE_DIRECTORY` to specify locations relative to the workspace.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="run_command-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="run_command-aspect_hints"></a>aspect_hints |  <a href="https://bazel.build/reference/be/common-definitions#common.aspect_hints">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="run_command-command"></a>command |  Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell)). Separate multiple CLI calls with newline or semicolon.   | String | required |  |
| <a id="run_command-compatible_with"></a>compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_command-deprecation"></a>deprecation |  <a href="https://bazel.build/reference/be/common-definitions#common.deprecation">Inherited rule attribute</a>   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_command-env"></a>env |  Optional environment variables.   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="run_command-exec_compatible_with"></a>exec_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_command-exec_group_compatible_with"></a>exec_group_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_group_compatible_with">Inherited rule attribute</a>   | Dictionary: String -> List of labels; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_command-exec_properties"></a>exec_properties |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_properties">Inherited rule attribute</a>   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `None`  |
| <a id="run_command-features"></a>features |  <a href="https://bazel.build/reference/be/common-definitions#common.features">Inherited rule attribute</a>   | List of strings | optional |  `None`  |
| <a id="run_command-inputs"></a>inputs |  Inputs used in `command`. The following rules apply:<br><br>- Dictionary keys starting with `-` (minus): `inputs = { "-f": "<label>" }` and `command = "... {-f} ..."` yield a resulting command line like this: `... -f <file1> -f <file2> ...` (i.e., all files are listed with the preceeding switch). - Dictionary keys containing `\|` (pipe): `inputs = { "files\|,": "<label>" }` and `command = "... -f {files} ..."` yield a resulting command line like this: `... -f <file1>,<file2> ...` (i.e, all files are listed, joined by the given separator). - Pipe and separator are optional defaulting to a single space separator, i.e.: `inputs = { "files": "<label>" }` and `command = "import {files}"` yield a resulting command line like this: `import <file1> <file2> ...`.   | Dictionary: String -> Label | optional |  `None`  |
| <a id="run_command-package_metadata"></a>package_metadata |  <a href="https://bazel.build/reference/be/common-definitions#common.package_metadata">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_command-project"></a>project |  The project on which to run the command. Only required if the command needs a project.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="run_command-restricted_to"></a>restricted_to |  <a href="https://bazel.build/reference/be/common-definitions#common.restricted_to">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_command-tags"></a>tags |  -   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="run_command-target_compatible_with"></a>target_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.target_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="run_command-testonly"></a>testonly |  <a href="https://bazel.build/reference/be/common-definitions#common.testonly">Inherited rule attribute</a>   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_command-toolchains"></a>toolchains |  <a href="https://bazel.build/reference/be/common-definitions#common.toolchains">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="run_command-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="script_jar"></a>

## script_jar

<pre>
load("@rules_cfg6//:defs.bzl", "script_jar")

script_jar(*, <a href="#script_jar-name">name</a>, <a href="#script_jar-deps">deps</a>, <a href="#script_jar-srcs">srcs</a>, <a href="#script_jar-data">data</a>, <a href="#script_jar-resources">resources</a>, <a href="#script_jar-add_exports">add_exports</a>, <a href="#script_jar-add_opens">add_opens</a>, <a href="#script_jar-allow_beta">allow_beta</a>, <a href="#script_jar-bootclasspath">bootclasspath</a>,
           <a href="#script_jar-exported_plugins">exported_plugins</a>, <a href="#script_jar-exports">exports</a>, <a href="#script_jar-javabuilder_jvm_flags">javabuilder_jvm_flags</a>, <a href="#script_jar-javacopts">javacopts</a>, <a href="#script_jar-licenses">licenses</a>, <a href="#script_jar-neverlink">neverlink</a>,
           <a href="#script_jar-pai_version">pai_version</a>, <a href="#script_jar-plugins">plugins</a>, <a href="#script_jar-proguard_specs">proguard_specs</a>, <a href="#script_jar-resource_strip_prefix">resource_strip_prefix</a>, <a href="#script_jar-runtime_deps">runtime_deps</a>, <a href="#script_jar-script_classes">script_classes</a>,
           <a href="#script_jar-tags">tags</a>, <a href="#script_jar-visibility">visibility</a>)
</pre>

Internal macro for setting up a PAI project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="script_jar-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="script_jar-deps"></a>deps |  The list of libraries to link into this library. See general comments about <code>deps</code> at <a href="${link common-definitions#typical-attributes}">Typical attributes defined by most build rules</a>. <p>   The jars built by <code>java_library</code> rules listed in <code>deps</code> will be on   the compile-time classpath of this rule. Furthermore the transitive closure of their   <code>deps</code>, <code>runtime_deps</code> and <code>exports</code> will be on the   runtime classpath. </p> <p>   By contrast, targets in the <code>data</code> attribute are included in the runfiles but   on neither the compile-time nor runtime classpath. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-srcs"></a>srcs |  The list of source files that are processed to create the target. This attribute is almost always required; see exceptions below. <p> Source files of type <code>.java</code> are compiled. In case of generated <code>.java</code> files it is generally advisable to put the generating rule's name here instead of the name of the file itself. This not only improves readability but makes the rule more resilient to future changes: if the generating rule generates different files in the future, you only need to fix one place: the <code>outs</code> of the generating rule. You should not list the generating rule in <code>deps</code> because it is a no-op. </p> <p> Source files of type <code>.srcjar</code> are unpacked and compiled. (This is useful if you need to generate a set of <code>.java</code> files with a genrule.) </p> <p> Rules: if the rule (typically <code>genrule</code> or <code>filegroup</code>) generates any of the files listed above, they will be used the same way as described for source files. </p> <p> Source files of type <code>.properties</code> are treated as resources. </p><br><br><p>All other files are ignored, as long as there is at least one file of a file type described above. Otherwise an error is raised.</p><br><br><p> This argument is almost always required, except if you specify the <code>runtime_deps</code> argument. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-data"></a>data |  The list of files needed by this library at runtime. See general comments about <code>data</code> at <a href="${link common-definitions#typical-attributes}">Typical attributes defined by most build rules</a>. <p>   When building a <code>java_library</code>, Bazel doesn't put these files anywhere; if the   <code>data</code> files are generated files then Bazel generates them. When building a   test that depends on this <code>java_library</code> Bazel copies or links the   <code>data</code> files into the runfiles area. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-resources"></a>resources |  A list of data files to include in a Java jar. <p> Resources may be source files or generated files. </p><br><br><p> If resources are specified, they will be bundled in the jar along with the usual <code>.class</code> files produced by compilation. The location of the resources inside of the jar file is determined by the project structure. Bazel first looks for Maven's <a href="https://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html">standard directory layout</a>, (a "src" directory followed by a "resources" directory grandchild). If that is not found, Bazel then looks for the topmost directory named "java" or "javatests" (so, for example, if a resource is at <code>&lt;workspace root&gt;/x/java/y/java/z</code>, the path of the resource will be <code>y/java/z</code>. This heuristic cannot be overridden, however, the <code>resource_strip_prefix</code> attribute can be used to specify a specific alternative directory for resource files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-add_exports"></a>add_exports |  Allow this library to access the given <code>module</code> or <code>package</code>. <p> This corresponds to the javac and JVM --add-exports= flags.   | List of strings | optional |  `[]`  |
| <a id="script_jar-add_opens"></a>add_opens |  Allow this library to reflectively access the given <code>module</code> or <code>package</code>. <p> This corresponds to the javac and JVM --add-opens= flags.   | List of strings | optional |  `[]`  |
| <a id="script_jar-allow_beta"></a>allow_beta |  Whether to allow usage of beta PAI APIs.   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="script_jar-bootclasspath"></a>bootclasspath |  Restricted API, do not use!   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="script_jar-exported_plugins"></a>exported_plugins |  The list of <code><a href="#${link java_plugin}">java_plugin</a></code>s (e.g. annotation processors) to export to libraries that directly depend on this library. <p>   The specified list of <code>java_plugin</code>s will be applied to any library which   directly depends on this library, just as if that library had explicitly declared these   labels in <code><a href="${link java_library.plugins}">plugins</a></code>. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-exports"></a>exports |  Exported libraries. <p>   Listing rules here will make them available to parent rules, as if the parents explicitly   depended on these rules. This is not true for regular (non-exported) <code>deps</code>. </p> <p>   Summary: a rule <i>X</i> can access the code in <i>Y</i> if there exists a dependency   path between them that begins with a <code>deps</code> edge followed by zero or more   <code>exports</code> edges. Let's see some examples to illustrate this. </p> <p>   Assume <i>A</i> depends on <i>B</i> and <i>B</i> depends on <i>C</i>. In this case   C is a <em>transitive</em> dependency of A, so changing C's sources and rebuilding A will   correctly rebuild everything. However A will not be able to use classes in C. To allow   that, either A has to declare C in its <code>deps</code>, or B can make it easier for A   (and anything that may depend on A) by declaring C in its (B's) <code>exports</code>   attribute. </p> <p>   The closure of exported libraries is available to all direct parent rules. Take a slightly   different example: A depends on B, B depends on C and D, and also exports C but not D.   Now A has access to C but not to D. Now, if C and D exported some libraries, C' and D'   respectively, A could only access C' but not D'. </p> <p>   Important: an exported rule is not a regular dependency. Sticking to the previous example,   if B exports C and wants to also use C, it has to also list it in its own   <code>deps</code>. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-javabuilder_jvm_flags"></a>javabuilder_jvm_flags |  Restricted API, do not use!   | List of strings | optional |  `[]`  |
| <a id="script_jar-javacopts"></a>javacopts |  Extra compiler options for this library. Subject to <a href="make-variables.html">"Make variable"</a> substitution and <a href="common-definitions.html#sh-tokenization">Bourne shell tokenization</a>. <p>These compiler options are passed to javac after the global compiler options.</p>   | List of strings | optional |  `[]`  |
| <a id="script_jar-licenses"></a>licenses |  -   | List of strings | optional |  `[]`  |
| <a id="script_jar-neverlink"></a>neverlink |  Whether this library should only be used for compilation and not at runtime. Useful if the library will be provided by the runtime environment during execution. Examples of such libraries are the IDE APIs for IDE plug-ins or <code>tools.jar</code> for anything running on a standard JDK. <p>   Note that <code>neverlink = True</code> does not prevent the compiler from inlining material   from this library into compilation targets that depend on it, as permitted by the Java   Language Specification (e.g., <code>static final</code> constants of <code>String</code>   or of primitive types). The preferred use case is therefore when the runtime library is   identical to the compilation library. </p> <p>   If the runtime library differs from the compilation library then you must ensure that it   differs only in places that the JLS forbids compilers to inline (and that must hold for   all future versions of the JLS). </p>   | Boolean | optional |  `False`  |
| <a id="script_jar-pai_version"></a>pai_version |  -   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="script_jar-plugins"></a>plugins |  Java compiler plugins to run at compile-time. Every <code>java_plugin</code> specified in this attribute will be run whenever this rule is built. A library may also inherit plugins from dependencies that use <code><a href="#java_library.exported_plugins">exported_plugins</a></code>. Resources generated by the plugin will be included in the resulting jar of this rule.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-proguard_specs"></a>proguard_specs |  Files to be used as Proguard specification. These will describe the set of specifications to be used by Proguard. If specified, they will be added to any <code>android_binary</code> target depending on this library.<br><br>The files included here must only have idempotent rules, namely -dontnote, -dontwarn, assumenosideeffects, and rules that start with -keep. Other options can only appear in <code>android_binary</code>'s proguard_specs, to ensure non-tautological merges.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-resource_strip_prefix"></a>resource_strip_prefix |  The path prefix to strip from Java resources. <p> If specified, this path prefix is stripped from every file in the <code>resources</code> attribute. It is an error for a resource file not to be under this directory. If not specified (the default), the path of resource file is determined according to the same logic as the Java package of source files. For example, a source file at <code>stuff/java/foo/bar/a.txt</code> will be located at <code>foo/bar/a.txt</code>. </p>   | String | optional |  `""`  |
| <a id="script_jar-runtime_deps"></a>runtime_deps |  Libraries to make available to the final binary or test at runtime only. Like ordinary <code>deps</code>, these will appear on the runtime classpath, but unlike them, not on the compile-time classpath. Dependencies needed only at runtime should be listed here. Dependency-analysis tools should ignore targets that appear in both <code>runtime_deps</code> and <code>deps</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-script_classes"></a>script_classes |  ScriptFactory class names.   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="script_jar-tags"></a>tags |  [Inherited rule attribute](https://bazel.build/reference/be/common-definitions#common-attributes)   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="script_jar-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="cfg6_archive"></a>

## cfg6_archive

<pre>
load("@rules_cfg6//:defs.bzl", "cfg6_archive")

cfg6_archive(<a href="#cfg6_archive-name">name</a>, <a href="#cfg6_archive-auth_patterns">auth_patterns</a>, <a href="#cfg6_archive-nupkg_auth_patterns">nupkg_auth_patterns</a>, <a href="#cfg6_archive-nupkg_sha256">nupkg_sha256</a>, <a href="#cfg6_archive-nupkg_url">nupkg_url</a>, <a href="#cfg6_archive-sha256">sha256</a>, <a href="#cfg6_archive-url">url</a>)
</pre>

Rule for using a DaVinci Configurator Classic Version 6 .nupkg or .deb archive. Use a locally installed DaVinci Configurator Classic Version 6 with `--repo_env=LOCAL_DVCFG6='<path>'`.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cfg6_archive-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cfg6_archive-auth_patterns"></a>auth_patterns |  Authorization patterns (see [http_archive](https://bazel.build/rules/lib/repo/http#http_archive-auth_patterns)).   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="cfg6_archive-nupkg_auth_patterns"></a>nupkg_auth_patterns |  Authorization patterns (see [http_archive](https://bazel.build/rules/lib/repo/http#http_archive-auth_patterns)).   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="cfg6_archive-nupkg_sha256"></a>nupkg_sha256 |  SHA256 checksum of the .nupkg archive.   | String | optional |  `""`  |
| <a id="cfg6_archive-nupkg_url"></a>nupkg_url |  URL of the .nupkg archive. Mutually exclusive with `url`.   | String | optional |  `""`  |
| <a id="cfg6_archive-sha256"></a>sha256 |  SHA256 checksum of the .deb archive.   | String | optional |  `""`  |
| <a id="cfg6_archive-url"></a>url |  URL of the .deb archive. Mutually exclusive with `nupkg_url`.   | String | optional |  `""`  |


<a id="local_cfg6"></a>

## local_cfg6

<pre>
load("@rules_cfg6//:defs.bzl", "local_cfg6")

local_cfg6(<a href="#local_cfg6-name">name</a>, <a href="#local_cfg6-path">path</a>)
</pre>

Rule for using a local DaVinci Configurator Classic Version 6 installation.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="local_cfg6-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="local_cfg6-path"></a>path |  Path (absolute or relative to workspace root) of the dvcfg install folder.   | String | required |  |


