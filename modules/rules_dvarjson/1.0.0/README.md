<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# rules_dvarjson v1.0.0

```starlark
bazep_dep(name = "rules_dvarjson", version = "1.0.0")
```
Bazel ruleset for working with [DaVinci AUTOSAR JSON](https://help.vector.com/davinci-configurator-classic/en/current/davinci-autosar-json/6.2-SP0/index.html).

<a id="ddm"></a>

## ddm

<pre>
load("@rules_dvarjson", "ddm")

ddm(<a href="#ddm-name">name</a>, <a href="#ddm-json">json</a>)
</pre>

Rule for extracting a diagnostic module configuration from .cdd using a DDM .json file.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="ddm-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="ddm-json"></a>json |  The DDM .json file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="ddm_json"></a>

## ddm_json

<pre>
load("@rules_dvarjson", "ddm_json")

ddm_json(<a href="#ddm_json-name">name</a>, <a href="#ddm_json-bsw_pkg">bsw_pkg</a>, <a href="#ddm_json-cdd">cdd</a>, <a href="#ddm_json-did_and_rid_as_single_signal">did_and_rid_as_single_signal</a>, <a href="#ddm_json-ecu">ecu</a>, <a href="#ddm_json-generic_legacy_import">generic_legacy_import</a>, <a href="#ddm_json-patch_file">patch_file</a>,
         <a href="#ddm_json-variant">variant</a>)
</pre>

Rule for creating a DDM .json file.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="ddm_json-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="ddm_json-bsw_pkg"></a>bsw_pkg |  Path to the BSW package folder.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="ddm_json-cdd"></a>cdd |  The .cdd file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="ddm_json-did_and_rid_as_single_signal"></a>did_and_rid_as_single_signal |  -   | Boolean | optional |  `False`  |
| <a id="ddm_json-ecu"></a>ecu |  ECU name as defined in the given .cdd file.   | String | required |  |
| <a id="ddm_json-generic_legacy_import"></a>generic_legacy_import |  -   | Boolean | optional |  `False`  |
| <a id="ddm_json-patch_file"></a>patch_file |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="ddm_json-variant"></a>variant |  Diagnostic variant name as defined in the given .cdd file.   | String | required |  |


<a id="evs"></a>

## evs

<pre>
load("@rules_dvarjson", "evs")

evs(<a href="#evs-name">name</a>, <a href="#evs-json">json</a>)
</pre>

Rule for transforming an EvaluatedVariantSet .json file to .arxml.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="evs-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="evs-json"></a>json |  The EVS .json file.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="dvarjson_archive"></a>

## dvarjson_archive

<pre>
load("@rules_dvarjson", "dvarjson_archive")

dvarjson_archive(<a href="#dvarjson_archive-name">name</a>, <a href="#dvarjson_archive-sha256">sha256</a>, <a href="#dvarjson_archive-url">url</a>)
</pre>

Rule for using a dvarjson .nupkg or .deb archive.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="dvarjson_archive-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="dvarjson_archive-sha256"></a>sha256 |  SHA256 archive checksum.   | String | optional |  `""`  |
| <a id="dvarjson_archive-url"></a>url |  URL of the .deb or .nupkg archive.   | String | required |  |


<a id="local_dvarjson"></a>

## local_dvarjson

<pre>
load("@rules_dvarjson", "local_dvarjson")

local_dvarjson(<a href="#local_dvarjson-name">name</a>, <a href="#local_dvarjson-path">path</a>)
</pre>

Rule for using a local dvarjson installation.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="local_dvarjson-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="local_dvarjson-path"></a>path |  Path of the dvarjson install folder.   | String | required |  |


