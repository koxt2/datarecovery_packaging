# spec file for package datarecovery (Copr build)

Name:           datarecovery
Version:        0.7.1
Release:        %autorelease
Summary:        GTK4/Libadwaita application for data recovery
License:        GPL-2.0-or-later
BuildArch:      noarch
URL:            https://github.com/koxt2/DataRecovery
Source0:        %url/archive/refs/tags/v%{version}.tar.gz
Source1:        %name-rpmlintrc

BuildRequires:  meson >= 1.0.0
BuildRequires:  pkgconfig
BuildRequires:  python3-devel
BuildRequires:  pkgconfig(gtk4)
BuildRequires:  pkgconfig(libadwaita-1)
BuildRequires:  pkgconfig(gio-2.0)
BuildRequires:  desktop-file-utils
BuildRequires:  libappstream-glib

Requires:       python3
Requires:       python3-gobject
Requires:       gtk4
Requires:       libadwaita
Requires:       ddrescue
Requires:       testdisk
Requires:       rdfind
Requires:       udisks2
Requires:       polkit
Requires:       hicolor-icon-theme
Requires:       dbus-common

%description
A GTK4/Libadwaita application for data recovery using ddrescue and PhotoRec. 
Recovers all files (not just deleted ones) from storage devices or disk images, 
organizes them by file type, and optionally removes duplicates using rdfind.

%prep
%autosetup -n DataRecovery-%{version}

%build
%meson
%meson_build

%install
%meson_install

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/datarecovery.desktop
appstream-util validate-relax --nonet %{buildroot}%{_metainfodir}/*.metainfo.xml

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/datarecovery
%{_bindir}/datarecovery-pkexec-helper
%{_datadir}/datarecovery/
%{_datadir}/applications/datarecovery.desktop
%{_datadir}/dbus-1/services/com.github.koxt2.datarecovery.service
%{_datadir}/icons/hicolor/*/apps/com.github.koxt2.datarecovery*.*
%{_datadir}/metainfo/com.github.koxt2.datarecovery.metainfo.xml
%{_datadir}/polkit-1/actions/datarecovery.policy

%changelog
%autochangelog