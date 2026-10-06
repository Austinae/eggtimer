#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/.build/arm64-apple-macosx/release"
APP="$ROOT/dist/EggTimer.app"

cd "$ROOT"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cp "$BUILD/EggTimer" "$APP/Contents/MacOS/EggTimer"
cp -R "$BUILD/EggTimer_EggTimer.bundle" "$APP/EggTimer_EggTimer.bundle"
chmod +x "$APP/Contents/MacOS/EggTimer"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>EggTimer</string>
    <key>CFBundleIdentifier</key>
    <string>com.eggtimer.app</string>
    <key>CFBundleName</key>
    <string>EggTimer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

rm -f "$ROOT/dist/EggTimer.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ROOT/dist/EggTimer.zip"

echo "Built $APP"
echo "Share $ROOT/dist/EggTimer.zip"
