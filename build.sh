#!/bin/bash
set -e

# Build configuration
readonly VERSION="1.0.0"
readonly PROJECT_NAME="teams-desktop-linux"
readonly BUILD_DIR="build"
readonly DIST_DIR="dist"
readonly SRC_DIR="src"
readonly ASSETS_DIR="assets"
readonly PACKAGING_DIR="packaging"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

print_color() {
    echo -e "${1}${2}${NC}"
}

print_header() {
    echo
    print_color "$BLUE" "========================================"
    print_color "$BLUE" " $1"
    print_color "$BLUE" "========================================"
    echo
}

cleanup() {
    print_color "$YELLOW" "🧹 Cleaning previous builds..."
    rm -rf "$BUILD_DIR" "$DIST_DIR"
    mkdir -p "$BUILD_DIR" "$DIST_DIR"
}

build_deb() {
    print_header "Building Debian Package"
    
    local deb_dir="$BUILD_DIR/debian/$PROJECT_NAME"
    
    # Create directory structure
    mkdir -p "$deb_dir"/{usr/bin,usr/share/applications,usr/share/pixmaps,DEBIAN}
    
    # Copy files
    cp "$SRC_DIR/teams-desktop-linux" "$deb_dir/usr/bin/"
    cp "$ASSETS_DIR/icons/teams-desktop-linux.png" "$deb_dir/usr/share/pixmaps/"
    cp "$PACKAGING_DIR/debian"/* "$deb_dir/DEBIAN/"
    
    # Create desktop file
    cat > "$deb_dir/usr/share/applications/teams-desktop-linux.desktop" << 'EOF'
[Desktop Entry]
Name=Teams Desktop Linux
GenericName=Microsoft Teams Client
Comment=Lightweight Microsoft Teams PWA client
Exec=/usr/bin/teams-desktop-linux %U
Icon=teams-desktop-linux
Type=Application
Categories=Network;Chat;InstantMessaging;Office;VideoConference;
StartupWMClass=teams-desktop-linux
MimeType=x-scheme-handler/msteams;x-scheme-handler/ms-teams;
StartupNotify=true
Keywords=teams;microsoft;chat;video;collaboration;meeting;
EOF
    
    # Set permissions
    chmod +x "$deb_dir/usr/bin/teams-desktop-linux"
    chmod +x "$deb_dir/DEBIAN/postinst"
    chmod +x "$deb_dir/DEBIAN/postrm"
    
    # Build package
    dpkg-deb --build "$deb_dir" "$DIST_DIR/${PROJECT_NAME}_${VERSION}_all.deb"
    
    print_color "$GREEN" "✅ Debian package built successfully!"
}

build_rpm() {
    print_header "Building RPM Package"
    
    local rpm_dir="$BUILD_DIR/rpm"
        local rpmbuild_dir="$rpm_dir/rpmbuild"
    
    # Create RPM build structure
    mkdir -p "$rpmbuild_dir"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
    
    # Copy and process spec file
    cp "$PACKAGING_DIR/rpm/teams-desktop-linux.spec" "$rpmbuild_dir/SPECS/"
    sed -i "s/VERSION_PLACEHOLDER/$VERSION/g" "$rpmbuild_dir/SPECS/teams-desktop-linux.spec"
    
    # Create source directory
    local source_dir="$rpm_dir/$PROJECT_NAME-$VERSION"
    mkdir -p "$source_dir"
    cp "$SRC_DIR/teams-desktop-linux" "$source_dir/"
    cp "$ASSETS_DIR/icons/teams-desktop-linux.png" "$source_dir/"
    
    # Create source tarball
    tar -czf "$rpmbuild_dir/SOURCES/$PROJECT_NAME-$VERSION.tar.gz" \
        -C "$rpm_dir" "$PROJECT_NAME-$VERSION"
    
    # Build RPM
    rpmbuild --define "_topdir $PWD/$rpmbuild_dir" \
             -ba "$rpmbuild_dir/SPECS/teams-desktop-linux.spec"
    
    # Copy built RPM
    cp "$rpmbuild_dir/RPMS/noarch/$PROJECT_NAME-$VERSION-1.noarch.rpm" \
       "$DIST_DIR/$PROJECT_NAME-$VERSION.rpm"
    
    print_color "$GREEN" "✅ RPM package built successfully!"
}

build_arch() {
    print_header "Building Arch Package"
    
    local arch_dir="$BUILD_DIR/arch"
    mkdir -p "$arch_dir"
    
    # Copy PKGBUILD
    cp "$PACKAGING_DIR/arch/PKGBUILD" "$arch_dir/"
    
    # Create source directory
    local source_dir="$arch_dir/src/$PROJECT_NAME-$VERSION"
    mkdir -p "$source_dir"
    cp -r "$SRC_DIR" "$ASSETS_DIR" "$source_dir/"
    
    # Build package
    cd "$arch_dir"
    makepkg -f
    cd - > /dev/null
    
    # Copy built package
    cp "$arch_dir/$PROJECT_NAME-$VERSION-1-any.pkg.tar.xz" \
       "$DIST_DIR/$PROJECT_NAME-$VERSION.pkg.tar.xz"
    
    print_color "$GREEN" "✅ Arch package built successfully!"
}

build_appimage() {
    print_header "Building AppImage"
    
    local appimage_dir="$BUILD_DIR/appimage"
    local appdir="$appimage_dir/AppDir"
    
    # Create AppDir structure
    mkdir -p "$appdir"/{usr/bin,usr/share/applications,usr/share/pixmaps}
    
    # Copy files
    cp "$SRC_DIR/teams-desktop-linux" "$appdir/usr/bin/"
    cp "$ASSETS_DIR/icons/teams-desktop-linux.png" "$appdir/usr/share/pixmaps/"
    
    # Create desktop file
    cat > "$appdir/usr/share/applications/teams-desktop-linux.desktop" << 'EOF'
[Desktop Entry]
Name=Teams Desktop Linux
GenericName=Microsoft Teams Client
Comment=Lightweight Microsoft Teams PWA client
Exec=teams-desktop-linux %U
Icon=teams-desktop-linux
Type=Application
Categories=Network;Chat;InstantMessaging;Office;VideoConference;
StartupWMClass=teams-desktop-linux
MimeType=x-scheme-handler/msteams;x-scheme-handler/ms-teams;
StartupNotify=true
Keywords=teams;microsoft;chat;video;collaboration;meeting;
EOF
    
    # Create AppRun
    cat > "$appdir/AppRun" << 'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${PATH}"
exec "${HERE}/usr/bin/teams-desktop-linux" "$@"
EOF
    
    # Set permissions
    chmod +x "$appdir/AppRun"
    chmod +x "$appdir/usr/bin/teams-desktop-linux"
    
    # Copy icon to root (required for AppImage)
    cp "$ASSETS_DIR/icons/teams-desktop-linux.png" "$appdir/"
    
    # Copy desktop file to root (required for AppImage)
    cp "$appdir/usr/share/applications/teams-desktop-linux.desktop" "$appdir/"
    
    # Download appimagetool if not available
    if ! command -v appimagetool >/dev/null 2>&1; then
        print_color "$YELLOW" "📥 Downloading appimagetool..."
        wget -O "$appimage_dir/appimagetool" \
            https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
        chmod +x "$appimage_dir/appimagetool"
        APPIMAGETOOL="$appimage_dir/appimagetool"
    else
        APPIMAGETOOL="appimagetool"
    fi
    
    # Build AppImage
    cd "$appimage_dir"
    ARCH=x86_64 "$APPIMAGETOOL" "$appdir" "../$DIST_DIR/$PROJECT_NAME-$VERSION.AppImage"
    cd - > /dev/null
    
    print_color "$GREEN" "✅ AppImage built successfully!"
}

create_checksums() {
    print_header "Creating Checksums"
    
    cd "$DIST_DIR"
    sha256sum * > SHA256SUMS
    md5sum * > MD5SUMS
    cd - > /dev/null
    
    print_color "$GREEN" "✅ Checksums created!"
}

show_summary() {
    print_header "Build Summary"
    
    echo "📦 Built packages:"
    ls -la "$DIST_DIR/"
    
    echo
    echo "📊 Package sizes:"
    du -h "$DIST_DIR"/* | sort -h
    
    echo
    print_color "$GREEN" "🎉 All packages built successfully!"
    print_color "$BLUE" "📁 Output directory: $DIST_DIR"
}

main() {
    print_color "$BLUE" "🚀 Building $PROJECT_NAME v$VERSION"
    
    # Check dependencies
    local missing_deps=()
    
    command -v dpkg-deb >/dev/null 2>&1 || missing_deps+=("dpkg-deb")
    command -v rpmbuild >/dev/null 2>&1 || missing_deps+=("rpmbuild")
    command -v makepkg >/dev/null 2>&1 || missing_deps+=("makepkg")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_color "$YELLOW" "⚠️  Missing dependencies: ${missing_deps[*]}"
        print_color "$YELLOW" "Some packages will be skipped."
    fi
    
    # Clean and prepare
    cleanup
    
    # Build packages
    command -v dpkg-deb >/dev/null 2>&1 && build_deb
    command -v rpmbuild >/dev/null 2>&1 && build_rpm
    command -v makepkg >/dev/null 2>&1 && build_arch
    build_appimage
    
    # Create checksums
    create_checksums
    
    # Show summary
    show_summary
}

# Run main function
main "$@"