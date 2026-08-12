#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Mac Patro"
APP_BUNDLE="dist/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"
WIDGET_BUNDLE_ID="com.agamtech.macpatro.widgets"

osascript -e 'tell application id "com.agamtech.macpatro" to quit' >/dev/null 2>&1 || true
for _ in {1..20}; do
    pgrep -x MacPatroNativeApp >/dev/null || break
    sleep 0.1
done
pkill -x MacPatroNativeApp >/dev/null 2>&1 || true

./build.sh "${1:-1.0.12}"
rm -rf "$INSTALL_PATH"
ditto "$APP_BUNDLE" "$INSTALL_PATH"

# Drop WidgetKit's cached extension process so desktop widgets pick up the new binary.
killall -9 MacPatroWidgetExtension >/dev/null 2>&1 || true
pluginkit -e use -i "$WIDGET_BUNDLE_ID" >/dev/null 2>&1 || true

open "$INSTALL_PATH"

echo "Installed and launched: $INSTALL_PATH"
echo "Widget cache reset for $WIDGET_BUNDLE_ID"
