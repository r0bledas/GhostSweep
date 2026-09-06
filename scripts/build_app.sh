#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_DIR="$PROJECT_DIR/GhostSweep.app"

echo "🔨 Building GhostSweep in release mode..."
cd "$PROJECT_DIR"
swift build -c release

echo "📦 Creating GhostSweep.app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/GhostSweepApp" "$APP_DIR/Contents/MacOS/GhostSweepApp"

cat << 'PLIST' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>GhostSweepApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.raudel.GhostSweep</string>
    <key>CFBundleName</key>
    <string>GhostSweep</string>
    <key>CFBundleDisplayName</key>
    <string>GhostSweep</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "✅ GhostSweep.app bundle created at: $APP_DIR"
echo "CLI tool built at: $BUILD_DIR/ghostsweep"
echo ""
echo "To run GhostSweep GUI: open $APP_DIR"
echo "To install CLI system-wide: sudo cp $BUILD_DIR/ghostsweep /usr/local/bin/"
