%global debug_package %{nil}
%define _lto_cflags %{nil}

Name:           libfprint-tod
Version:        1.94.10
Release:        1%{?dist}
Summary:        libfprint with Touch OEM Drivers (TOD) support

License:        LGPL-2.1-or-later AND NIST-PD
URL:            https://gitlab.freedesktop.org/3v1n0/libfprint
Source0:        libfprint-v%{version}+tod1.tar.gz

Provides:       libfprint = %{version}-%{release}
Provides:       libfprint%{?_isa} = %{version}-%{release}
Obsoletes:      libfprint

BuildRequires:  meson
BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  git
BuildRequires:  openssl-devel
BuildRequires:  pkgconfig(glib-2.0) >= 2.50
BuildRequires:  pkgconfig(gio-2.0) >= 2.44.0
BuildRequires:  pkgconfig(gusb) >= 0.3.0
BuildRequires:  pkgconfig(nss)
BuildRequires:  pkgconfig(pixman-1)
BuildRequires:  libgudev-devel
BuildRequires:  systemd
BuildRequires:  gobject-introspection-devel
BuildRequires:  cairo-devel

%description
Fork of libfprint that loads external Touch OEM Driver (TOD) modules from
%{_libdir}/libfprint-2/tod-1/.

%prep
%autosetup -S git -n libfprint-v%{version}+tod1

%build
%meson -Ddrivers=all -Ddoc=false -Dgtk-examples=false -Dinstalled-tests=false --buildtype release
%meson_build

%install
%meson_install

%ldconfig_scriptlets

%files
%license COPYING
%doc NEWS THANKS AUTHORS README.md
%{_libdir}/*.so.*
%{_libdir}/*.so
%{_libdir}/girepository-1.0/*.typelib
%{_includedir}/*
%{_libdir}/pkgconfig/*.pc
%{_datadir}/gir-1.0/*.gir
%{_udevhwdbdir}/60-autosuspend-libfprint-2.hwdb
%{_udevrulesdir}/70-libfprint-2.rules
%{_datadir}/metainfo/*

%changelog
* Thu Oct 01 2026 xps image <noreply@example.invalid> - 1.94.10-1
- Build libfprint-TOD from source against the base image
