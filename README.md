# bazel-registry

Vector Group Bazel rules.

## Usage

Configure in `.bazelrc` file:

```text
common --registry=https://raw.githubusercontent.com/vectorgrp/bazel-registry/main
common --registry=https://bcr.bazel.build
```

## Examples

See [here](https://github.com/vectorgrp/davinci-samples) for ECU configuration examples with DaVinci Configurator Classic Version 6.

## Repo Content

This repo follows the structure for Bazel index registries. I.e. modules are represented as sub-folders of the [modules](modules) folder with sub-folders for the individual module versions.

E.g. version `1.0.2` of module `rules_ecu_config` is contained in [modules/rules_ecu_config/1.0.2](modules/rules_ecu_config/1.0.2).
