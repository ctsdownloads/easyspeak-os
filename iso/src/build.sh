#!/usr/bin/bash
# Turns the EasySpeakOS image into the live image on the live USB: a live session with EasySpeak working, and
# the EasySpeakOS installer (easyspeak-os-installer/, answered by voice) that puts EasySpeakOS on the computer from
# a copy carried on the USB stick, with no download. Based on the Bazzite example in Universal Blue's titanoboa
# (github.com/ublue-os/titanoboa, Apache-2.0).
set -exo pipefail

IMAGE=ghcr.io/ctsdownloads/easyspeak-os:latest

# Create the directory that /root is symlinked to
mkdir -p "$(realpath /root)"

# ---------------------------------------------------------------- the live session

# EasySpeak lives in /usr/lib/opt/easyspeak and is linked into /opt at boot through /var/opt. A live image has
# no persistent /var, so that link has nothing to land in and EasySpeak would be missing. Make /opt a real
# directory with the link already in place.
rm -f /opt
mkdir -p /opt
ln -sfn /usr/lib/opt/easyspeak /opt/easyspeak
[ -e /opt/easyspeak/venv ] || { echo 'ERROR: EasySpeak is not reachable at /opt/easyspeak'; exit 1; }

# Nothing in the live session updates, sets things up for later, or asks first-login questions: those are for the
# installed system, which gets them on its own first start.
for s in uupd.timer brew-setup.service podman-auto-update.timer tailscaled.service \
         easyspeak-os-codecs-setup.service easyspeak-os-disk-unlock-check.service rpm-ostreed-automatic.timer \
         easyspeak-os-flatpak-apps.service; do
  systemctl disable "$s" 2>/dev/null || true
done
rm -f /etc/xdg/autostart/easyspeak-os-setup-checklist.desktop /etc/xdg/autostart/easyspeak-os-packages-after-restart.desktop

# The live user and its automatic GNOME login
dnf install -y livesys-scripts
sed -i "s/^livesys_session=.*/livesys_session=gnome/" /etc/sysconfig/livesys
systemctl enable livesys.service livesys-late.service

# The welcome window: Install EasySpeakOS, or Try it first (answered by voice)
install -Dm755 /src/easyspeak-os-live-welcome /usr/libexec/easyspeak-os-live-welcome
install -Dm644 /src/easyspeak-os-live-welcome.desktop /etc/xdg/autostart/easyspeak-os-live-welcome.desktop

# ---------------------------------------------------------------- the installer

# The EasySpeakOS installer: every choice by voice, passwords typed. Its screens run as the live user; the part
# that changes the disk (easyspeak-os-install-engine) runs as root through pkexec, allowed without a password for
# the person at the computer by its own polkit action, on the live USB only.
# What it needs: GTK 4 and libadwaita for the window, langtable for the languages and keyboards (as Anaconda uses),
# libpwquality for the password strength, qrencode for the problem report's QR code, the tools that make the
# filesystems, and mdadm to stop a RAID array on a disk being erased.
dnf install -y python3-gobject gtk4 libadwaita python3-langtable python3-pwquality qrencode xkeyboard-config \
    dosfstools xfsprogs cryptsetup mdadm
install -d /usr/lib/easyspeak-os-installer
install -m755 /src/easyspeak-os-installer/easyspeak-os-installer /usr/lib/easyspeak-os-installer/
install -m644 /src/easyspeak-os-installer/*.py /src/easyspeak-os-installer/*.css /usr/lib/easyspeak-os-installer/
ln -sf ../lib/easyspeak-os-installer/easyspeak-os-installer /usr/bin/easyspeak-os-installer
install -Dm755 /src/easyspeak-os-install-engine /usr/libexec/easyspeak-os-install-engine
install -Dm644 /src/io.github.ctsdownloads.easyspeak-os.install.policy \
    /usr/share/polkit-1/actions/io.github.ctsdownloads.easyspeak-os.install.policy
# The restart at the end: run as root (this helper) through pkexec, so it works even when said by voice on a screen
# nobody has touched. Its polkit action allows it without a password, on the live USB only.
install -Dm755 /src/easyspeak-os-reboot /usr/libexec/easyspeak-os-reboot
install -Dm644 /src/io.github.ctsdownloads.easyspeak-os.reboot.policy \
    /usr/share/polkit-1/actions/io.github.ctsdownloads.easyspeak-os.reboot.policy
install -Dm644 /src/io.github.ctsdownloads.EasySpeakOS.Installer.desktop \
    /usr/share/applications/io.github.ctsdownloads.EasySpeakOS.Installer.desktop
install -Dm644 /branding/logo-EasySpeak.svg /usr/share/icons/hicolor/scalable/apps/easyspeak-os-installer.svg
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
install -Dm644 /build-branding/logo-EasySpeak-wide.svg /usr/share/easyspeak-os-installer/logo-wide.svg
# Its language list is Fedora's installer's: the languages Anaconda is translated into (its anaconda.mo files),
# read from the package list without installing Anaconda.
dnf5 repoquery --quiet --setopt=optional_metadata_types=filelists --list anaconda-core \
  | sed -n 's|^/usr/share/locale/\([^/]*\)/LC_MESSAGES/anaconda.mo$|\1|p' | sort -u \
  > /usr/share/easyspeak-os-installer/anaconda-translations.txt

# The dock: the installer first, then Firefox, Files and Bazaar. (The live session's own setup writes Fedora's list, with
# apps this system doesn't have; this file sorts after it, so it wins.)
cat > /usr/share/glib-2.0/schemas/zz2-easyspeak-os-live.gschema.override <<'OVR'
[org.gnome.shell]
favorite-apps=['io.github.ctsdownloads.EasySpeakOS.Installer.desktop', 'org.mozilla.firefox.desktop', 'org.gnome.Nautilus.desktop', 'io.github.kolunmi.Bazaar.desktop']
welcome-dialog-last-shown-version='4294967295'
OVR
glib-compile-schemas /usr/share/glib-2.0/schemas

# What the installer puts on the disk: EasySpeakOS itself, from a copy carried on the USB stick (no download).
# Once installed, the system is pointed at the signed image on GitHub (the engine sets its origin), so its updates
# are checked against the project's signature like on any other EasySpeakOS install.
# For a local test build, build-local-iso.sh puts a copy of the locally built image in /src/payload.oci.tar; it is
# stored under the GitHub name, so the installed system still gets its updates from GitHub.
if [ -f /src/payload.oci.tar ]; then
  loaded=$(podman load -q -i /src/payload.oci.tar | sed -n 's/^Loaded image: //p' | tail -1)
  [ -n "$loaded" ] || { echo "ERROR: the local copy of EasySpeakOS could not be loaded"; exit 1; }
  podman tag "$loaded" "$IMAGE"
  [ "$loaded" = "$IMAGE" ] || podman untag "$IMAGE" "$loaded"
  echo "payload: the locally built image (test build)"
else
  podman pull "$IMAGE"
fi

# ---------------------------------------------------------------- live boot

dnf install -y dracut-live
kernel=$(kernel-install list --json pretty | jq -r '.[] | select(.has_kernel == true) | .version')
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"

# The USB's boot partition (titanoboa copies /boot/efi/EFI onto it): EasySpeakOS's own grub, unsigned, so the USB
# needs Secure Boot off. No Fedora boot files: with Fedora's shim and EFI/fedora folder the boot menu listed the USB
# as "Fedora", editing shim's BOOTX64.CSV did not change that and made the USB vanish from the menu with Secure Boot
# on, and Fedora's grub has /EFI/fedora built in. This grub is made from GRUB's modules with only what the menu
# (iso.yaml, written to grub.cfg by titanoboa) uses, and reads that menu from /EFI/EasySpeakOS. EFI/BOOT/BOOTX64.EFI
# is the file the computer starts from a USB stick; EFI/EasySpeakOS takes the place of EFI/fedora. The installed
# system is not affected: it gets Fedora's signed shim from the copy of EasySpeakOS it installs.
dnf install -y grub2-efi-x64-modules grub2-tools
grub2-mkimage -O x86_64-efi -d /usr/lib/grub/x86_64-efi -p /EFI/EasySpeakOS -o /tmp/easyspeak-os-grub.efi \
    normal boot linux search part_gpt fat iso9660 gzio all_video chain
install -Dm644 /tmp/easyspeak-os-grub.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
install -Dm644 /tmp/easyspeak-os-grub.efi /boot/efi/EFI/EasySpeakOS/grubx64.efi
rm /tmp/easyspeak-os-grub.efi

# Needed for image-builder's buildroot
dnf install -y xorriso isomd5sum squashfs-tools

# The ISO configuration
mkdir -p /usr/lib/bootc-image-builder
cp /src/iso.yaml /usr/lib/bootc-image-builder/iso.yaml

dnf clean all

# ---------------------------------------------------------------- checks: fail the build, never ship it wrong

fail() { echo "ERROR: $*"; exit 1; }
rpm -q anaconda-core >/dev/null 2>&1 && fail "Fedora's installer (Anaconda) is still on the USB"
for f in /usr/bin/easyspeak-os-installer /usr/libexec/easyspeak-os-install-engine; do
  [ -x "$f" ] || fail "$f is missing"
done
[ -s /usr/share/applications/io.github.ctsdownloads.EasySpeakOS.Installer.desktop ] || fail "the installer's launcher is missing"
[ -s /usr/share/polkit-1/actions/io.github.ctsdownloads.easyspeak-os.install.policy ] || fail "the installer's polkit action is missing"
[ -x /usr/libexec/easyspeak-os-reboot ] || fail "the reboot helper is missing (the restart at the end of the install)"
[ -s /usr/share/polkit-1/actions/io.github.ctsdownloads.easyspeak-os.reboot.policy ] || fail "the reboot helper's polkit action is missing"
grep -q '<allow_any>yes</allow_any>' /usr/share/polkit-1/actions/io.github.ctsdownloads.easyspeak-os.reboot.policy \
  || fail "the reboot action must allow any session, so restart by voice works on a screen nobody has touched"
[ -s /usr/share/easyspeak-os-installer/logo-wide.svg ] || fail "the installer's EasySpeakOS logo is missing"
[ "$(wc -l < /usr/share/easyspeak-os-installer/anaconda-translations.txt)" -ge 50 ] || fail "the installer's language list is missing"
command -v qrencode >/dev/null || fail "qrencode is missing (the problem report's QR code)"
for tool in mdadm dmsetup cryptsetup mkfs.fat mkfs.ext4 mkfs.xfs sfdisk wipefs hwclock; do
  command -v "$tool" >/dev/null || fail "$tool is missing (the install engine uses it)"
done
# The install engine's bootc steps: copy without finishing, write the settings, then finish.
bootc install to-filesystem --help | grep -q -- '--skip-finalize' || fail "bootc has no install to-filesystem --skip-finalize"
bootc install to-filesystem --help | grep -q -- '--bootloader' || fail "bootc has no install to-filesystem --bootloader"
bootc install finalize --help >/dev/null 2>&1 || fail "bootc has no install finalize"
# Every language offered must work on the installed system, which is this same image.
rpm -q glibc-all-langpacks >/dev/null || fail "glibc-all-langpacks is missing: the languages offered would not work"
# The installer's window can start (GTK 4, libadwaita, the strength meter), and its lists read the way it reads them:
# languages, keyboards, keyboards for the disk password, time zones.
python3 -I -c '
import sys; sys.path.insert(0, "/usr/lib/easyspeak-os-installer")
import gi; gi.require_version("Gtk", "4.0"); gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk
import data, pwquality
assert len(data.languages()) >= 50, "languages"
assert len(data.keyboards()) >= 500, "keyboards"
# kbd-misc comes with the system image itself (kbd requires it), so the installed system has these keymaps too.
assert data.has_console_keymap("us") and data.has_console_keymap("de(nodeadkeys)"), "keyboards for the disk password"
assert len(data.timezones()) >= 9, "time zones"
' || fail "the installer's lists could not be read"
grep -qi 'fedora' /etc/system-release && fail "/etc/system-release still says Fedora"
podman image exists "$IMAGE" || fail "the copy of EasySpeakOS for the installer is missing"
[ "$(ls /boot/efi/EFI | tr '\n' ' ')" = "BOOT EasySpeakOS " ] || fail "the USB's boot partition must hold only EFI/BOOT and EFI/EasySpeakOS (no shim, no EFI/fedora)"
[ "$(ls /boot/efi/EFI/BOOT)" = BOOTX64.EFI ] && [ "$(ls /boot/efi/EFI/EasySpeakOS)" = grubx64.efi ] || fail "the USB's boot files are not just the EasySpeakOS grub"
grep -rqi fedora /boot/efi && fail "a file on the USB's boot partition still contains Fedora"
# The install copies the image one layer at a time through the live session's memory: a few huge layers fill it
# up ("no space left on device"). The published image is split into many small layers; a local one must be too.
[ "$(podman image inspect "$IMAGE" --format '{{len .RootFS.Layers}}')" -ge 20 ] || fail "the copy of EasySpeakOS for the installer is not split into small layers"
echo "live image ready: installer in place, payload $IMAGE present"
