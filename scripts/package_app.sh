#!/bin/zsh
set -euo pipefail

repository_root=${0:A:h:h}
output_directory="$repository_root/build"
app_directory="$output_directory/Clean Mac Desktop.app"

cd "$repository_root"
swift build -c release --arch arm64 --arch x86_64

rm -rf "$app_directory"
mkdir -p "$app_directory/Contents/MacOS" "$app_directory/Contents/Resources"
cp ".build/apple/Products/Release/CleanMacDesktop" "$app_directory/Contents/MacOS/CleanMacDesktop"
cp Support/Info.plist "$app_directory/Contents/Info.plist"
cp Assets/AppIcon.icns "$app_directory/Contents/Resources/AppIcon.icns"

xattr -cr "$app_directory"
codesign --force --sign "${CODE_SIGN_IDENTITY:--}" "$app_directory"
codesign --verify --deep --strict "$app_directory"

echo "$app_directory"
