#!/bin/bash
# Package both modes without installing or launching either app.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=1.1.1
TIMESTAMP=2026-09-20-120000
PLIST="dist/Mac Patro.app/Contents/Info.plist"
for LOCAL in 1 0; do
    LOCAL_BUILD="$LOCAL" BUILD_TIMESTAMP="$TIMESTAMP" ./build.sh "$VERSION"
    EXPECTED="$VERSION"
    if [[ "$LOCAL" == 1 ]]; then
        EXPECTED="$VERSION--build-$TIMESTAMP"
    fi
    test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleGetInfoString' "$PLIST")" = "$EXPECTED"
    test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$PLIST")" = "$VERSION"
    test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$PLIST")" = "20260920120000"
done
echo "Local and release version metadata checks passed."
