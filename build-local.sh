#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Mac Patro"
APP_BUNDLE="dist/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"

osascript -e 'tell application id "com.agamtech.macpatro" to quit' >/dev/null 2>&1 || true
for _ in {1..20}; do
    pgrep -x MacPatroNativeApp >/dev/null || break
    sleep 0.1
done
pkill -x MacPatroNativeApp >/dev/null 2>&1 || true

./build.sh "${1:-1.0.12}"
rm -rf "$INSTALL_PATH"
ditto "$APP_BUNDLE" "$INSTALL_PATH"
open "$INSTALL_PATH"

echo "Installed and launched: $INSTALL_PATH"
