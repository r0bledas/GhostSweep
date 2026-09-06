#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="1.1.0"
DIST_DIR="$PROJECT_DIR/dist"
APP_DIR="$PROJECT_DIR/GhostSweep.app"
CLI_BIN="$PROJECT_DIR/.build/release/ghostsweep"

cd "$PROJECT_DIR"

# 1. Build app and CLI in release mode
"$PROJECT_DIR/scripts/build_app.sh"

echo "Packaging GhostSweep v$VERSION release..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 2. Build DMG for GUI installer
DMG_STAGING="$DIST_DIR/dmg_staging"
mkdir -p "$DMG_STAGING"
cp -R "$APP_DIR" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

DMG_FILE="$DIST_DIR/GhostSweep-v$VERSION.dmg"
hdiutil create -volname "GhostSweep" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_FILE"
rm -rf "$DMG_STAGING"

# 3. Build universal ZIP archive
ZIP_FILE="$DIST_DIR/GhostSweep-v$VERSION.zip"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_FILE"

# 4. Build standalone CLI archive
CLI_ZIP="$DIST_DIR/ghostsweep-cli-v$VERSION.tar.gz"
tar -czf "$CLI_ZIP" -C "$PROJECT_DIR/.build/release" ghostsweep

# 5. Generate SHA256 checksums
cd "$DIST_DIR"
shasum -a 256 "GhostSweep-v$VERSION.dmg" "GhostSweep-v$VERSION.zip" "ghostsweep-cli-v$VERSION.tar.gz" > checksums.txt

echo ""
echo "Release packages generated in $DIST_DIR:"
ls -lh "$DIST_DIR"
