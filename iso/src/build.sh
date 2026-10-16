#!/usr/bin/bash
# Turns the EasySpeakOS image into the live image on the live USB: a live session with EasySpeak working, and
# the installer (Fedora's Anaconda, with EasySpeakOS's name and logo) that puts EasySpeakOS on the computer from
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

dnf install -y anaconda-live anaconda-webui libblockdev-btrfs libblockdev-lvm libblockdev-dm
mkdir -p /var/lib/rpm-state      # the installer's web interface needs it
install -Dm644 /src/easyspeak-os.conf /etc/anaconda/profile.d/easyspeak-os.conf
printf 'EasySpeakOS release 44\n' > /etc/system-release

# Its name everywhere the installer shows one. The installer's pages (and their translations) have three
# sentences with "Fedora" in them: "Welcome to Fedora Linux", "Fedora linux requires at least ... of disk space"
# and "Reinstall Fedora". The last one is also how it recognises an existing install to reinstall over, which
# is then an existing EasySpeakOS. Debug maps (.map) are not used by the installer and are removed.
for f in /usr/share/cockpit/anaconda-webui/*.js.gz; do
  zcat "$f" | sed -e 's/Fedora Linux/EasySpeakOS/g; s/Fedora linux/EasySpeakOS/g; s/Fedora/EasySpeakOS/g' | gzip -9n > "$f.new"
  mv "$f.new" "$f"
done
rm -f /usr/share/cockpit/anaconda-webui/*.map /usr/share/cockpit/anaconda-webui/*.map.gz
# The Beta badge, no Fedora feedback block or QR code, and problem reports to GitHub (see that script).
python3 /src/easyspeak-os-installer-text.py /usr/share/cockpit/anaconda-webui/index.js.gz
mv /usr/share/cockpit/anaconda-webui/index.js.gz.new /usr/share/cockpit/anaconda-webui/index.js.gz
rm -f /usr/share/cockpit/anaconda-webui/qr-code-feedback.svg

# Fedora's own live welcome screen ("Welcome to Fedora") is replaced by the EasySpeakOS one above.
rm -rf /usr/share/anaconda/gnome

# The installer's launcher: its name, and the EasySpeakOS logo as its icon (also under the name the installer's
# own window asks for).
sed -i -e 's/^Name=.*/Name=Install EasySpeakOS/' -e '/^Name\[/d' \
       -e 's/^Comment=.*/Comment=Put EasySpeakOS on this computer/' -e '/^Comment\[/d' \
       -e 's/^Icon=.*/Icon=easyspeak-os-installer/' -e 's/X-Fedora;//' /usr/share/applications/liveinst.desktop
for n in easyspeak-os-installer org.fedoraproject.AnacondaInstaller; do
  install -Dm644 /branding/logo-EasySpeak.svg "/usr/share/icons/hicolor/scalable/apps/$n.svg"
done
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true

# The logo at the top of the installer's pages. The installer's page server looks for a folder named after the
# system's ID (easyspeak-os) before the generic one, so this one is used.
b=/usr/share/cockpit/branding/easyspeak-os
install -Dm644 /branding/logo-EasySpeak.svg "$b/logo.svg"
cat > "$b/branding.css" <<'CSS'
.anaconda {
    --brand-default-light: #4facfe;
    --brand-default: #1f6fd1;
    --brand-default-dark: #144a8c;

    .logo {
        background-image: url("logo.svg");
        filter: none;
        mix-blend-mode: normal;
    }
}

:not(.pf-v6-theme-dark) .anaconda {
    --pf-t--global--color--brand--default: var(--brand-default);
    --pf-t--global--color--brand--hover: var(--brand-default-dark);
}

.pf-v6-theme-dark .anaconda {
    --pf-t--global--color--brand--default: var(--brand-default-light);
    --pf-t--global--color--brand--hover: var(--brand-default);
}
CSS

# The dock: the installer first, then Firefox and Files. (The live session's own setup writes Fedora's list, with
# apps this system doesn't have; this file sorts after it, so it wins.)
cat > /usr/share/glib-2.0/schemas/zz2-easyspeak-os-live.gschema.override <<'OVR'
[org.gnome.shell]
favorite-apps=['anaconda.desktop', 'org.mozilla.firefox.desktop', 'org.gnome.Nautilus.desktop']
welcome-dialog-last-shown-version='4294967295'
OVR
glib-compile-schemas /usr/share/glib-2.0/schemas

# What the installer puts on the disk: EasySpeakOS itself, from a copy carried on the USB stick (no download).
# Once installed, the system is pointed at the signed image on GitHub, so its updates are checked against the
# project's signature like on any other EasySpeakOS install.
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
cat >> /usr/share/anaconda/interactive-defaults.ks <<KS

ostreecontainer --url=$IMAGE --transport=containers-storage --no-signature-verification

%post --erroronfail --log=/tmp/easyspeak-os-signed-updates.log
set -x
for f in /ostree/deploy/*/deploy/*.origin; do
  sed -i 's|^container-image-reference=.*|container-image-reference=ostree-image-signed:docker://$IMAGE|' "\$f"
  grep -q '^container-image-reference=ostree-image-signed:docker://$IMAGE\$' "\$f"
done
%end
KS

# ---------------------------------------------------------------- live boot

dnf install -y dracut-live
kernel=$(kernel-install list --json pretty | jq -r '.[] | select(.has_kernel == true) | .version')
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"

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

# ---------------------------------------------------------------- checks: fail the build, never ship it wrong

fail() { echo "ERROR: $*"; exit 1; }
for f in /usr/share/cockpit/anaconda-webui/*; do
  case "$f" in *.gz) zgrep -q 'Fedora' "$f" && fail "the installer still says Fedora in $f" ;; *) grep -q 'Fedora' "$f" && fail "the installer still says Fedora in $f" ;; esac
done
grep -q 'Fedora' /usr/share/applications/liveinst.desktop && fail "the installer's launcher still says Fedora"
zgrep -q 'fedoraproject.org/' /usr/share/cockpit/anaconda-webui/index.js.gz && fail "the installer still links to Fedora"
zgrep -q 'gg("Beta")' /usr/share/cockpit/anaconda-webui/index.js.gz || fail "the installer's Beta badge is missing"
[ -e /usr/share/cockpit/anaconda-webui/qr-code-feedback.svg ] && fail "Fedora's feedback QR code is still there"
[ -e /usr/share/anaconda/gnome ] && fail "Fedora's live welcome screen is still there"
[ -s /usr/share/cockpit/branding/easyspeak-os/logo.svg ] && grep -q 'logo.svg' /usr/share/cockpit/branding/easyspeak-os/branding.css || fail "the installer's EasySpeakOS logo is missing"
grep -qx 'PRETTY_NAME="EasySpeakOS"' /usr/lib/os-release || fail "the system name is not EasySpeakOS (the installer shows it in its title)"
grep -qi 'fedora' /etc/system-release && fail "/etc/system-release still says Fedora"
grep -q '^os_id = easyspeak-os$' /etc/anaconda/profile.d/easyspeak-os.conf || fail "the installer profile is missing"
podman image exists "$IMAGE" || fail "the copy of EasySpeakOS for the installer is missing"
# The installer copies the image one layer at a time through the live session's memory: a few huge layers fill it
# up ("no space left on device"). The published image is split into many small layers; a local one must be too.
[ "$(podman image inspect "$IMAGE" --format '{{len .RootFS.Layers}}')" -ge 20 ] || fail "the copy of EasySpeakOS for the installer is not split into small layers"
grep -q "^ostreecontainer --url=$IMAGE " /usr/share/anaconda/interactive-defaults.ks || fail "the installer isn't set to install EasySpeakOS"
echo "live image ready: installer branded, payload $IMAGE present"
