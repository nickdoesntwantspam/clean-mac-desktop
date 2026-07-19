# Clean Mac Desktop

Clean Mac Desktop is a tiny, native macOS menu-bar utility that hides files and folders on the Desktop without moving them. Everything remains available in Finder.

It is intentionally narrow: no accounts, analytics, telemetry, advertising, networking, background service, login item, updater, or subscription.

## Requirements

- macOS 14 Sonoma or later
- Apple silicon or Intel Mac

## Use

1. Open Clean Mac Desktop. A display icon appears in the menu bar; the app does not add a Dock icon or open a window.
2. Choose **Hide Desktop Items**.
3. Continue accessing the files normally through the Desktop folder in Finder.
4. Choose **Show Desktop Items** from the menu-bar menu to restore them on the desktop.

The app changes the same Desktop visibility preference exposed by **System Settings → Desktop & Dock → Show Items → On Desktop**. Finder briefly refreshes when the setting changes. Files are never moved, renamed, deleted, uploaded, or edited.

## Recovery

Normally, choose **Show Desktop Items** from the menu-bar menu. You can also enable **Show Items → On Desktop** in Desktop & Dock settings. If neither is available, restart the Mac. No data loss is expected because the app changes visibility only.

## Privacy and permissions

Clean Mac Desktop requests no macOS permissions and makes no network connections. It reads and changes one local macOS preference, then asks Finder to refresh. See [PRIVACY.md](PRIVACY.md).

## Build from source

Xcode 16 or later is required. The project has no third-party dependencies.

```sh
swift test
./scripts/package_app.sh
open "build/Clean Mac Desktop.app"
```

The packaging script creates an ad-hoc signed development build. Ad-hoc builds are not notarized and macOS may treat each rebuild as a different identity. Official distribution builds should use Developer ID signing and notarization.

## Distribution

Download the signed and notarized universal DMG from [GitHub Releases](https://github.com/nickdoesntwantspam/clean-mac-desktop/releases). The application remains completely free and open source. A Homebrew Cask is not currently published.

To build from source instead, clone this repository and follow the instructions above.

## Contributing and security

Focused issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md) first.

## License

MIT. Copyright © 2026 Nicholas Williams.
