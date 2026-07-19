# Contributing

Focused bug reports and pull requests are welcome. Keep changes aligned with the app's single purpose and avoid dependencies, settings, networking, telemetry, or unrelated features.

Before opening a pull request:

```sh
swift test
./scripts/package_app.sh
codesign --verify --deep --strict "build/Clean Mac Desktop.app"
```

Describe the macOS version and hardware used for any manual testing. Do not claim Intel, multi-display, upgrade, or fresh-account testing unless it was actually performed.
