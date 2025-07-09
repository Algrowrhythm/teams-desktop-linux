Name:           teams-desktop-linux
Version:        VERSION_PLACEHOLDER
Release:        1%{?dist}
Summary:        Lightweight Microsoft Teams PWA client
Group:          Applications/Internet
License:        MIT
URL:            https://github.com/Algrowrhythm/teams-desktop-linux
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root

Requires:       chromium >= 90.0
Requires:       chromium-browser >= 90.0
Requires:       google-chrome-stable >= 90.0
Requires:       microsoft-edge-stable >= 90.0
Requires:       brave-browser >= 90.0

Recommends:     zenity
Recommends:     kdialog
Suggests:       libnotify

%description
A native-feeling Microsoft Teams client for Linux that wraps the Teams PWA
with proper desktop integration. Features include system notifications,
deep link support, and seamless integration with your desktop environment.

This package provides a lightweight alternative to the official Teams client
without the overhead of Electron, resulting in better performance and lower
resource usage.

Key features:
* Lightning fast startup and operation
* Native desktop integration
* System notifications support  
* Deep link handling for Teams URLs
* Automatic updates via PWA
* Multi-desktop environment support

%prep
%setup -q

%build
# Nothing to build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{_bindir}
mkdir -p $RPM_BUILD_ROOT%{_datadir}/applications
mkdir -p $RPM_BUILD_ROOT%{_datadir}/pixmaps

install -m 755 teams-desktop-linux $RPM_BUILD_ROOT%{_bindir}/
install -m 644 teams-desktop-linux.png $RPM_BUILD_ROOT%{_datadir}/pixmaps/

cat > $RPM_BUILD_ROOT%{_datadir}/applications/teams-desktop-linux.desktop << 'EOF'
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

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_bindir}/teams-desktop-linux
%{_datadir}/applications/teams-desktop-linux.desktop
%{_datadir}/pixmaps/teams-desktop-linux.png

%post
/bin/touch --no-create %{_datadir}/pixmaps &>/dev/null || :
if [ $1 -eq 1 ] ; then
    /usr/bin/gtk-update-icon-cache %{_datadir}/pixmaps &>/dev/null || :
fi
/usr/bin/update-desktop-database &> /dev/null || :

# Create symlink
ln -sf %{_bindir}/teams-desktop-linux %{_bindir}/teams-linux || :

echo "✅ Teams Desktop Linux installed successfully!"
echo ""
echo "🚀 Launch from your applications menu or run:"
echo "   teams-desktop-linux"

%postun
if [ $1 -eq 0 ] ; then
    /bin/touch --no-create %{_datadir}/pixmaps &>/dev/null
    /usr/bin/gtk-update-icon-cache %{_datadir}/pixmaps &>/dev/null || :
fi
/usr/bin/update-desktop-database &> /dev/null || :

# Remove symlink
rm -f %{_bindir}/teams-linux || :

%changelog
* Thu Jan 01 2024 Teams Desktop Linux <puneet.dev@myyahoo.com> - 1.0.0-1
- Initial release
- Lightweight Microsoft Teams PWA wrapper
- Native desktop integration
- System notifications support
- Deep link handling for Teams URLs
- Multi-format packaging (deb, rpm, pkg.tar.xz, AppImage)