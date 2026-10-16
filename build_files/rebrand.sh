#!/bin/bash
# Replace Fedora's trademarked branding packages with the generic ones, and give the image its own name.
# Fedora's trademark guidelines ask for fedora-logos, fedora-release and fedora-release-notes to be
# removed or replaced when Fedora software is modified and redistributed.
# Unlike the codec step, this FAILS the build if anything looks wrong: a published image must not
# ship Fedora's branding by accident.
set -euo pipefail

plan=$(dnf5 install --assumeno --allowerasing generic-logos generic-release 2>&1 || true)
# dnf5 lists packages that would go away under a "Removing ..." heading, or as "replacing NAME" lines
removed=$(printf '%s\n' "$plan" | awk '
/^Removing[A-Za-z ]*:$/ {rm=1; next}
/^[A-Z][A-Za-z ]*:$/ {rm=0}
rm && NF {print $1; next}
/^[[:space:]]+replacing[[:space:]]/ {print $2}')
if [ -z "$removed" ]; then
  echo "ERROR: the rebranding plan removes nothing. Did dnf's output change?"; printf '%s\n' "$plan" | tail -20; exit 1
fi
bad=$(printf '%s\n' "$removed" | grep -vE '^(fedora-logos|fedora-release(-[a-z0-9-]+)?)$' || true)
if [ -n "$bad" ]; then echo "ERROR: rebranding would also remove: $(echo $bad)"; exit 1; fi

# Fedora's release packages also hold Fedora's default list of services that switch on by themselves (systemd
# presets). Keep that list exactly as Fedora ships it: copy the files out now, put them back after the swap.
keep=$(mktemp -d)
for f in $(rpm -ql fedora-release-common fedora-release-identity-silverblue fedora-release-silverblue 2>/dev/null | grep -E '^/usr/lib/systemd/(system|user)-preset/[^/]+[.]preset$'); do
  mkdir -p "$keep$(dirname "$f")"; cp -a "$f" "$keep$f"
done
[ -f "$keep/usr/lib/systemd/system-preset/90-default.preset" ] || { echo "ERROR: Fedora's preset files were not found"; exit 1; }

dnf5 -y install --allowerasing generic-logos generic-release
rpm -q generic-logos generic-release
if rpm -q fedora-logos fedora-release-common >/dev/null 2>&1; then echo "ERROR: Fedora branding packages are still installed"; exit 1; fi

# Put Fedora's preset files back as NN-name-fedora.preset. That name sorts just before the generic package's
# NN-name.preset, so Fedora's lines win, exactly as on Fedora.
for f in $(cd "$keep" && find usr -name '*.preset'); do
  install -Dm644 "$keep/$f" "/$(dirname "$f")/$(basename "$f" .preset)-fedora.preset"
done
rm -rf "$keep"

# The image's own name. ID_LIKE keeps tools that look for a Fedora-family system working.
cat > /usr/lib/os-release <<'OSREL'
NAME="EasySpeakOS"
ID=easyspeak-os
ID_LIKE="fedora"
VERSION_ID=44
VERSION="44"
PLATFORM_ID="platform:f44"
PRETTY_NAME="EasySpeakOS"
ANSI_COLOR="0;34"
HOME_URL="https://github.com/ctsdownloads/easyspeak-os"
DOCUMENTATION_URL="https://github.com/ctsdownloads/easyspeak-os"
SUPPORT_URL="https://github.com/ctsdownloads/easyspeak-os/issues"
BUG_REPORT_URL="https://github.com/ctsdownloads/easyspeak-os/issues"
OSREL
ln -sf ../usr/lib/os-release /etc/os-release
echo "rebranded: $(. /usr/lib/os-release; echo "$PRETTY_NAME")"
