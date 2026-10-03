#!/usr/bin/bash
# Turns the EasySpeak-OS image into a live image. Adapted from the Fedora Kinoite live-ISO example.
set -exo pipefail

# Create the directory that /root is symlinked to
mkdir -p "$(realpath /root)"

# Live-boot support in the initramfs
dnf install -y dracut-live
kernel=$(kernel-install list --json pretty | jq -r '.[] | select(.has_kernel == true) | .version')
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"

# EasySpeak lives in /usr/lib/opt/easyspeak and is linked into /opt at boot through /var/opt. A live image has
# no persistent /var, so that link has nothing to land in and EasySpeak would be missing. Make /opt a real
# directory with the link already in place.
rm -f /opt
mkdir -p /opt
ln -sfn /usr/lib/opt/easyspeak /opt/easyspeak
[ -e /opt/easyspeak/venv ] || { echo 'ERROR: EasySpeak is not reachable at /opt/easyspeak'; exit 1; }

# The live user and its automatic GNOME login
dnf install -y livesys-scripts
sed -i "s/^livesys_session=.*/livesys_session=gnome/" /etc/sysconfig/livesys
systemctl enable livesys.service livesys-late.service

# image-builder needs gcdx64.efi, and expects the EFI directory in /boot/efi
dnf install -y grub2-efi-x64-cdboot
mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/

# Needed for image-builder's buildroot
dnf install -y xorriso isomd5sum squashfs-tools

# The ISO configuration
mkdir -p /usr/lib/bootc-image-builder
cp /src/iso.yaml /usr/lib/bootc-image-builder/iso.yaml

dnf clean all
