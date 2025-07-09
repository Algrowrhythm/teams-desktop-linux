#!/bin/bash
# Desktop integration helper for AppImage

set -e

APPIMAGE_PATH="$1"
ACTION="${2:-install}"

if [[ -z "$APPIMAGE_PATH" ]] || [[ ! -f "$APPIMAGE_PATH" ]]; then
    echo "Usage: $0 <path-to-appimage> [install|remove]"
    exit 1
fi

APPIMAGE_PATH="$(readlink -f "$APPIMAGE_PATH")"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"

case "$ACTION" in
    install)
        echo "🔗 Installing desktop integration..."
        
        # Create directories
        mkdir -p "$DESKTOP_DIR" "$ICON_DIR"
        
        # Extract icon
        "$APPIMAGE_PATH" --appimage-extract teams-desktop-linux.png >/dev/null 2>&1
        if [[ -f squashfs-root/teams-desktop-linux.png ]]; then
            cp squashfs-root/teams-desktop-linux.png "$ICON_DIR/"
            rm -rf squashfs-root
        fi
        
        # Create desktop file
        cat > "$DESKTOP_DIR/teams-desktop-linux-appimage.desktop" << EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Teams Desktop Linux (AppImage)
GenericName=Microsoft Teams Client
Comment=Lightweight Microsoft Teams PWA client (AppImage)
Keywords=teams;microsoft;chat;video;collaboration;meeting;
Exec=$APPIMAGE_PATH %U
Icon=teams-desktop-linux
Terminal=false
StartupNotify=true
StartupWMClass=teams-desktop-linux
Categories=Network;Chat;InstantMessaging;Office;VideoConference;
MimeType=x-scheme-handler/msteams;x-scheme-handler/ms-teams;
X-AppImage-Version=1.0.0
X-AppImage-BuildId=teams-desktop-linux-1.0.0
EOF
        
        # Update desktop database
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
        fi
        
        # Update icon cache
        if command -v gtk-update-icon-cache >/dev/null 2>&1; then
            gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
        fi
        
        echo "✅ Desktop integration installed"
        ;;
        
    remove)
        echo "🗑️  Removing desktop integration..."
        
        rm -f "$DESKTOP_DIR/teams-desktop-linux-appimage.desktop"
        rm -f "$ICON_DIR/teams-desktop-linux.png"
        
        # Update desktop database
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
        fi
        
        # Update icon cache
        if command -v gtk-update-icon-cache >/dev/null 2>&1; then
            gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
        fi
        
        echo "✅ Desktop integration removed"
        ;;
        
    *)
        echo "Unknown action: $ACTION"
        echo "Usage: $0 <path-to-appimage> [install|remove]"
        exit 1
        ;;
esac