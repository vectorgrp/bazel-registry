<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# rules_ecu_config v2.1.0

```starlark
bazep_dep(name = "rules_ecu_config", version = "2.1.0")
```
Bazel ruleset for configuring ECU projects.

<a id="ecu_config"></a>

## ecu_config

<pre>
ecu_config = use_extension("@//:doc/rules_ecu_config_doc.bzl", "ecu_config")
ecu_config.project(<a href="#ecu_config.project-name">name</a>, <a href="#ecu_config.project-as_code">as_code</a>, <a href="#ecu_config.project-bsw_pkg">bsw_pkg</a>, <a href="#ecu_config.project-cfg6_defs">cfg6_defs</a>, <a href="#ecu_config.project-creation_file">creation_file</a>, <a href="#ecu_config.project-diag_modules">diag_modules</a>, <a href="#ecu_config.project-dvjson">dvjson</a>, <a href="#ecu_config.project-evs">evs</a>,
                   <a href="#ecu_config.project-extract">extract</a>, <a href="#ecu_config.project-ifp_file">ifp_file</a>, <a href="#ecu_config.project-modules">modules</a>, <a href="#ecu_config.project-project_archive">project_archive</a>, <a href="#ecu_config.project-project_archive_dvjson">project_archive_dvjson</a>,
                   <a href="#ecu_config.project-project_archive_type">project_archive_type</a>, <a href="#ecu_config.project-update_switches">update_switches</a>)
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
| <a id="ecu_config.project-cfg6_defs"></a>cfg6_defs |  The `defs.bzl` file of the DaVinci Configurator Classic Version 6 tool repo.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="ecu_config.project-creation_file"></a>creation_file |  Project creation file containing general settings. Mutually exclusive with `dvjson` and `dvjson_archive_url`.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="ecu_config.project-diag_modules"></a>diag_modules |  Diagnostic module .arxml or .json files to import.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-dvjson"></a>dvjson |  The existing .dvjson file. Mutually exclusive with `creation_file` and `dvjson_archive_url`.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="ecu_config.project-evs"></a>evs |  EvaluatedVariantSet (either one .json file or .arxml files).   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-extract"></a>extract |  ECU extract .arxml files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-ifp_file"></a>ifp_file |  IFP settings .json file for the project. Optional and only used if `creation_file` or `project_archive` are provided.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="ecu_config.project-modules"></a>modules |  Module .arxml files to import.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="ecu_config.project-project_archive"></a>project_archive |  An archive containing the project. Mutually exclusive with `dvjson` and `creation_file`.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="ecu_config.project-project_archive_dvjson"></a>project_archive_dvjson |  The path to the .dvjson file within the project archive.   | String | optional |  `""`  |
| <a id="ecu_config.project-project_archive_type"></a>project_archive_type |  The type of the project archive (see [extract](https://bazel.build/rules/lib/builtins/repository_ctx#extract.type)).   | String | optional |  `""`  |
| <a id="ecu_config.project-update_switches"></a>update_switches |  String consisting of all switches to apply when running the "project update" command (defaults to "" meaning perform all updates). E.g.: "asr" will only run "automatic reference correction", "solve all" and "RTE config update". The following switches are available:<br/> `a`: Perform automatic correction of unresolved or inconsistent references.<br/> `s`: Perform 'solve all' by executing all recommended solving actions of the project.<br/> `c`: Apply changes from project input files.<br/> `r`: Apply changes to the RTE configuration.<br/> `e`: Apply changes from evaluated variant set.   | String | optional |  `""`  |


<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# DaVinci Project Repo

The following targets and rules are available from a DaVinci project repo:

- Use `bazel run @MyProject//:edit_project` to edit the project in DaVinci Configurator Classic Version 6.

<a id="eac_jar"></a>

## eac_jar

<pre>
load("@MyProject", "eac_jar")

eac_jar(*, <a href="#eac_jar-name">name</a>, <a href="#eac_jar-deps">deps</a>, <a href="#eac_jar-srcs">srcs</a>, <a href="#eac_jar-data">data</a>, <a href="#eac_jar-resources">resources</a>, <a href="#eac_jar-add_exports">add_exports</a>, <a href="#eac_jar-add_opens">add_opens</a>, <a href="#eac_jar-arg">arg</a>, <a href="#eac_jar-bootclasspath">bootclasspath</a>, <a href="#eac_jar-javacopts">javacopts</a>,
        <a href="#eac_jar-licenses">licenses</a>, <a href="#eac_jar-neverlink">neverlink</a>, <a href="#eac_jar-plugins">plugins</a>, <a href="#eac_jar-runtime_deps">runtime_deps</a>, <a href="#eac_jar-tags">tags</a>, <a href="#eac_jar-visibility">visibility</a>)
</pre>

Macro for setting up the follwing EaC targets for `@MyProject//:project` (`<name>` = name provided to the macro):

- `<name>` for use in [as_code](#ecu_config.project-as_code).
- `<name>_jar` for building the actual .jar file.
- `<name>_dbg` for running/debugging the EaC logic in the IDE.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="eac_jar-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="eac_jar-deps"></a>deps |  [Inherited rule attribute](https://bazel.build/reference/be/java#java_library.deps)   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="eac_jar-srcs"></a>srcs |  The list of source files that are processed to create the target. This attribute is almost always required; see exceptions below. <p> Source files of type <code>.java</code> are compiled. In case of generated <code>.java</code> files it is generally advisable to put the generating rule's name here instead of the name of the file itself. This not only improves readability but makes the rule more resilient to future changes: if the generating rule generates different files in the future, you only need to fix one place: the <code>outs</code> of the generating rule. You should not list the generating rule in <code>deps</code> because it is a no-op. </p> <p> Source files of type <code>.srcjar</code> are unpacked and compiled. (This is useful if you need to generate a set of <code>.java</code> files with a genrule.) </p> <p> Rules: if the rule (typically <code>genrule</code> or <code>filegroup</code>) generates any of the files listed above, they will be used the same way as described for source files. </p> <p> Source files of type <code>.properties</code> are treated as resources. </p><br><br><p>All other files are ignored, as long as there is at least one file of a file type described above. Otherwise an error is raised.</p><br><br><p> This argument is almost always required, except if you specify the <code>runtime_deps</code> argument. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="eac_jar-data"></a>data |  The list of files needed by this library at runtime. See general comments about <code>data</code> at <a href="${link common-definitions#typical-attributes}">Typical attributes defined by most build rules</a>. <p>   When building a <code>java_library</code>, Bazel doesn't put these files anywhere; if the   <code>data</code> files are generated files then Bazel generates them. When building a   test that depends on this <code>java_library</code> Bazel copies or links the   <code>data</code> files into the runfiles area. </p>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="eac_jar-resources"></a>resources |  A list of data files to include in a Java jar. <p> Resources may be source files or generated files. </p><br><br><p> If resources are specified, they will be bundled in the jar along with the usual <code>.class</code> files produced by compilation. The location of the resources inside of the jar file is determined by the project structure. Bazel first looks for Maven's <a href="https://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html">standard directory layout</a>, (a "src" directory followed by a "resources" directory grandchild). If that is not found, Bazel then looks for the topmost directory named "java" or "javatests" (so, for example, if a resource is at <code>&lt;workspace root&gt;/x/java/y/java/z</code>, the path of the resource will be <code>y/java/z</code>. This heuristic cannot be overridden, however, the <code>resource_strip_prefix</code> attribute can be used to specify a specific alternative directory for resource files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="eac_jar-add_exports"></a>add_exports |  Allow this library to access the given <code>module</code> or <code>package</code>. <p> This corresponds to the javac and JVM --add-exports= flags.   | List of strings | optional |  `None`  |
| <a id="eac_jar-add_opens"></a>add_opens |  Allow this library to reflectively access the given <code>module</code> or <code>package</code>. <p> This corresponds to the javac and JVM --add-opens= flags.   | List of strings | optional |  `None`  |
| <a id="eac_jar-arg"></a>arg |  Optional argument. Use rule `load("@rules_cfg6//:defs.bazl", "as_code_arg")` to define the argument.<br><br>For deserializing the argument a dependency to Gson is required. `@dvcfg6//:gson` can be used for this.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="eac_jar-bootclasspath"></a>bootclasspath |  Restricted API, do not use!   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="eac_jar-javacopts"></a>javacopts |  Extra compiler options for this library. Subject to <a href="make-variables.html">"Make variable"</a> substitution and <a href="common-definitions.html#sh-tokenization">Bourne shell tokenization</a>. <p>These compiler options are passed to javac after the global compiler options.</p>   | List of strings | optional |  `None`  |
| <a id="eac_jar-licenses"></a>licenses |  -   | List of strings | optional |  `None`  |
| <a id="eac_jar-neverlink"></a>neverlink |  Whether this library should only be used for compilation and not at runtime. Useful if the library will be provided by the runtime environment during execution. Examples of such libraries are the IDE APIs for IDE plug-ins or <code>tools.jar</code> for anything running on a standard JDK. <p>   Note that <code>neverlink = True</code> does not prevent the compiler from inlining material   from this library into compilation targets that depend on it, as permitted by the Java   Language Specification (e.g., <code>static final</code> constants of <code>String</code>   or of primitive types). The preferred use case is therefore when the runtime library is   identical to the compilation library. </p> <p>   If the runtime library differs from the compilation library then you must ensure that it   differs only in places that the JLS forbids compilers to inline (and that must hold for   all future versions of the JLS). </p>   | Boolean | optional |  `None`  |
| <a id="eac_jar-plugins"></a>plugins |  [Inherited rule attribute](https://bazel.build/reference/be/java#java_library.plugins)   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="eac_jar-runtime_deps"></a>runtime_deps |  Libraries to make available to the final binary or test at runtime only. Like ordinary <code>deps</code>, these will appear on the runtime classpath, but unlike them, not on the compile-time classpath. Dependencies needed only at runtime should be listed here. Dependency-analysis tools should ignore targets that appear in both <code>runtime_deps</code> and <code>deps</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="eac_jar-tags"></a>tags |  [Inherited rule attribute](https://bazel.build/reference/be/common-definitions#common.tags)   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `[]`  |
| <a id="eac_jar-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="edit_project"></a>

## edit_project

<pre>
load("@MyProject", "edit_project")

edit_project(*, <a href="#edit_project-name">name</a>, <a href="#edit_project-aspect_hints">aspect_hints</a>, <a href="#edit_project-compatible_with">compatible_with</a>, <a href="#edit_project-deprecation">deprecation</a>, <a href="#edit_project-evo1">evo1</a>, <a href="#edit_project-exec_compatible_with">exec_compatible_with</a>,
             <a href="#edit_project-exec_group_compatible_with">exec_group_compatible_with</a>, <a href="#edit_project-exec_properties">exec_properties</a>, <a href="#edit_project-features">features</a>, <a href="#edit_project-package_metadata">package_metadata</a>, <a href="#edit_project-restricted_to">restricted_to</a>,
             <a href="#edit_project-tags">tags</a>, <a href="#edit_project-target_compatible_with">target_compatible_with</a>, <a href="#edit_project-testonly">testonly</a>, <a href="#edit_project-toolchains">toolchains</a>, <a href="#edit_project-visibility">visibility</a>)
</pre>

Macro for editing `@MyProject//:project` in DaVinci Configurator Classic Version 6 GUI tool.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="edit_project-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="edit_project-aspect_hints"></a>aspect_hints |  <a href="https://bazel.build/reference/be/common-definitions#common.aspect_hints">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="edit_project-compatible_with"></a>compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="edit_project-deprecation"></a>deprecation |  <a href="https://bazel.build/reference/be/common-definitions#common.deprecation">Inherited rule attribute</a>   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="edit_project-evo1"></a>evo1 |  The DaVinci Configurator Classic Version 6 Evo1 GUI executable for opening the project (absolute path).   | String | optional |  `None`  |
| <a id="edit_project-exec_compatible_with"></a>exec_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="edit_project-exec_group_compatible_with"></a>exec_group_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_group_compatible_with">Inherited rule attribute</a>   | Dictionary: String -> List of labels; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="edit_project-exec_properties"></a>exec_properties |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_properties">Inherited rule attribute</a>   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `None`  |
| <a id="edit_project-features"></a>features |  <a href="https://bazel.build/reference/be/common-definitions#common.features">Inherited rule attribute</a>   | List of strings | optional |  `None`  |
| <a id="edit_project-package_metadata"></a>package_metadata |  <a href="https://bazel.build/reference/be/common-definitions#common.package_metadata">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="edit_project-restricted_to"></a>restricted_to |  <a href="https://bazel.build/reference/be/common-definitions#common.restricted_to">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="edit_project-tags"></a>tags |  <a href="https://bazel.build/reference/be/common-definitions#common.tags">Inherited rule attribute</a>   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="edit_project-target_compatible_with"></a>target_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.target_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="edit_project-testonly"></a>testonly |  <a href="https://bazel.build/reference/be/common-definitions#common.testonly">Inherited rule attribute</a>   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="edit_project-toolchains"></a>toolchains |  <a href="https://bazel.build/reference/be/common-definitions#common.toolchains">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="edit_project-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


<a id="run_on_project"></a>

## run_on_project

<pre>
load("@MyProject", "run_on_project")

run_on_project(*, <a href="#run_on_project-name">name</a>, <a href="#run_on_project-aspect_hints">aspect_hints</a>, <a href="#run_on_project-command">command</a>, <a href="#run_on_project-compatible_with">compatible_with</a>, <a href="#run_on_project-deprecation">deprecation</a>, <a href="#run_on_project-exec_compatible_with">exec_compatible_with</a>,
               <a href="#run_on_project-exec_group_compatible_with">exec_group_compatible_with</a>, <a href="#run_on_project-exec_properties">exec_properties</a>, <a href="#run_on_project-features">features</a>, <a href="#run_on_project-inputs">inputs</a>, <a href="#run_on_project-package_metadata">package_metadata</a>,
               <a href="#run_on_project-restricted_to">restricted_to</a>, <a href="#run_on_project-tags">tags</a>, <a href="#run_on_project-target_compatible_with">target_compatible_with</a>, <a href="#run_on_project-testonly">testonly</a>, <a href="#run_on_project-toolchains">toolchains</a>, <a href="#run_on_project-visibility">visibility</a>)
</pre>

Macro for running DaVinci Configurator Classic Version 6 on `@MyProject//:project`.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="run_on_project-name"></a>name |  A unique name for this macro instance. Normally, this is also the name for the macro's main or only target. The names of any other targets that this macro might create will be this name with a string suffix.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="run_on_project-aspect_hints"></a>aspect_hints |  <a href="https://bazel.build/reference/be/common-definitions#common.aspect_hints">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="run_on_project-command"></a>command |  Command to run on the project (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.command)). Use `{dvcfg}` for the DaVinci Configurator Classic CLI executable, `{project}` for the .dvjson file and `{bsw_pkg}` for the BSW package folder.   | String | required |  |
| <a id="run_on_project-compatible_with"></a>compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_on_project-deprecation"></a>deprecation |  <a href="https://bazel.build/reference/be/common-definitions#common.deprecation">Inherited rule attribute</a>   | String; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_on_project-exec_compatible_with"></a>exec_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_on_project-exec_group_compatible_with"></a>exec_group_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_group_compatible_with">Inherited rule attribute</a>   | Dictionary: String -> List of labels; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_on_project-exec_properties"></a>exec_properties |  <a href="https://bazel.build/reference/be/common-definitions#common.exec_properties">Inherited rule attribute</a>   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `None`  |
| <a id="run_on_project-features"></a>features |  <a href="https://bazel.build/reference/be/common-definitions#common.features">Inherited rule attribute</a>   | List of strings | optional |  `None`  |
| <a id="run_on_project-inputs"></a>inputs |  Input files (see [run_shell](https://bazel.build/rules/lib/builtins/actions#run_shell.inputs)). Use `{key}` to access file `input["key"]` in `command`.   | Dictionary: String -> Label | optional |  `None`  |
| <a id="run_on_project-package_metadata"></a>package_metadata |  <a href="https://bazel.build/reference/be/common-definitions#common.package_metadata">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_on_project-restricted_to"></a>restricted_to |  <a href="https://bazel.build/reference/be/common-definitions#common.restricted_to">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_on_project-tags"></a>tags |  <a href="https://bazel.build/reference/be/common-definitions#common.tags">Inherited rule attribute</a>   | List of strings; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_on_project-target_compatible_with"></a>target_compatible_with |  <a href="https://bazel.build/reference/be/common-definitions#common.target_compatible_with">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="run_on_project-testonly"></a>testonly |  <a href="https://bazel.build/reference/be/common-definitions#common.testonly">Inherited rule attribute</a>   | Boolean; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  `None`  |
| <a id="run_on_project-toolchains"></a>toolchains |  <a href="https://bazel.build/reference/be/common-definitions#common.toolchains">Inherited rule attribute</a>   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `None`  |
| <a id="run_on_project-visibility"></a>visibility |  The visibility to be passed to this macro's exported targets. It always implicitly includes the location where this macro is instantiated, so this attribute only needs to be explicitly set if you want the macro's targets to be additionally visible somewhere else.   | <a href="https://bazel.build/concepts/labels">List of labels</a>; <a href="https://bazel.build/reference/be/common-definitions#configurable-attributes">nonconfigurable</a> | optional |  |


