load("@dvarjson//:dvarjson.bzl", "dvarjson_toolchain")

package(default_visibility = ["//visibility:public"])

dvarjson_toolchain(
    name = "dvarjson",
    cli = "CLI"
)

toolchain(
    name ="toolchain",
    toolchain = ":dvarjson",
    toolchain_type = "@dvarjson//:toolchain_type"
)
