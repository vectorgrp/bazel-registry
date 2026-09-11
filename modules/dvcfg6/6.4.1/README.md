<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# dvcfg6 v6.4.1

```starlark
bazep_dep(name = "dvcfg6", version = "6.4.1")
```

Bazel dependency to use and download a dedicated [DaVinci Configurator Classic](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/index.html) version.

<a id="ecu_config"></a>

## ecu_config

<pre>
ecu_config = use_extension("@dvcfg6//:ecu_config.bzl", "ecu_config")
ecu_config.project(<a href="#ecu_config.project-name">name</a>, <a href="#ecu_config.project-as_code">as_code</a>, <a href="#ecu_config.project-bsw_pkg">bsw_pkg</a>, <a href="#ecu_config.project-diag_modules">diag_modules</a>, <a href="#ecu_config.project-dvjson">dvjson</a>, <a href="#ecu_config.project-evs">evs</a>, <a href="#ecu_config.project-extract">extract</a>, <a href="#ecu_config.project-modules">modules</a>,
                   <a href="#ecu_config.project-settings_patch_substitutions">settings_patch_substitutions</a>, <a href="#ecu_config.project-settings_patch_template">settings_patch_template</a>, <a href="#ecu_config.project-update_switches">update_switches</a>)
</pre>

Module extension for using DaVinci projects in the Bazel pipeline.


**TAG CLASSES**

<a id="ecu_config.project"></a>

### project

Creates a DaVinci project repo for configuring an ECU and generating the BSW code.

Import the repo with `use_repo(ecu_config, "MyProject")`.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="ecu_config.project-name"></a>name |  The name of the resulting repo.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="ecu_config.project-as_code"></a>as_code |  List of as-code .jar files. Each .jar must be tagged with `as_code_eac`. The .jar files are applied in the order given here.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-bsw_pkg"></a>bsw_pkg |  The BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="ecu_config.project-diag_modules"></a>diag_modules |  Diagnostic module .arxml or .json files to import.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-dvjson"></a>dvjson |  The existing .dvjson file. Mutually exclusive with `settings_patch_template`.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="ecu_config.project-evs"></a>evs |  EvaluatedVariantSet (either one .json file or .arxml files).   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-extract"></a>extract |  ECU extract .arxml files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-modules"></a>modules |  Module .arxml files to import.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-settings_patch_substitutions"></a>settings_patch_substitutions |  Optional substitutions for replacing variables in the `settings_patch_template` with build target file paths. E.g.: Use `{"{{OUTPUT_DIR}}": "//pkg:target"}` to replace the text `{{OUTPUT_DIR}}` in the provided `settings_patch_template` with the path to the file created by building `//pkg:target`.   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="ecu_config.project-settings_patch_template"></a>settings_patch_template |  Optional JSON file for patching project settings. Mutually exclusive with `dvjson`.<br><br>Here is an example for setting `allowMergeConflicts` in the `General.json` file to `true` and removing the mapping for the `Dcm` module from the `moduleDefinitionMappings` array in the `Ifp.json` file:<br><br><pre><code class="language-json">{&#10;  "general": {&#10;    "allowMergeConflicts": true&#10;  },&#10;  "ifp": {&#10;    "moduleDefinitionMappings": [&#10;      { "__delete__": true, "moduleConfigName": "Dcm" }&#10;    ]&#10;  }&#10;}</code></pre><br><br>Each object-typed property is merged into the settings file referenced by the .dvjson file with the corresponding key:<br><br>- Object-typed properties are merged recursively. - Primitive-typed properties are overwritten with the patch value (use `null` to delete the property). - Arrays with primitive-typed elements are merged as duplicate-free unions. - Objects in arrays are identified by a key property:   - In `General.json`, `useCases` are identified by their `vector` property.   - In `Ifp.json`, `moduleDefinitionMappings` are identified by their `moduleConfigName` (see example) and `comControllerMappings` by their `clusterPath`.   - Use the `__delete__` property (see example) to remove an object from the array.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="ecu_config.project-update_switches"></a>update_switches |  String consisting of all switches to apply when running the "project update" command (defaults to "" meaning perform all updates). E.g.: "asr" will only run "automatic reference correction", "solve all" and "RTE config update". The following switches are available:<br/> `a`: Perform automatic correction of unresolved or inconsistent references.<br/> `s`: Perform 'solve all' by executing all recommended solving actions of the project.<br/> `c`: Apply changes from project input files.<br/> `r`: Apply changes to the RTE configuration.<br/> `e`: Apply changes from evaluated variant set.   | String | optional |  `""`  |


