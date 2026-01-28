<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# rules_ecu_config v1.0.3

```starlark
bazep_dep(name = "rules_ecu_config", version = "1.0.3")
```
Bazel ruleset for configuring ECU projects.

<a id="ecu_config"></a>

## ecu_config

<pre>
ecu_config = use_extension("@//:doc/rules_ecu_config_doc.bzl", "ecu_config")
ecu_config.tools(<a href="#ecu_config.tools-cfg6_path">cfg6_path</a>, <a href="#ecu_config.tools-cfg6_sha256">cfg6_sha256</a>, <a href="#ecu_config.tools-cfg6_url">cfg6_url</a>, <a href="#ecu_config.tools-dvarjson_path">dvarjson_path</a>, <a href="#ecu_config.tools-dvarjson_sha256">dvarjson_sha256</a>, <a href="#ecu_config.tools-dvarjson_url">dvarjson_url</a>)
ecu_config.project(<a href="#ecu_config.project-as_code">as_code</a>, <a href="#ecu_config.project-bsw_pkg">bsw_pkg</a>, <a href="#ecu_config.project-creation_file">creation_file</a>, <a href="#ecu_config.project-diag_modules">diag_modules</a>, <a href="#ecu_config.project-dvjson">dvjson</a>, <a href="#ecu_config.project-evs">evs</a>, <a href="#ecu_config.project-extract">extract</a>, <a href="#ecu_config.project-modules">modules</a>,
                   <a href="#ecu_config.project-update_switches">update_switches</a>)
</pre>

Module extension for using a DaVinci project in the Bazel pipeline.


**TAG CLASSES**

<a id="ecu_config.tools"></a>

### tools

DaVinci tools used for ECU configuration.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="ecu_config.tools-cfg6_path"></a>cfg6_path |  Path of the local DaVinci Configurator install folder. Mutually exclusive with `cfg6_url`.   | String | optional |  `""`  |
| <a id="ecu_config.tools-cfg6_sha256"></a>cfg6_sha256 |  Cfg6 SHA256 archive checksum.   | String | optional |  `""`  |
| <a id="ecu_config.tools-cfg6_url"></a>cfg6_url |  URL of the DaVinci Configurator .deb or .nupkg archive. Mutually exclusive with `cfg6_path`.   | String | optional |  `""`  |
| <a id="ecu_config.tools-dvarjson_path"></a>dvarjson_path |  Path of the local dvarjson install folder. Mutually exclusive with `dvarjson_url`.   | String | optional |  `""`  |
| <a id="ecu_config.tools-dvarjson_sha256"></a>dvarjson_sha256 |  dvarjson SHA256 archive checksum.   | String | optional |  `""`  |
| <a id="ecu_config.tools-dvarjson_url"></a>dvarjson_url |  URL of the dvarjson .deb or .nupkg archive. Mutually exclusive with `dvarjson_path`.   | String | optional |  `""`  |

<a id="ecu_config.project"></a>

### project

Creates a DaVinci project for configuring an ECU and generating the BSW code.

To Bazel the project is made available as repo named like the used `dvjson` file or the project name given in the `creation_file`.
E.g., for a file named `MyProject.dvjson` a repo named `MyProject` is created.
Import the repo with `use_repo(ecu_config, "MyProject")`.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="ecu_config.project-as_code"></a>as_code |  List of as-code .jar files. Each .jar must be tagged with `as_code_eac`. The .jar files are applied in the order given here.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-bsw_pkg"></a>bsw_pkg |  The BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="ecu_config.project-creation_file"></a>creation_file |  Project creation file containing general settings. The project name given in this file is taken as repo name. Mutually exclusive with `dvjson`.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="ecu_config.project-diag_modules"></a>diag_modules |  Diagnostic module .arxml or .json files to import.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-dvjson"></a>dvjson |  The existing .dvjson file. This file's name is taken as repo name. Mutually exclusive with `creation_file`.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="ecu_config.project-evs"></a>evs |  EvaluatedVariantSet (either one .json file or .arxml files).   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-extract"></a>extract |  ECU extract .arxml files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-modules"></a>modules |  Module .arxml files to import.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-update_switches"></a>update_switches |  String consisting of all switches to apply when running the "project update" command (defaults to "" meaning perform all updates). E.g.: "asr" will only run "automatic reference correction", "solve all" and "RTE config update". The following switches are available:<br/> `a`: Perform automatic correction of unresolved or inconsistent references.<br/> `s`: Perform 'solve all' by executing all recommended solving actions of the project.<br/> `c`: Apply changes from project input files.<br/> `r`: Apply changes to the RTE configuration.<br/> `e`: Apply changes from evaluated variant set.   | String | optional |  `""`  |


<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# DaVinci Project Repo

The following targets and rules are available from a DaVinci project repo:

- Use `bazel run @MyProject//:open_configurator` to open the project in DaVinci Configurator Classic Version 6.
- Use `bazel build @MyProject//:validate` to validate the project.

<a id="eac_jar"></a>

## eac_jar

<pre>
load("@MyProject", "eac_jar")

eac_jar(*, <a href="#eac_jar-name">name</a>, <a href="#eac_jar-deps">deps</a>, <a href="#eac_jar-srcs">srcs</a>, <a href="#eac_jar-data">data</a>, <a href="#eac_jar-resources">resources</a>, <a href="#eac_jar-add_exports">add_exports</a>, <a href="#eac_jar-add_opens">add_opens</a>, <a href="#eac_jar-allow_beta_api">allow_beta_api</a>, <a href="#eac_jar-bootclasspath">bootclasspath</a>,
        <a href="#eac_jar-javacopts">javacopts</a>, <a href="#eac_jar-licenses">licenses</a>, <a href="#eac_jar-neverlink">neverlink</a>, <a href="#eac_jar-plugins">plugins</a>, <a href="#eac_jar-runtime_deps">runtime_deps</a>, <a href="#eac_jar-tags">tags</a>, <a href="#eac_jar-visibility">visibility</a>)
</pre>

Macro for setting up an EaC project resulting in 3 targets (`<name>` = name provided to the macro):

- `<name>` for use in <a href="#ecu_config.project-as_code">as_code</a>.
- `<name>_jar` for building the actual .jar file containing the EaC logic (required for IDE support).
- `<name>_dbg` for debugging the EaC logic.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="eac_jar-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="eac_jar-deps"></a>deps |  See [Java Rules](https://bazel.build/reference/be/java).   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="eac_jar-srcs"></a>srcs |  The list of source files that are processed to create the target. This attribute is almost always required; see exceptions below. <p> Source files of type <code>.java</code> are compiled. In case of generated <code>.java</code> files it is generally advisable to put the generating rule's name here instead of the name of the file itself. This not only improves readability but makes the rule more resilient to future changes: if the generating rule generates different files in the future, you only need to fix one place: the <code>outs</code> of the generating rule. You should not list the generating rule in <code>deps</code> because it is a no-op. </p> <p> Source files of type <code>.srcjar</code> are unpacked and compiled. (This is useful if you need to generate a set of <code>.java</code> files with a genrule.) </p> <p> Rules: if the rule (typically <code>genrule</code> or <code>filegroup</code>) generates any of the files listed above, they will be used the same way as described for source files. </p> <p> Source files of type <code>.properties</code> are treated as resources. </p><br><br><p>All other files are ignored, as long as there is at least one file of a file type described above. Otherwise an error is raised.</p><br><br><p> This argument is almost always required, except if you specify the <code>runtime_deps</code> argument. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="eac_jar-data"></a>data |  The list of files needed by this library at runtime. See general comments about <code>data</code> at <a href="${link common-definitions#typical-attributes}">Typical attributes defined by most build rules</a>. <p>   When building a <code>java_library</code>, Bazel doesn't put these files anywhere; if the   <code>data</code> files are generated files then Bazel generates them. When building a   test that depends on this <code>java_library</code> Bazel copies or links the   <code>data</code> files into the runfiles area. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="eac_jar-resources"></a>resources |  A list of data files to include in a Java jar. <p> Resources may be source files or generated files. </p><br><br><p> If resources are specified, they will be bundled in the jar along with the usual <code>.class</code> files produced by compilation. The location of the resources inside of the jar file is determined by the project structure. Bazel first looks for Maven's <a href="https://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html">standard directory layout</a>, (a "src" directory followed by a "resources" directory grandchild). If that is not found, Bazel then looks for the topmost directory named "java" or "javatests" (so, for example, if a resource is at <code>&lt;workspace root&gt;/x/java/y/java/z</code>, the path of the resource will be <code>y/java/z</code>. This heuristic cannot be overridden, however, the <code>resource_strip_prefix</code> attribute can be used to specify a specific alternative directory for resource files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="eac_jar-add_exports"></a>add_exports |  Allow this library to access the given <code>module</code> or <code>package</code>. <p> This corresponds to the javac and JVM --add-exports= flags.   | List of strings | optional |  `None`  |
| <a id="eac_jar-add_opens"></a>add_opens |  Allow this library to reflectively access the given <code>module</code> or <code>package</code>. <p> This corresponds to the javac and JVM --add-opens= flags.   | List of strings | optional |  `None`  |
| <a id="eac_jar-allow_beta_api"></a>allow_beta_api |  Set to "true" to use beta API.   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="eac_jar-bootclasspath"></a>bootclasspath |  Restricted API, do not use!   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="eac_jar-javacopts"></a>javacopts |  Extra compiler options for this library. Subject to <a href="make-variables.html">"Make variable"</a> substitution and <a href="common-definitions.html#sh-tokenization">Bourne shell tokenization</a>. <p>These compiler options are passed to javac after the global compiler options.</p>   | List of strings | optional |  `None`  |
| <a id="eac_jar-licenses"></a>licenses |  -   | List of strings | optional |  `None`  |
| <a id="eac_jar-neverlink"></a>neverlink |  Whether this library should only be used for compilation and not at runtime. Useful if the library will be provided by the runtime environment during execution. Examples of such libraries are the IDE APIs for IDE plug-ins or <code>tools.jar</code> for anything running on a standard JDK. <p>   Note that <code>neverlink = True</code> does not prevent the compiler from inlining material   from this library into compilation targets that depend on it, as permitted by the Java   Language Specification (e.g., <code>static final</code> constants of <code>String</code>   or of primitive types). The preferred use case is therefore when the runtime library is   identical to the compilation library. </p> <p>   If the runtime library differs from the compilation library then you must ensure that it   differs only in places that the JLS forbids compilers to inline (and that must hold for   all future versions of the JLS). </p>   | Boolean | optional |  `None`  |
| <a id="eac_jar-plugins"></a>plugins |  See [Java Rules](https://bazel.build/reference/be/java).   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="eac_jar-runtime_deps"></a>runtime_deps |  Libraries to make available to the final binary or test at runtime only. Like ordinary <code>deps</code>, these will appear on the runtime classpath, but unlike them, not on the compile-time classpath. Dependencies needed only at runtime should be listed here. Dependency-analysis tools should ignore targets that appear in both <code>runtime_deps</code> and <code>deps</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="eac_jar-tags"></a>tags |  See [common attributes](https://bazel.build/reference/be/common-definitions#common-attributes).   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="eac_jar-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="export"></a>

## export

<pre>
load("@MyProject", "export")

export(*, <a href="#export-name">name</a>, <a href="#export-args">args</a>, <a href="#export-binding_time">binding_time</a>, <a href="#export-exporter">exporter</a>, <a href="#export-split_post_build_variants">split_post_build_variants</a>, <a href="#export-split_pre_build_variants">split_pre_build_variants</a>,
       <a href="#export-visibility">visibility</a>)
</pre>

Rule for exporting data from the DaVinci project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="export-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="export-args"></a>args |  Exporter-specific arguments.   | List of strings | optional |  `[]`  |
| <a id="export-binding_time"></a>binding_time |  Binding time to use for the export.   | String | optional |  `""`  |
| <a id="export-exporter"></a>exporter |  Exporter ID. A list of all IDs is available via the `export list` command of the DaVinci Configurator Classic CLI.   | String | required |  |
| <a id="export-split_post_build_variants"></a>split_post_build_variants |  Generate separate output for each post-build variant.   | Boolean | optional |  `False`  |
| <a id="export-split_pre_build_variants"></a>split_pre_build_variants |  Generate separate output for each pre-build variant.   | Boolean | optional |  `False`  |
| <a id="export-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="flat_extract"></a>

## flat_extract

<pre>
load("@MyProject", "flat_extract")

flat_extract(*, <a href="#flat_extract-name">name</a>, <a href="#flat_extract-args">args</a>, <a href="#flat_extract-binding_time">binding_time</a>, <a href="#flat_extract-exporters">exporters</a>, <a href="#flat_extract-split_post_build_variants">split_post_build_variants</a>,
             <a href="#flat_extract-split_pre_build_variants">split_pre_build_variants</a>, <a href="#flat_extract-visibility">visibility</a>)
</pre>

Rule for exporting a flat ECU extract from the DaVinci project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="flat_extract-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="flat_extract-args"></a>args |  Exporter-specific arguments.   | List of strings | optional |  `[]`  |
| <a id="flat_extract-binding_time"></a>binding_time |  Binding time to use for the export.   | String | optional |  `""`  |
| <a id="flat_extract-exporters"></a>exporters |  Exporter IDs. A list of all IDs is available via the `export list` command of the DaVinci Configurator Classic CLI.   | List of strings | required |  |
| <a id="flat_extract-split_post_build_variants"></a>split_post_build_variants |  Generate separate output for each post-build variant.   | Boolean | optional |  `False`  |
| <a id="flat_extract-split_pre_build_variants"></a>split_pre_build_variants |  Generate separate output for each pre-build variant.   | Boolean | optional |  `False`  |
| <a id="flat_extract-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="generate"></a>

## generate

<pre>
load("@MyProject", "generate")

generate(*, <a href="#generate-name">name</a>, <a href="#generate-excluded">excluded</a>, <a href="#generate-ext_steps">ext_steps</a>, <a href="#generate-keep_tmp_files">keep_tmp_files</a>, <a href="#generate-modules">modules</a>, <a href="#generate-no_save">no_save</a>, <a href="#generate-skip_up_to_date_checks">skip_up_to_date_checks</a>,
         <a href="#generate-type">type</a>, <a href="#generate-visibility">visibility</a>)
</pre>

Rule for generating the BSW code.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="generate-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="generate-excluded"></a>excluded |  Modules to exclude from generation, given either by definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte").   | List of strings | optional |  `[]`  |
| <a id="generate-ext_steps"></a>ext_steps |  External generation steps to execute, given by name. Defaults to executing all steps.   | List of strings | optional |  `[]`  |
| <a id="generate-keep_tmp_files"></a>keep_tmp_files |  Keep temporary files created during generation.   | Boolean | optional |  `False`  |
| <a id="generate-modules"></a>modules |  Modules to generate, given either by definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte"). Defaults to generating all modules.   | List of strings | optional |  `[]`  |
| <a id="generate-no_save"></a>no_save |  Prevent saving the project to disk.   | Boolean | optional |  `False`  |
| <a id="generate-skip_up_to_date_checks"></a>skip_up_to_date_checks |  Run validation and generation without performing up-to-date checks.   | Boolean | optional |  `False`  |
| <a id="generate-type"></a>type |  Generation target ("REAL" or "VTT").   | String | optional |  `""`  |
| <a id="generate-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="swct"></a>

## swct

<pre>
load("@MyProject", "swct")

swct(*, <a href="#swct-name">name</a>, <a href="#swct-args">args</a>, <a href="#swct-components">components</a>, <a href="#swct-keep_tmp_files">keep_tmp_files</a>, <a href="#swct-no_save">no_save</a>, <a href="#swct-visibility">visibility</a>)
</pre>

Rule for generating SWC templates and contract phase headers.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="swct-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="swct-args"></a>args |  Arguments for certain generators given in the form "<module>:<arg>" where <module> is a module definition (e.g. "/MICROSAR/Rte") or short name (e.g. "Rte").   | List of strings | optional |  `[]`  |
| <a id="swct-components"></a>components |  Software components for which a template and/or contract phase header will be generated, given by name specified in the project settings.   | List of strings | optional |  `[]`  |
| <a id="swct-keep_tmp_files"></a>keep_tmp_files |  Keep temporary files created during generation.   | Boolean | optional |  `False`  |
| <a id="swct-no_save"></a>no_save |  Prevent saving the project to disk.   | Boolean | optional |  `False`  |
| <a id="swct-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


