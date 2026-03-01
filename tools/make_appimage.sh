#!/usr/bin/env bash
set -euo pipefail

# Minimal AppImage builder for the Flutter Linux bundle including core/.
# Requires: flutter, appimagetool (or linuxdeploy/AppDir tooling).

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GUI_DIR="$REPO_ROOT/gui"
BUILD_BUNDLE="$GUI_DIR/build/linux/x64/release/bundle"
APPDIR="$REPO_ROOT/AppDir"
OUT="$REPO_ROOT/Blipboard.AppImage"

echo "Building Flutter release bundle..."
cd "$GUI_DIR"
flutter build linux --release

if [ ! -d "$BUILD_BUNDLE" ]; then
  echo "Expected build bundle at $BUILD_BUNDLE not found" >&2
  exit 1
fi

echo "Preparing AppDir..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"

# Copy bundle contents into AppDir
cp -r "$BUILD_BUNDLE"/* "$APPDIR/usr/bin/"

# Copy core directory into AppDir under usr/bin so GUI path matches
mkdir -p "$APPDIR/usr/bin/core"
cp -r "$REPO_ROOT/core"/* "$APPDIR/usr/bin/core/"  # contains executables and scripts
# ensure executables have +x
chmod +x "$APPDIR/usr/bin/core/blipboard_server" "$APPDIR/usr/bin/core/blipboard_client" || true

# also copy repository icon if present for the desktop entry
if [ -f "$REPO_ROOT/flutter.png" ]; then
  cp "$REPO_ROOT/flutter.png" "$APPDIR/"
  mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
  cp "$REPO_ROOT/flutter.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/flutter.png"
fi
cat > "$APPDIR/blipboard.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Blipboard
Exec=usr/bin/gui
Icon=flutter
Categories=Utility;
EOF

# Create AppRun stub which appimagetool expects. It should launch the GUI
# binary located in usr/bin. Executable permission is required.
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
exec "$HERE/usr/bin/gui" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "Done."
