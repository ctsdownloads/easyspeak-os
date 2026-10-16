#!/usr/bin/bash
# Builds a test live ISO on this computer from the code in this folder, so it can be tried on a USB stick before
# anything goes to GitHub. Three steps: the EasySpeakOS image, the live variant on top of it (carrying that same
# image as the copy to install), then the ISO, made by Universal Blue's titanoboa.
#
# Run it from a normal terminal (not inside a toolbox or distrobox), at the top of the repository:
#   iso/build-local-iso.sh
# It asks for your password once (sudo), and needs about 70 GB free. The ISO ends up in ~/Downloads/easyspeak-os-iso/.
set -euo pipefail
trap 'echo; echo "STOPPED at: $BASH_COMMAND"' ERR

if [ -e /run/.containerenv ] || [ -n "${CONTAINER_ID:-}" ]; then
  echo "This terminal is inside a container (toolbox or distrobox). Run this in a normal terminal."; exit 1
fi
cd "$(dirname "$0")/.."
free=$(df --output=avail -BG . | tail -1 | tr -dc 0-9)
[ "$free" -ge 70 ] || { echo "Only ${free} GB free here. It needs 70 GB."; exit 1; }

out="$HOME/Downloads/easyspeak-os-iso"
payload=iso/src/payload.oci.tar
token=$(mktemp)      # empty: the build then downloads from GitHub without signing in, as anyone can

# Ask for the password once and keep it fresh until the end (the steps take longer than sudo remembers it).
sudo -v
while true; do sudo -n true; sleep 50; done 2>/dev/null &
keepalive=$!
trap 'kill $keepalive 2>/dev/null; rm -f "$token"; sudo rm -f "$payload"' EXIT

# Step 1 is the slowest. It is skipped when the files it is built from (Containerfile, build_files/, system_files/)
# are exactly the same as for the image already built here; delete that image to force it:
#   sudo podman rmi localhost/easyspeak-os
stamp="$HOME/.cache/easyspeak-os-local-image-v2"   # v2: images built before --no-cache are not trusted
src=$(git ls-files -s Containerfile build_files system_files | sha256sum | cut -c1-16)
git diff --quiet HEAD -- Containerfile build_files system_files || src="changed-$(date +%s)"
if [ "$(cat "$stamp" 2>/dev/null)" = "$src" ] && sudo podman image exists localhost/easyspeak-os; then
  echo "== 1 of 3: the EasySpeakOS image: unchanged since the last build here, using that one"
else
  rm -f "$stamp"
  echo "== 1 of 3: the EasySpeakOS image"
  # --no-cache: podman's saved steps don't notice changed build files (they come in through a bind mount), so a
  # saved step could bring back an old image. The GitHub build always starts clean.
  sudo podman build --no-cache --secret id=GITHUB_TOKEN,src="$token" -t localhost/easyspeak-os -f Containerfile .
  # Split it into many smaller layers, exactly as the GitHub build does (the Justfile's ostree-rechunk). The
  # installer copies the image one layer at a time through the live session's memory, so one huge layer fills it
  # up ("no space left on device" in /var/tmp).
  graphroot=$(sudo podman info --format '{{.Store.GraphRoot}}')
  sudo podman run --rm --pull=never --privileged \
    --mount=type=image,src=localhost/easyspeak-os,target=/rpm-ostree \
    --mount=type=bind,src="$graphroot",target=/run/host-container-storage,rw \
    --mount=type=tmpfs,target=/run/rpm-ostree-storage \
    --entrypoint /usr/bin/rpm-ostree localhost/easyspeak-os \
    compose build-chunked-oci --max-layers 127 --format-version=2 --bootc --rootfs /rpm-ostree \
    --output "containers-storage:[overlay@/run/host-container-storage+/run/rpm-ostree-storage]localhost/easyspeak-os:latest"
  sudo podman image prune -f >/dev/null      # the unsplit copy
  mkdir -p "$(dirname "$stamp")" && echo "$src" > "$stamp"
fi
layers=$(sudo podman image inspect localhost/easyspeak-os --format '{{len .RootFS.Layers}}')
[ "$layers" -ge 20 ] || { echo "The EasySpeakOS image has only $layers layers; it was not split. Stopping."; exit 1; }
# The image must be built from the files in this folder, not an older build: its system name and a new-ish file must
# match what is here.
want=$(sed -n 's/^PRETTY_NAME="\(.*\)"$/\1/p' build_files/rebrand.sh)
got=$(sudo podman run --rm --pull=never --entrypoint /usr/bin/sh localhost/easyspeak-os -c '. /usr/lib/os-release; echo "$PRETTY_NAME"; cat /etc/dconf/db/distro.d/50-easyspeak-os-quick-settings >/dev/null && echo qs-ok')
[ "$got" = "$want
qs-ok" ] || { echo "The EasySpeakOS image is not built from this folder (it says: $got). Stopping."; exit 1; }
echo "image checked: built from this folder ($want)"

echo "== 2 of 3: the live variant, with that image as the copy to install"
sudo rm -f "$payload"
sudo podman save --format oci-archive -o "$payload" localhost/easyspeak-os
sudo podman build --no-cache --cap-add sys_admin --security-opt label=disable --squash \
  --build-arg BASE_IMAGE=localhost/easyspeak-os -t localhost/easyspeak-os-live -f iso/Containerfile .
sudo rm -f "$payload"

echo "== Checking every change inside the built system and the USB system"
iso/verify-image.sh localhost/easyspeak-os localhost/easyspeak-os-live

echo "== 3 of 3: the ISO"
[ -d "$HOME/titanoboa" ] || git clone --depth 1 https://github.com/ublue-os/titanoboa.git "$HOME/titanoboa"
mkdir -p "$out"
(cd "$HOME/titanoboa" && sudo TITANOBOA_CTR_IMAGE=localhost/easyspeak-os-live TITANOBOA_OUTPUT_DIR="$out" ./main.sh)
ls -lh "$out"
echo "Done. Write the .iso above to a USB stick with GNOME Disks (Restore Disk Image) or Fedora Media Writer."
