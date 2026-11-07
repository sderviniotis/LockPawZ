#!/bin/bash
# LockPawZ: build a Release app, check it is universal, zip it for other Macs,
# and (optionally) install it to /Applications on this Mac.
#
#   ./scripts/build-lockpawz.sh            build + zip only
#   ./scripts/build-lockpawz.sh --install  build + zip + replace /Applications/LockPawZ.app
#
# Signing uses the Personal Team already configured in Xcode (CODE_SIGN_STYLE Automatic).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Generating project"
xcodegen generate >/dev/null

echo "==> Building Release"
xcodebuild -project Lockpaw.xcodeproj -scheme Lockpaw -configuration Release \
  -derivedDataPath build/DerivedData -destination 'platform=macOS' \
  -allowProvisioningUpdates build 2>&1 | grep -E 'error:|warning: .*LockPawZ|BUILD (SUCCEEDED|FAILED)' || true

APP="build/DerivedData/Build/Products/Release/LockPawZ.app"
[ -d "$APP" ] || { echo "Build product missing: $APP"; exit 1; }

echo "==> Architectures"
lipo -archs "$APP/Contents/MacOS/LockPawZ"

echo "==> Signature"
codesign -dv --verbose=2 "$APP" 2>&1 | grep -E 'Authority=|Identifier=|TeamIdentifier=' | head -4

VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$APP/Contents/Info.plist")
ZIP="build/LockPawZ-$VERSION-$BUILD.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "==> Zipped: $ZIP ($(du -h "$ZIP" | cut -f1))"

if [ "${1:-}" = "--install" ]; then
  echo "==> Installing to /Applications (quitting any running copy)"
  osascript -e 'tell application "LockPawZ" to quit' >/dev/null 2>&1 || true
  pkill -x LockPawZ >/dev/null 2>&1 || true
  rm -rf /Applications/LockPawZ.app
  ditto "$APP" /Applications/LockPawZ.app
  echo "==> Installed /Applications/LockPawZ.app $VERSION ($BUILD)"
  echo "    Open it from Applications, grant Accessibility to LockPawZ, turn on Open at login in Settings."
fi
