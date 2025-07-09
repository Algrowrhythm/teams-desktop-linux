#!/bin/bash
# Helper script to build AppImage

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/appimage"
DIST_DIR="$PROJECT_ROOT/dist"

echo "🔨 Building AppImage for Teams Desktop Linux..."

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

# Copy source files
cp -r "$PROJECT_ROOT/src" "$BUILD_DIR/"
cp -r "$PROJECT_ROOT/assets" "$BUILD_DIR/"
cp "$SCRIPT_DIR/AppImageBuilder.yml" "$BUILD_DIR/"

cd "$BUILD_DIR"

# Install appimage-builder if not available
if ! command -v appimage-builder >/dev/null 2>&1; then
    echo "📥 Installing appimage-builder..."
    
    # Try different installation methods
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user appimage-builder
        export PATH="$HOME/.local/bin:$PATH"
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y appimage-builder
    else
        echo "❌ Cannot install appimage-builder automatically"
        echo "Please install it manually: https://appimage-builder.readthedocs.io/en/latest/intro/install.html"
        exit 1
    fi
fi

# Build AppImage
echo "🏗️  Building AppImage..."
appimage-builder --recipe AppImageBuilder.yml --skip-test

# Move to dist directory
if [[ -f teams-desktop-linux-1.0.0.AppImage ]]; then
    mv teams-desktop-linux-1.0.0.AppImage "$DIST_DIR/"
    echo "✅ AppImage built successfully!"
    echo "📁 Output: $DIST_DIR/teams-desktop-linux-1.0.0.AppImage"
else
    echo "❌ AppImage build failed"
    exit 1
fi

# Generate zsync file for updates
if command -v zsyncmake >/dev/null 2>&1; then
    echo "📦 Generating zsync file..."
    cd "$DIST_DIR"
    zsyncmake -u "teams-desktop-linux-1.0.0.AppImage" "teams-desktop-linux-1.0.0.AppImage"
    echo "✅ Zsync file generated for automatic updates"
fi

echo "🎉 AppImage build complete!"