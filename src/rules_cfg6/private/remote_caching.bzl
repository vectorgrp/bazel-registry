"""Support for [Remote Caching](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/configuration/cache/remote-cache.html)"""

RemoteCacheInfo = provider("Remote Cache config", fields = ["enabled", "scheme", "host", "port", "config_file"])

def _remote_caching_setting_impl(ctx):
    settings_str = ctx.build_setting_value
    if not settings_str:
        return [RemoteCacheInfo(enabled = False)]
    scheme, _, host_port = settings_str.partition("://")
    if not scheme:
        fail("Missing scheme")
    elif scheme not in ("http", "https"):
        fail("Only http and https supported")

    host_port = host_port.removesuffix("/")
    if "/" in host_port:
        fail("Specifying a subpath is not supported")
    host, _, port = host_port.partition(":")

    if not port:
        port = 80 if scheme == "http" else 443
    else:
        port = int(port)

    config_file = ctx.actions.declare_file("cache/cache_config.json")
    ctx.actions.write(
        config_file,
        json.encode(
            {
                "version": "1.0",
                "general": {
                    "maxFileSizeInMb": 1024,
                },
                "remote": {
                    "endpoints": [
                        {
                            "protocol": scheme,
                            "host": host,
                            "port": port,
                        },
                    ],
                },
            },
        ),
    )
    return [
        RemoteCacheInfo(enabled = True, scheme = scheme, host = host, port = port, config_file = config_file),
    ]

remote_caching_setting = rule(
    doc = "Build setting for configuring [Remote Caching](https://help.vector.com/davinci-configurator-classic/en/latest/user-manual/configuration/cache/remote-cache.html)",
    implementation = _remote_caching_setting_impl,
    build_setting = config.string(flag = True),
    provides = [RemoteCacheInfo],
)
