<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# rules_cfg6 v1.0.2

```starlark
bazep_dep(name = "rules_cfg6", version = "1.0.2")
```
Bazel ruleset for working with [DaVinci Configurator Classic Version 6](https://help.vector.com/davinci-configurator-classic/en/current/dvcfg-classic/6.2-SP0/index.html).

<a id="as_code"></a>

## as_code

<pre>
load("@rules_cfg6", "as_code")

as_code(<a href="#as_code-name">name</a>, <a href="#as_code-bsw_pkg">bsw_pkg</a>, <a href="#as_code-dvjson">dvjson</a>, <a href="#as_code-jars">jars</a>, <a href="#as_code-upstream">upstream</a>)
</pre>

Internal rule for adding EaC logic to the DaVinci project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="as_code-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="as_code-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="as_code-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="as_code-jars"></a>jars |  The EaC .jar files (see <a href="#as_code_eac">as_code_eac</a>).   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="as_code-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="as_code_eac"></a>

## as_code_eac

<pre>
load("@rules_cfg6", "as_code_eac")

as_code_eac(<a href="#as_code_eac-name">name</a>, <a href="#as_code_eac-jar">jar</a>)
</pre>

Rule for marking up a .jar for EaC usage.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="as_code_eac-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="as_code_eac-jar"></a>jar |  The EaC .jar file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="derive_ecuc"></a>

## derive_ecuc

<pre>
load("@rules_cfg6", "derive_ecuc")

derive_ecuc(<a href="#derive_ecuc-name">name</a>, <a href="#derive_ecuc-bsw_pkg">bsw_pkg</a>, <a href="#derive_ecuc-dvjson">dvjson</a>, <a href="#derive_ecuc-extract">extract</a>, <a href="#derive_ecuc-upstream">upstream</a>)
</pre>

Internal rule for adding an ECU extract to the DaVinci project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="derive_ecuc-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="derive_ecuc-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="derive_ecuc-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="derive_ecuc-extract"></a>extract |  The .arxml files containing the ECU extract.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="derive_ecuc-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="export_flat_extract"></a>

## export_flat_extract

<pre>
load("@rules_cfg6", "export_flat_extract")

export_flat_extract(<a href="#export_flat_extract-name">name</a>, <a href="#export_flat_extract-args">args</a>, <a href="#export_flat_extract-binding_time">binding_time</a>, <a href="#export_flat_extract-bsw_pkg">bsw_pkg</a>, <a href="#export_flat_extract-dvjson">dvjson</a>, <a href="#export_flat_extract-exporters">exporters</a>, <a href="#export_flat_extract-split_post_build_variants">split_post_build_variants</a>,
                    <a href="#export_flat_extract-split_pre_build_variants">split_pre_build_variants</a>, <a href="#export_flat_extract-upstream">upstream</a>)
</pre>

Rule for exporting a flat ECU extract from the DaVinci project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="export_flat_extract-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="export_flat_extract-args"></a>args |  Exporter-specific arguments.   | List of strings | optional |  `[]`  |
| <a id="export_flat_extract-binding_time"></a>binding_time |  Binding time to use for the export.   | String | optional |  `""`  |
| <a id="export_flat_extract-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="export_flat_extract-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="export_flat_extract-exporters"></a>exporters |  Exporter IDs. A list of all IDs is available via the `export list` command of the DaVinci Configurator Classic CLI.   | List of strings | required |  |
| <a id="export_flat_extract-split_post_build_variants"></a>split_post_build_variants |  Generate separate output for each post-build variant.   | Boolean | optional |  `False`  |
| <a id="export_flat_extract-split_pre_build_variants"></a>split_pre_build_variants |  Generate separate output for each pre-build variant.   | Boolean | optional |  `False`  |
| <a id="export_flat_extract-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="generate"></a>

## generate

<pre>
load("@rules_cfg6", "generate")

generate(<a href="#generate-name">name</a>, <a href="#generate-bsw_pkg">bsw_pkg</a>, <a href="#generate-dvjson">dvjson</a>, <a href="#generate-excluded">excluded</a>, <a href="#generate-ext_steps">ext_steps</a>, <a href="#generate-keep_tmp_files">keep_tmp_files</a>, <a href="#generate-modules">modules</a>, <a href="#generate-no_save">no_save</a>,
         <a href="#generate-skip_up_to_date_checks">skip_up_to_date_checks</a>, <a href="#generate-type">type</a>, <a href="#generate-upstream">upstream</a>)
</pre>

Rule for generating the BSW code.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="generate-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="generate-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="generate-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="generate-excluded"></a>excluded |  Modules to exclude from generation, given either by definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte").   | List of strings | optional |  `[]`  |
| <a id="generate-ext_steps"></a>ext_steps |  External generation steps to execute, given by name. Defaults to executing all steps.   | List of strings | optional |  `[]`  |
| <a id="generate-keep_tmp_files"></a>keep_tmp_files |  Keep temporary files created during generation.   | Boolean | optional |  `False`  |
| <a id="generate-modules"></a>modules |  Modules to generate, given either by definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte"). Defaults to generating all modules.   | List of strings | optional |  `[]`  |
| <a id="generate-no_save"></a>no_save |  Prevent saving the project to disk.   | Boolean | optional |  `False`  |
| <a id="generate-skip_up_to_date_checks"></a>skip_up_to_date_checks |  Run validation and generation without performing up-to-date checks.   | Boolean | optional |  `False`  |
| <a id="generate-type"></a>type |  Generation target ("REAL" or "VTT").   | String | optional |  `""`  |
| <a id="generate-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="generate_bswmd_model"></a>

## generate_bswmd_model

<pre>
load("@rules_cfg6", "generate_bswmd_model")

generate_bswmd_model(<a href="#generate_bswmd_model-name">name</a>, <a href="#generate_bswmd_model-bsw_pkg">bsw_pkg</a>)
</pre>

Internal rule for generating the BSWMD model API.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="generate_bswmd_model-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="generate_bswmd_model-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="generate_swct"></a>

## generate_swct

<pre>
load("@rules_cfg6", "generate_swct")

generate_swct(<a href="#generate_swct-name">name</a>, <a href="#generate_swct-args">args</a>, <a href="#generate_swct-bsw_pkg">bsw_pkg</a>, <a href="#generate_swct-components">components</a>, <a href="#generate_swct-dvjson">dvjson</a>, <a href="#generate_swct-keep_tmp_files">keep_tmp_files</a>, <a href="#generate_swct-no_save">no_save</a>, <a href="#generate_swct-upstream">upstream</a>)
</pre>

Rule for generating SWC templates and contract phase headers.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="generate_swct-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="generate_swct-args"></a>args |  Arguments for certain generators given in the form "<module>:<arg>" where <module> is a module definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte").   | List of strings | optional |  `[]`  |
| <a id="generate_swct-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="generate_swct-components"></a>components |  Software components for which a template and/or contract phase header will be generated, given by name specified in the project settings.   | List of strings | optional |  `[]`  |
| <a id="generate_swct-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="generate_swct-keep_tmp_files"></a>keep_tmp_files |  Keep temporary files created during generation.   | Boolean | optional |  `False`  |
| <a id="generate_swct-no_save"></a>no_save |  Prevent saving the project to disk.   | Boolean | optional |  `False`  |
| <a id="generate_swct-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="import_diag_modules"></a>

## import_diag_modules

<pre>
load("@rules_cfg6", "import_diag_modules")

import_diag_modules(<a href="#import_diag_modules-name">name</a>, <a href="#import_diag_modules-bsw_pkg">bsw_pkg</a>, <a href="#import_diag_modules-dvjson">dvjson</a>, <a href="#import_diag_modules-modules">modules</a>, <a href="#import_diag_modules-upstream">upstream</a>)
</pre>

Rule for importing diagnostic module configurations into the DaVinci project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="import_diag_modules-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="import_diag_modules-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="import_diag_modules-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="import_diag_modules-modules"></a>modules |  The .arxml files containing the diagnostic module configurations.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="import_diag_modules-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="import_evs"></a>

## import_evs

<pre>
load("@rules_cfg6", "import_evs")

import_evs(<a href="#import_evs-name">name</a>, <a href="#import_evs-bsw_pkg">bsw_pkg</a>, <a href="#import_evs-dvjson">dvjson</a>, <a href="#import_evs-evs">evs</a>, <a href="#import_evs-upstream">upstream</a>)
</pre>

Internal rule for adding an EvaluatedVariantSet to the DaVinci project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="import_evs-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="import_evs-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="import_evs-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="import_evs-evs"></a>evs |  The .arxml files containing the EvaluatedVariantSet.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="import_evs-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="import_modules"></a>

## import_modules

<pre>
load("@rules_cfg6", "import_modules")

import_modules(<a href="#import_modules-name">name</a>, <a href="#import_modules-bsw_pkg">bsw_pkg</a>, <a href="#import_modules-dvjson">dvjson</a>, <a href="#import_modules-modules">modules</a>, <a href="#import_modules-upstream">upstream</a>)
</pre>

Rule for importing module configurations into the DaVinci project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="import_modules-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="import_modules-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="import_modules-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="import_modules-modules"></a>modules |  The .arxml files containing the module configurations (use <a href="#replace_modules">replace_modules</a> to import in replace mode).   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="import_modules-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="merged_extract"></a>

## merged_extract

<pre>
load("@rules_cfg6", "merged_extract")

merged_extract(<a href="#merged_extract-name">name</a>, <a href="#merged_extract-srcs">srcs</a>)
</pre>

Rule for merging multiple .arxml files into an ECU extract.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="merged_extract-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="merged_extract-srcs"></a>srcs |  The .arxml files to merge into one ECU extract.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |


<a id="replace_modules"></a>

## replace_modules

<pre>
load("@rules_cfg6", "replace_modules")

replace_modules(<a href="#replace_modules-name">name</a>, <a href="#replace_modules-arxmls">arxmls</a>)
</pre>

Rule for specifying module configurations to be imported in replace mode.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="replace_modules-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="replace_modules-arxmls"></a>arxmls |  The .arxml files containing the module configurations.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |


<a id="run_export"></a>

## run_export

<pre>
load("@rules_cfg6", "run_export")

run_export(<a href="#run_export-name">name</a>, <a href="#run_export-args">args</a>, <a href="#run_export-binding_time">binding_time</a>, <a href="#run_export-bsw_pkg">bsw_pkg</a>, <a href="#run_export-dvjson">dvjson</a>, <a href="#run_export-exporter">exporter</a>, <a href="#run_export-split_post_build_variants">split_post_build_variants</a>,
           <a href="#run_export-split_pre_build_variants">split_pre_build_variants</a>, <a href="#run_export-upstream">upstream</a>)
</pre>

Rule for exporting data from the DaVinci project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="run_export-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="run_export-args"></a>args |  Exporter-specific arguments.   | List of strings | optional |  `[]`  |
| <a id="run_export-binding_time"></a>binding_time |  Binding time to use for the export.   | String | optional |  `""`  |
| <a id="run_export-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="run_export-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="run_export-exporter"></a>exporter |  Exporter ID. A list of all IDs is available via the `export list` command of the DaVinci Configurator Classic CLI.   | String | required |  |
| <a id="run_export-split_post_build_variants"></a>split_post_build_variants |  Generate separate output for each post-build variant.   | Boolean | optional |  `False`  |
| <a id="run_export-split_pre_build_variants"></a>split_pre_build_variants |  Generate separate output for each pre-build variant.   | Boolean | optional |  `False`  |
| <a id="run_export-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="script_patched_arxml"></a>

## script_patched_arxml

<pre>
load("@rules_cfg6", "script_patched_arxml")

script_patched_arxml(<a href="#script_patched_arxml-name">name</a>, <a href="#script_patched_arxml-evs">evs</a>, <a href="#script_patched_arxml-input">input</a>, <a href="#script_patched_arxml-tasks">tasks</a>)
</pre>

Rule for patching an .arxml file by applying a script task.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="script_patched_arxml-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="script_patched_arxml-evs"></a>evs |  The .arxml file containing the EvaluatedVariantSet (required for variant input only).   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="script_patched_arxml-input"></a>input |  The .arxml file to patch.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="script_patched_arxml-tasks"></a>tasks |  The tasks to execute (see <a href="#script_task">script_task</a>).   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |


<a id="script_task"></a>

## script_task

<pre>
load("@rules_cfg6", "script_task")

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


<a id="select_evs"></a>

## select_evs

<pre>
load("@rules_cfg6", "select_evs")

select_evs(<a href="#select_evs-name">name</a>, <a href="#select_evs-arxmls">arxmls</a>, <a href="#select_evs-evs_path">evs_path</a>)
</pre>

Rule for selecting one of multiple EvaluatedVariantSets from the given .arxml files.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="select_evs-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="select_evs-arxmls"></a>arxmls |  The .arxml files containing the EvaluatedVariantSet.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="select_evs-evs_path"></a>evs_path |  Short name path of the EvaluatedVariantSet.   | String | required |  |


<a id="system_extract"></a>

## system_extract

<pre>
load("@rules_cfg6", "system_extract")

system_extract(<a href="#system_extract-name">name</a>, <a href="#system_extract-ecu">ecu</a>, <a href="#system_extract-sysd">sysd</a>)
</pre>

Rule for extracting a given ECU from a system description.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="system_extract-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="system_extract-ecu"></a>ecu |  The ECU to extract from the given system description (defaults to rule name).   | String | optional |  `""`  |
| <a id="system_extract-sysd"></a>sysd |  The system description .arxml file from which to extract the given ECU.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="update_project"></a>

## update_project

<pre>
load("@rules_cfg6", "update_project")

update_project(<a href="#update_project-name">name</a>, <a href="#update_project-bsw_pkg">bsw_pkg</a>, <a href="#update_project-dvjson">dvjson</a>, <a href="#update_project-switches">switches</a>, <a href="#update_project-upstream">upstream</a>)
</pre>

Internal rule for updating the DaVinci project when input files have changed.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="update_project-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="update_project-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="update_project-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="update_project-switches"></a>switches |  String consisting of all switches to apply when running the "project update" command (defaults to "" meaning perform all updates). E.g.: "asr" will only run "automatic reference correction", "solve all" and "RTE config update". The following switches are available:<br/> `a`: Perform automatic correction of unresolved or inconsistent references.<br/> `s`: Perform 'solve all' by executing all recommended solving actions of the project.<br/> `c`: Apply changes from project input files.<br/> `r`: Apply changes to the RTE configuration.<br/> `e`: Apply changes from evaluated variant set.   | String | optional |  `""`  |
| <a id="update_project-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="validate"></a>

## validate

<pre>
load("@rules_cfg6", "validate")

validate(<a href="#validate-name">name</a>, <a href="#validate-bsw_pkg">bsw_pkg</a>, <a href="#validate-dvjson">dvjson</a>, <a href="#validate-upstream">upstream</a>)
</pre>

Rule for validating a DaVinci project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="validate-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="validate-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="validate-dvjson"></a>dvjson |  The .dvjson file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="validate-upstream"></a>upstream |  The upstream pipeline target.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="variant_arxmls"></a>

## variant_arxmls

<pre>
load("@rules_cfg6", "variant_arxmls")

variant_arxmls(<a href="#variant_arxmls-name">name</a>, <a href="#variant_arxmls-arxmls">arxmls</a>, <a href="#variant_arxmls-variant">variant</a>)
</pre>

Rule for specifying which post-build selectable variant the given .arxml files are associated with (e.g.: when <a href="#import_diag_modules">importing diagnostic modules</a>).

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="variant_arxmls-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="variant_arxmls-arxmls"></a>arxmls |  The .arxml files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="variant_arxmls-variant"></a>variant |  The name of the variant.   | String | required |  |


<a id="variant_extract"></a>

## variant_extract

<pre>
load("@rules_cfg6", "variant_extract")

variant_extract(<a href="#variant_extract-name">name</a>, <a href="#variant_extract-config">config</a>, <a href="#variant_extract-evs">evs</a>, <a href="#variant_extract-extracts">extracts</a>)
</pre>

Rule for creating a variant ECU extract from invariant extracts.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="variant_extract-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="variant_extract-config"></a>config |  The merge configuration .xml file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="variant_extract-evs"></a>evs |  The .arxml files containing the EvaluatedVariantSet.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="variant_extract-extracts"></a>extracts |  One extract for each variant in the EvaluatedVariantSet. E.g.: { ":ExtractA": "VariantA", ... }   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | required |  |


<a id="open_configurator"></a>

## open_configurator

<pre>
load("@rules_cfg6", "open_configurator")

open_configurator(*, <a href="#open_configurator-name">name</a>, <a href="#open_configurator-visibility">visibility</a>)
</pre>

Rule for opening a project in DaVinci Configurator Classic Version 6 GUI tool.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="open_configurator-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="open_configurator-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="script_jar"></a>

## script_jar

<pre>
load("@rules_cfg6", "script_jar")

script_jar(*, <a href="#script_jar-name">name</a>, <a href="#script_jar-deps">deps</a>, <a href="#script_jar-srcs">srcs</a>, <a href="#script_jar-data">data</a>, <a href="#script_jar-resources">resources</a>, <a href="#script_jar-add_exports">add_exports</a>, <a href="#script_jar-add_opens">add_opens</a>, <a href="#script_jar-allow_beta_api">allow_beta_api</a>,
           <a href="#script_jar-bootclasspath">bootclasspath</a>, <a href="#script_jar-javacopts">javacopts</a>, <a href="#script_jar-licenses">licenses</a>, <a href="#script_jar-neverlink">neverlink</a>, <a href="#script_jar-pai">pai</a>, <a href="#script_jar-pai_version">pai_version</a>, <a href="#script_jar-plugins">plugins</a>, <a href="#script_jar-runtime_deps">runtime_deps</a>,
           <a href="#script_jar-script_classes">script_classes</a>, <a href="#script_jar-tags">tags</a>, <a href="#script_jar-visibility">visibility</a>)
</pre>

Rule for setting up a PAI project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="script_jar-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="script_jar-deps"></a>deps |  See [Java Rules](https://bazel.build/reference/be/java).   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="script_jar-srcs"></a>srcs |  The list of source files that are processed to create the target. This attribute is almost always required; see exceptions below. <p> Source files of type <code>.java</code> are compiled. In case of generated <code>.java</code> files it is generally advisable to put the generating rule's name here instead of the name of the file itself. This not only improves readability but makes the rule more resilient to future changes: if the generating rule generates different files in the future, you only need to fix one place: the <code>outs</code> of the generating rule. You should not list the generating rule in <code>deps</code> because it is a no-op. </p> <p> Source files of type <code>.srcjar</code> are unpacked and compiled. (This is useful if you need to generate a set of <code>.java</code> files with a genrule.) </p> <p> Rules: if the rule (typically <code>genrule</code> or <code>filegroup</code>) generates any of the files listed above, they will be used the same way as described for source files. </p> <p> Source files of type <code>.properties</code> are treated as resources. </p><br><br><p>All other files are ignored, as long as there is at least one file of a file type described above. Otherwise an error is raised.</p><br><br><p> This argument is almost always required, except if you specify the <code>runtime_deps</code> argument. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-data"></a>data |  The list of files needed by this library at runtime. See general comments about <code>data</code> at <a href="${link common-definitions#typical-attributes}">Typical attributes defined by most build rules</a>. <p>   When building a <code>java_library</code>, Bazel doesn't put these files anywhere; if the   <code>data</code> files are generated files then Bazel generates them. When building a   test that depends on this <code>java_library</code> Bazel copies or links the   <code>data</code> files into the runfiles area. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-resources"></a>resources |  A list of data files to include in a Java jar. <p> Resources may be source files or generated files. </p><br><br><p> If resources are specified, they will be bundled in the jar along with the usual <code>.class</code> files produced by compilation. The location of the resources inside of the jar file is determined by the project structure. Bazel first looks for Maven's <a href="https://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html">standard directory layout</a>, (a "src" directory followed by a "resources" directory grandchild). If that is not found, Bazel then looks for the topmost directory named "java" or "javatests" (so, for example, if a resource is at <code>&lt;workspace root&gt;/x/java/y/java/z</code>, the path of the resource will be <code>y/java/z</code>. This heuristic cannot be overridden, however, the <code>resource_strip_prefix</code> attribute can be used to specify a specific alternative directory for resource files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-add_exports"></a>add_exports |  Allow this library to access the given <code>module</code> or <code>package</code>. <p> This corresponds to the javac and JVM --add-exports= flags.   | List of strings | optional |  `[]`  |
| <a id="script_jar-add_opens"></a>add_opens |  Allow this library to reflectively access the given <code>module</code> or <code>package</code>. <p> This corresponds to the javac and JVM --add-opens= flags.   | List of strings | optional |  `[]`  |
| <a id="script_jar-allow_beta_api"></a>allow_beta_api |  Set to "true" to use beta API.   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `False`  |
| <a id="script_jar-bootclasspath"></a>bootclasspath |  Restricted API, do not use!   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="script_jar-javacopts"></a>javacopts |  Extra compiler options for this library. Subject to <a href="make-variables.html">"Make variable"</a> substitution and <a href="common-definitions.html#sh-tokenization">Bourne shell tokenization</a>. <p>These compiler options are passed to javac after the global compiler options.</p>   | List of strings | optional |  `[]`  |
| <a id="script_jar-licenses"></a>licenses |  -   | List of strings | optional |  `[]`  |
| <a id="script_jar-neverlink"></a>neverlink |  Whether this library should only be used for compilation and not at runtime. Useful if the library will be provided by the runtime environment during execution. Examples of such libraries are the IDE APIs for IDE plug-ins or <code>tools.jar</code> for anything running on a standard JDK. <p>   Note that <code>neverlink = True</code> does not prevent the compiler from inlining material   from this library into compilation targets that depend on it, as permitted by the Java   Language Specification (e.g., <code>static final</code> constants of <code>String</code>   or of primitive types). The preferred use case is therefore when the runtime library is   identical to the compilation library. </p> <p>   If the runtime library differs from the compilation library then you must ensure that it   differs only in places that the JLS forbids compilers to inline (and that must hold for   all future versions of the JLS). </p>   | Boolean | optional |  `False`  |
| <a id="script_jar-pai"></a>pai |  PAI libs target.   | <a href="https://bazel.build/concepts/labels">Label</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="script_jar-pai_version"></a>pai_version |  PAI version.   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="script_jar-plugins"></a>plugins |  Java compiler plugins to run at compile-time. Every <code>java_plugin</code> specified in this attribute will be run whenever this rule is built. A library may also inherit plugins from dependencies that use <code><a href="#java_library.exported_plugins">exported_plugins</a></code>. Resources generated by the plugin will be included in the resulting jar of this rule.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-runtime_deps"></a>runtime_deps |  Libraries to make available to the final binary or test at runtime only. Like ordinary <code>deps</code>, these will appear on the runtime classpath, but unlike them, not on the compile-time classpath. Dependencies needed only at runtime should be listed here. Dependency-analysis tools should ignore targets that appear in both <code>runtime_deps</code> and <code>deps</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="script_jar-script_classes"></a>script_classes |  ScriptFactory class names.   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | required |  |
| <a id="script_jar-tags"></a>tags |  See [common attributes](https://bazel.build/reference/be/common-definitions#common-attributes).   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="script_jar-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="cfg6_archive"></a>

## cfg6_archive

<pre>
load("@rules_cfg6", "cfg6_archive")

cfg6_archive(<a href="#cfg6_archive-name">name</a>, <a href="#cfg6_archive-sha256">sha256</a>, <a href="#cfg6_archive-url">url</a>)
</pre>

Internal rule for using a DaVinci Configurator Classic Version 6 .nupkg or .deb archive.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cfg6_archive-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cfg6_archive-sha256"></a>sha256 |  SHA256 archive checksum.   | String | optional |  `""`  |
| <a id="cfg6_archive-url"></a>url |  URL of the .deb or .nupkg archive.   | String | required |  |


<a id="local_cfg6"></a>

## local_cfg6

<pre>
load("@rules_cfg6", "local_cfg6")

local_cfg6(<a href="#local_cfg6-name">name</a>, <a href="#local_cfg6-path">path</a>)
</pre>

Internal rule for using a local DaVinci Configurator Classic Version 6 installation.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="local_cfg6-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="local_cfg6-path"></a>path |  Path of the dvcfg install folder.   | String | required |  |


