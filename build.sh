#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Mac Patro"
EXECUTABLE_NAME="MacPatroNativeApp"
APP_BUNDLE="dist/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
PRODUCTS=".build/apple/Products/Release"
VERSION="${1:-1.0.12}"
BUILD_TIMESTAMP="${BUILD_TIMESTAMP:-$(date +%Y-%m-%d-%H%M%S)}"
BUILD_NUMBER="${BUILD_TIMESTAMP//-/}"
DISPLAY_VERSION="$VERSION--build-$BUILD_TIMESTAMP"

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "Version must be numeric, for example: 1.0.12" >&2
    exit 1
fi

# Build a universal release executable.
swift build -c release --arch arm64 --arch x86_64

# Create a clean app bundle.
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"
cp "$PRODUCTS/$EXECUTABLE_NAME" "$MACOS/"
cp MacPatroNative/Resources/icon.icns "$RESOURCES/AppIcon.icns"
ditto "$PRODUCTS/MacPatroNative_MacPatroKit.bundle" \
    "$RESOURCES/MacPatroNative_MacPatroKit.bundle"

cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.agamtech.macpatro</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>CFBundleGetInfoString</key>
    <string>$DISPLAY_VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSCalendarsUsageDescription</key>
    <string>Mac Patro shows your Calendar events for today.</string>
    <key>NSCalendarsFullAccessUsageDescription</key>
    <string>Mac Patro shows your Calendar events for today.</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Ad-hoc sign local builds.
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Build complete: $APP_BUNDLE ($DISPLAY_VERSION)"
