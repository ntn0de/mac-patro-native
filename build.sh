#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Mac Patro"
EXECUTABLE_NAME="MacPatroNativeApp"
APP_BUNDLE="dist/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
PLUGINS="$CONTENTS/PlugIns"
WIDGET_BUNDLE="$PLUGINS/MacPatroWidgetExtension.appex"
WIDGET_CONTENTS="$WIDGET_BUNDLE/Contents"
PRODUCTS="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
WIDGET_ARM_PRODUCTS=".build/WidgetExtension-arm64/Build/Products/Release"
WIDGET_X86_PRODUCTS=".build/WidgetExtension-x86_64/Build/Products/Release"
VERSION="${1:-1.0.12}"
BUILD_TIMESTAMP="${BUILD_TIMESTAMP:-$(date +%Y-%m-%d-%H%M%S)}"
BUILD_NUMBER="${BUILD_TIMESTAMP//-/}"
DISPLAY_VERSION="$VERSION"
if [[ "${LOCAL_BUILD:-0}" == "1" ]]; then
    DISPLAY_VERSION="$VERSION--build-$BUILD_TIMESTAMP"
fi

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "Version must be numeric, for example: 1.0.12" >&2
    exit 1
fi

# Build universal app and WidgetKit extension binaries.
swift build -c release --arch arm64 --arch x86_64
for ARCH in arm64 x86_64; do
    xcodebuild \
        -project MacPatroNative/Widgets/MacPatroWidgetExtension.xcodeproj \
        -scheme MacPatroWidgetExtension \
        -configuration Release \
        -derivedDataPath ".build/WidgetExtension-$ARCH" \
        ARCHS="$ARCH" \
        ONLY_ACTIVE_ARCH=YES \
        CODE_SIGNING_ALLOWED=NO \
        build
done

# Create a clean app bundle.
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES" "$PLUGINS"
cp "$PRODUCTS/$EXECUTABLE_NAME" "$MACOS/"
cp MacPatroNative/Resources/icon.icns "$RESOURCES/AppIcon.icns"
cp MacPatroNative/Resources/*.json "$RESOURCES/"

RESOURCE_BUNDLE=""
for candidate in \
    "$PRODUCTS/MacPatroNative_MacPatroKit.bundle" \
    .build/arm64-apple-macosx/release/MacPatroNative_MacPatroKit.bundle \
    .build/x86_64-apple-macosx/release/MacPatroNative_MacPatroKit.bundle
do
    if [[ -d "$candidate" ]]; then
        RESOURCE_BUNDLE="$candidate"
        break
    fi
done
if [[ -n "$RESOURCE_BUNDLE" ]]; then
    ditto "$RESOURCE_BUNDLE" "$RESOURCES/MacPatroNative_MacPatroKit.bundle"
fi

ditto "$WIDGET_ARM_PRODUCTS/MacPatroWidgetExtension.appex" "$WIDGET_BUNDLE"
lipo -create \
    "$WIDGET_ARM_PRODUCTS/MacPatroWidgetExtension.appex/Contents/MacOS/MacPatroWidgetExtension" \
    "$WIDGET_X86_PRODUCTS/MacPatroWidgetExtension.appex/Contents/MacOS/MacPatroWidgetExtension" \
    -output "$WIDGET_CONTENTS/MacOS/MacPatroWidgetExtension"

cat > "$WIDGET_CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacPatroWidgetExtension</string>
    <key>CFBundleIdentifier</key>
    <string>com.agamtech.macpatro.widgets</string>
    <key>CFBundleName</key>
    <string>Mac Patro Widgets</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
EOF

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
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.agamtech.macpatro</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>macpatro</string>
            </array>
        </dict>
    </array>
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
codesign --force --sign - --entitlements MacPatroNative/Widgets/MacPatroWidgets.entitlements "$WIDGET_BUNDLE"
codesign --force --sign - "$APP_BUNDLE"

echo "Build complete: $APP_BUNDLE ($DISPLAY_VERSION)"
