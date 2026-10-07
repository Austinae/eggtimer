#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/EggTimer.app"

cd "$ROOT"
BIN="$(swift build -c release --show-bin-path)"
EXEC="$BIN/EggTimer"
BUNDLE="$BIN/EggTimer_EggTimer.bundle"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$EXEC" "$APP/Contents/MacOS/EggTimer"
cp -R "$BUNDLE" "$APP/EggTimer_EggTimer.bundle"
cp "$ROOT/App/Info.plist" "$APP/Contents/Info.plist"
iconutil -c icns "$ROOT/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
chmod +x "$APP/Contents/MacOS/EggTimer"

rm -f "$ROOT/dist/EggTimer.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ROOT/dist/EggTimer.zip"

echo "Built $APP"
echo "Share $ROOT/dist/EggTimer.zip"
