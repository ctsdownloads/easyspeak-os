#!/bin/bash
set -ouex pipefail

ver=1.94.10
commit=d9b7879b45c4bb1b8cbe25b02d0adb10c5befeba

dnf5 -y install rpm-build git meson gcc gcc-c++ openssl-devel glib2-devel libgusb-devel nss-devel pixman-devel libgudev-devel gobject-introspection-devel systemd-devel cairo-devel python3-gobject

git clone --branch "v${ver}+tod1" https://gitlab.freedesktop.org/3v1n0/libfprint.git /tmp/libfprint
test "$(git -C /tmp/libfprint rev-parse HEAD)" = "$commit"

top=/var/tmp/rpmbuild
mkdir -p "$top/SOURCES" "$top/SPECS" /out
git -C /tmp/libfprint archive --format=tar.gz --prefix="libfprint-v${ver}+tod1/" -o "$top/SOURCES/libfprint-v${ver}+tod1.tar.gz" HEAD
cp /ctx/libfprint-tod.spec "$top/SPECS/"
rpmbuild --define "_topdir $top" -bb "$top/SPECS/libfprint-tod.spec"
cp "$top"/RPMS/x86_64/libfprint-tod-${ver}-*.rpm /out/

rpm --import /ctx/rpms/pubkey.gpg
rpm -K /ctx/rpms/libfprint-tod-goodix-*.x86_64.rpm
dnf5 -y install /out/libfprint-tod-*.rpm /ctx/rpms/libfprint-tod-goodix-*.x86_64.rpm
if rpm -q libfprint >/dev/null 2>&1; then
  echo "stock libfprint is still installed"
  exit 1
fi
out=$(G_MESSAGES_DEBUG=all python3 -c 'import gi; gi.require_version("FPrint","2.0"); from gi.repository import FPrint; FPrint.Context()' 2>&1)
echo "$out"
echo "$out" | grep -q 'Loading driver goodix-tod'
