#!/bin/zsh
set -euo pipefail

repository_root=${0:A:h:h}
version=$(defaults read "$repository_root/Support/Info" CFBundleShortVersionString)
expected_version=${1:-$version}

if [[ "$expected_version" != "$version" ]]; then
  echo "Requested version $expected_version does not match Info.plist version $version." >&2
  exit 1
fi

code_sign_identity=${CODE_SIGN_IDENTITY:-Developer ID Application: Nicholas Williams (G5E7K59HUM)}
output_directory="$repository_root/build"
dmg_path="$output_directory/Clean-Mac-Desktop-$version.dmg"
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/clean-mac-desktop-release.XXXXXX")
temporary_dmg="$temporary_directory/Clean-Mac-Desktop-$version.dmg"
staging_directory="$temporary_directory/dmg-root"
trap 'rm -rf "$temporary_directory"' EXIT

cd "$repository_root"
OUTPUT_DIRECTORY="$temporary_directory" \
  CODE_SIGN_IDENTITY="$code_sign_identity" \
  ./scripts/package_app.sh >/dev/null

mkdir -p "$staging_directory"
ditto "$temporary_directory/Clean Mac Desktop.app" "$staging_directory/Clean Mac Desktop.app"
ln -s /Applications "$staging_directory/Applications"

hdiutil create \
  -volname "Clean Mac Desktop" \
  -srcfolder "$staging_directory" \
  -format UDZO \
  -fs HFS+ \
  "$temporary_dmg" >/dev/null

codesign --force --timestamp --sign "$code_sign_identity" "$temporary_dmg"
codesign --verify --verbose=2 "$temporary_dmg"

mkdir -p "$output_directory"
rm -f "$dmg_path" "$dmg_path.sha256"
ditto --noextattr --noqtn "$temporary_dmg" "$dmg_path"
shasum -a 256 "$dmg_path" >"$dmg_path.sha256"

echo "$dmg_path"
