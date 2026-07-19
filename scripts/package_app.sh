#!/bin/zsh
set -euo pipefail

repository_root=${0:A:h:h}
output_directory=${OUTPUT_DIRECTORY:-$repository_root/build}
final_app_directory="$output_directory/Clean Mac Desktop.app"
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/clean-mac-desktop-app.XXXXXX")
app_directory="$temporary_directory/Clean Mac Desktop.app"
trap 'rm -rf "$temporary_directory"' EXIT

cd "$repository_root"
swift build -c release --arch arm64 --arch x86_64

mkdir -p "$app_directory/Contents/MacOS" "$app_directory/Contents/Resources"
cp ".build/apple/Products/Release/CleanMacDesktop" "$app_directory/Contents/MacOS/CleanMacDesktop"
cp Support/Info.plist "$app_directory/Contents/Info.plist"
cp Assets/AppIcon.icns "$app_directory/Contents/Resources/AppIcon.icns"

xattr -cr "$app_directory"
code_sign_identity=${CODE_SIGN_IDENTITY:--}
if [[ "$code_sign_identity" == "-" ]]; then
  codesign --force --sign - "$app_directory"
else
  codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$code_sign_identity" \
    "$app_directory"
fi
codesign --verify --deep --strict "$app_directory"

mkdir -p "$output_directory"
rm -rf "$final_app_directory"
ditto --noextattr --noqtn "$app_directory" "$final_app_directory"

echo "$final_app_directory"
