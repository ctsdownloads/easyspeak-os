#!/bin/bash
# Rebuild the initramfs so the boot splash and the disk-unlock (LUKS) screen use a blank watermark
# instead of Fedora's logo. The initramfs holds its own copy of the splash artwork, built before
# our branding changes, so the logo only changes when it is rebuilt.
# The original was built with: dracut --reproducible -v --add ostree --tmpdir /tmp/dracut -f --no-hostonly
# This step FAILS the build if the new initramfs lacks anything needed to unlock a disk or boot,
# or if the old logo is still inside it.
set -euo pipefail

kvers=(/usr/lib/modules/*/)
[ "${#kvers[@]}" -eq 1 ] || { echo "ERROR: expected exactly one kernel, found ${#kvers[@]}"; exit 1; }
KVER=$(basename "${kvers[0]}")
IMG=/usr/lib/modules/$KVER/initramfs.img
[ -f "$IMG" ] || { echo "ERROR: $IMG not found"; exit 1; }
mode=$(stat -c %a "$IMG")

# Blank logos (generic-logos would otherwise show its hot-dog mascot).
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

export DRACUT_NO_XATTR=1
mkdir -p /tmp/dracut
dracut --reproducible -v --add ostree --tmpdir /tmp/dracut -f --no-hostonly --kver "$KVER" "$IMG"
chmod "$mode" "$IMG"

# Safety checks: everything needed to unlock an encrypted disk and boot an ostree system.
mods=$(lsinitrd -m "$IMG")
for m in ostree crypt plymouth dm lvm systemd-cryptsetup kernel-modules; do
  printf '%s\n' "$mods" | grep -qx "$m" || { echo "ERROR: the new initramfs lacks dracut module: $m"; exit 1; }
done
# The splash artwork inside the initramfs must now be the blank logo.
want=$(sha256sum /usr/share/pixmaps/system-logo-white.png | cut -d' ' -f1)
got=$(lsinitrd "$IMG" -f usr/share/plymouth/themes/spinner/watermark.png | sha256sum | cut -d' ' -f1)
[ "$want" = "$got" ] || { echo "ERROR: the boot splash inside the initramfs still has the old logo"; exit 1; }
echo "initramfs rebuilt for $KVER: $(du -h "$IMG" | cut -f1), modules ok, blank splash logo in place"
