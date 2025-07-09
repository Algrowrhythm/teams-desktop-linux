#!/bin/bash
# Universal installer for Teams Desktop Linux
# Supports Ubuntu, Debian, Fedora, CentOS, Arch Linux, and more

set -e

# Configuration
readonly REPO_URL="https://github.com/Algrowrhythm/teams-desktop-linux"
readonly RELEASES_URL="$REPO_URL/releases/latest/download"
readonly APP_NAME="Teams Desktop Linux"
readonly PACKAGE_NAME="teams-desktop-linux"
readonly VERSION="1.0.0"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
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

show_usage() {
    cat << EOF
Universal installer for $APP_NAME

Usage: $0 [OPTIONS]

Options:
    -h, --help      Show this help message
    -f, --format    Force specific package format (deb|rpm|pkg|appimage)
    -v, --version   Show version information
    --uninstall     Uninstall $APP_NAME
    --dry-run       Show what would be installed without installing

Examples:
    $0                    # Auto-detect and install
    $0 --format deb       # Force .deb installation
    $0 --uninstall        # Uninstall the application

EOF
}

detect_system() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

check_dependencies() {
    local missing_deps=()
    
    # Check for required tools
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    command -v wget >/dev/null 2>&1 || missing_deps+=("wget")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_color "$RED" "❌ Missing dependencies: ${missing_deps[*]}"
        
        local pm=$(detect_package_manager)
        case $pm in
            apt)
                print_color "$YELLOW" "Install with: sudo apt-get install ${missing_deps[*]}"
                ;;
            yum|dnf)
                print_color "$YELLOW" "Install with: sudo $pm install ${missing_deps[*]}"
                ;;
            pacman)
                print_color "$YELLOW" "Install with: sudo pacman -S ${missing_deps[*]}"
                ;;
        esac
        
        return 1
    fi
    
    return 0
}

download_file() {
    local url="$1"
    local output="$2"
    
    print_color "$BLUE" "📥 Downloading: $(basename "$url")"
    
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$output" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$output" "$url"
    else
        print_color "$RED" "❌ Neither curl nor wget is available"
        return 1
    fi
}

install_deb() {
    local package_file="$1"
    
    print_color "$BLUE" "📦 Installing Debian package..."
    
    sudo dpkg -i "$package_file" || {
        print_color "$YELLOW" "⚠️  Fixing dependencies..."
        sudo apt-get install -f -y
    }
    
    print_color "$GREEN" "✅ Debian package installed successfully!"
}

install_rpm() {
    local package_file="$1"
    local pm=$(detect_package_manager)
    
    print_color "$BLUE" "📦 Installing RPM package..."
    
    case $pm in
        yum)
            sudo yum localinstall -y "$package_file"
            ;;
        dnf)
            sudo dnf install -y "$package_file"
            ;;
        zypper)
            sudo zypper install -y "$package_file"
            ;;
        *)
            sudo rpm -i "$package_file"
            ;;
    esac
    
    print_color "$GREEN" "✅ RPM package installed successfully!"
}

install_pkg() {
    local package_file="$1"
    
    print_color "$BLUE" "📦 Installing Arch package..."
    
    sudo pacman -U --noconfirm "$package_file"
    
    print_color "$GREEN" "✅ Arch package installed successfully!"
}

install_appimage() {
    local appimage_file="$1"
    local install_dir="$HOME/.local/bin"
    local desktop_dir="$HOME/.local/share/applications"
    
    print_color "$BLUE" "📦 Installing AppImage..."
    
    # Create directories
    mkdir -p "$install_dir" "$desktop_dir"
    
    # Install AppImage
    cp "$appimage_file" "$install_dir/teams-desktop-linux"
    chmod +x "$install_dir/teams-desktop-linux"
    
    # Create desktop entry
    cat > "$desktop_dir/teams-desktop-linux.desktop" << EOF
[Desktop Entry]
Name=Teams Desktop Linux
GenericName=Microsoft Teams Client
Comment=Lightweight Microsoft Teams PWA client
Exec=$install_dir/teams-desktop-linux %U
Icon=teams-desktop-linux
Type=Application
Categories=Network;Chat;InstantMessaging;Office;VideoConference;
StartupWMClass=teams-desktop-linux
MimeType=x-scheme-handler/msteams;x-scheme-handler/ms-teams;
StartupNotify=true
Keywords=teams;microsoft;chat;video;collaboration;meeting;
EOF
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$desktop_dir" 2>/dev/null || true
    fi
    
    print_color "$GREEN" "✅ AppImage installed successfully!"
    print_color "$BLUE" "📁 Installed to: $install_dir/teams-desktop-linux"
}

uninstall_app() {
    print_header "Uninstalling $APP_NAME"
    
    local pm=$(detect_package_manager)
    local system=$(detect_system)
    
    case $pm in
        apt)
            if dpkg -l | grep -q "$PACKAGE_NAME"; then
                sudo apt-get remove -y "$PACKAGE_NAME"
                print_color "$GREEN" "✅ Uninstalled via apt"
            fi
            ;;
        yum|dnf)
            if rpm -q "$PACKAGE_NAME" >/dev/null 2>&1; then
                sudo "$pm" remove -y "$PACKAGE_NAME"
                print_color "$GREEN" "✅ Uninstalled via $pm"
            fi
            ;;
        pacman)
            if pacman -Q "$PACKAGE_NAME" >/dev/null 2>&1; then
                sudo pacman -R --noconfirm "$PACKAGE_NAME"
                print_color "$GREEN" "✅ Uninstalled via pacman"
            fi
            ;;
    esac
    
    # Remove AppImage installation
    if [[ -f "$HOME/.local/bin/teams-desktop-linux" ]]; then
        rm -f "$HOME/.local/bin/teams-desktop-linux"
        rm -f "$HOME/.local/share/applications/teams-desktop-linux.desktop"
        print_color "$GREEN" "✅ Removed AppImage installation"
    fi
    
    # Clean user data
    read -p "Remove user data? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.local/share/teams-desktop-linux"
        print_color "$GREEN" "✅ User data removed"
    fi
    
    print_color "$GREEN" "🎉 $APP_NAME uninstalled successfully!"
}

main() {
    local force_format=""
    local dry_run=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--format)
                force_format="$2"
                shift 2
                ;;
            -v|--version)
                echo "$APP_NAME installer v$VERSION"
                exit 0
                ;;
            --uninstall)
                uninstall_app
                exit 0
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                print_color "$RED" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_header "Installing $APP_NAME v$VERSION"
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    # Detect system
    local system=$(detect_system)
    local pm=$(detect_package_manager)
    
    print_color "$BLUE" "🔍 Detected system: $system"
    print_color "$BLUE" "🔍 Package manager: $pm"
    
    # Determine package format
    local format="$force_format"
    if [[ -z "$format" ]]; then
        case $pm in
            apt)
                format="deb"
                ;;
            yum|dnf|zypper)
                format="rpm"
                ;;
            pacman)
                format="pkg"
                ;;
            *)
                format="appimage"
                ;;
        esac
    fi
    
    print_color "$BLUE" "📦 Package format: $format"
    
    if [[ "$dry_run" == true ]]; then
        print_color "$YELLOW" "🧪 Dry run - would install $format package"
        exit 0
    fi
    
    # Download and install
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    case $format in
        deb)
            local package_file="$temp_dir/${PACKAGE_NAME}_${VERSION}_all.deb"
            download_file "$RELEASES_URL/${PACKAGE_NAME}_${VERSION}_all.deb" "$package_file"
            install_deb "$package_file"
            ;;
        rpm)
            local package_file="$temp_dir/${PACKAGE_NAME}-${VERSION}.rpm"
            download_file "$RELEASES_URL/${PACKAGE_NAME}-${VERSION}.rpm" "$package_file"
            install_rpm "$package_file"
            ;;
        pkg)
            local package_file="$temp_dir/${PACKAGE_NAME}-${VERSION}.pkg.tar.xz"
            download_file "$RELEASES_URL/${PACKAGE_NAME}-${VERSION}.pkg.tar.xz" "$package_file"
            install_pkg "$package_file"
            ;;
        appimage)
            local package_file="$temp_dir/${PACKAGE_NAME}-${VERSION}.AppImage"
            download_file "$RELEASES_URL/${PACKAGE_NAME}-${VERSION}.AppImage" "$package_file"
            install_appimage "$package_file"
            ;;
        *)
            print_color "$RED" "❌ Unsupported package format: $format"
            exit 1
            ;;
    esac
    
    print_color "$GREEN" "🎉 $APP_NAME installed successfully!"
    print_color "$BLUE" "🚀 Launch from your applications menu or run: teams-desktop-linux"
    print_color "$BLUE" "📋 For help: teams-desktop-linux --help"
    print_color "$BLUE" "🐛 Report issues: $REPO_URL/issues"
}

# Run main function
main "$@"