#!/bin/bash
# Rebuild the initramfs so the boot splash and the disk-unlock (LUKS) screen carry no Fedora logo.
# The initramfs holds its own copy of the splash artwork, built before our branding changes, so the
# logo only changes when it is rebuilt. The Fedora wordmark on those screens is
# /usr/share/plymouth/themes/spinner/watermark.png, which came from fedora-logos. That package is
# gone by now, so this installs the EasySpeak-OS logo in its place and checks that it is what
# ended up inside the new initramfs.
# The original was built with: dracut --reproducible -v --add ostree --tmpdir /tmp/dracut -f --no-hostonly
# This step FAILS the build if the new initramfs lacks anything needed to unlock a disk or boot,
# or if the splash artwork inside it is not the EasySpeak-OS logo.
set -euo pipefail

kvers=(/usr/lib/modules/*/)
[ "${#kvers[@]}" -eq 1 ] || { echo "ERROR: expected exactly one kernel, found ${#kvers[@]}"; exit 1; }
KVER=$(basename "${kvers[0]}")
IMG=/usr/lib/modules/$KVER/initramfs.img
[ -f "$IMG" ] || { echo "ERROR: $IMG not found"; exit 1; }
mode=$(stat -c %a "$IMG")

# Blank logos. The generic-logos package would otherwise show its hot-dog mascot.
python3 - <<'PY'
import zlib, struct
def chunk(t, d):
    c = struct.pack('>I', len(d)) + t + d
    return c + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
def blank(path, w, h):
    raw = b''.join(b'\x00' + b'\x00' * (w * 4) for _ in range(h))
    png = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
           + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))
    open(path, 'wb').write(png)
blank('/usr/share/pixmaps/system-logo-white.png', 240, 310)
blank('/usr/share/pixmaps/fedora-logo.png', 240, 310)
blank('/usr/share/pixmaps/fedora-logo-small.png', 128, 128)
PY
# The EasySpeak-OS logo, drawn at the bottom of the boot and disk-unlock screens.
[ -f /ctx/branding/boot-watermark.png ] || { echo 'ERROR: /ctx/branding/boot-watermark.png is missing'; exit 1; }
install -Dm644 /ctx/branding/boot-watermark.png /usr/share/plymouth/themes/spinner/watermark.png

export DRACUT_NO_XATTR=1
mkdir -p /tmp/dracut
dracut --reproducible -v --add ostree --tmpdir /tmp/dracut -f --no-hostonly --kver "$KVER" "$IMG"
chmod "$mode" "$IMG"

# Safety checks: everything needed to unlock an encrypted disk and boot an ostree system.
mods=$(lsinitrd -m "$IMG")
for m in ostree crypt plymouth dm lvm systemd-cryptsetup kernel-modules; do
  grep -qx "$m" <<< "$mods" || { echo "ERROR: the new initramfs lacks dracut module: $m"; exit 1; }
done

# The splash artwork inside the initramfs must be the EasySpeak-OS logo.
WM=usr/share/plymouth/themes/spinner/watermark.png
want=$(sha256sum /ctx/branding/boot-watermark.png | cut -d' ' -f1)
listing=$(lsinitrd "$IMG")
if ! grep -qE " ${WM}\$" <<< "$listing"; then
  echo "ERROR: $WM is missing from the new initramfs"; exit 1
fi
got=$(lsinitrd "$IMG" -f "$WM" | sha256sum | cut -d' ' -f1)
[ "$want" = "$got" ] || { echo "ERROR: the splash artwork inside the new initramfs is not the EasySpeak-OS logo (expected ${want:0:12}, found ${got:0:12})"; exit 1; }
echo "initramfs rebuilt for $KVER: $(du -h "$IMG" | cut -f1), modules ok, EasySpeak-OS logo in place"
