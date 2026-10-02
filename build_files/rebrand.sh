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

dnf5 -y install --allowerasing generic-logos generic-release
rpm -q generic-logos generic-release
if rpm -q fedora-logos fedora-release-common >/dev/null 2>&1; then echo "ERROR: Fedora branding packages are still installed"; exit 1; fi
dnf5 -y remove fedora-bookmarks || echo "note: fedora-bookmarks was not removed"

# The image's own name. ID_LIKE keeps tools that look for a Fedora-family system working.
cat > /usr/lib/os-release <<'OSREL'
NAME="speakfin"
ID=speakfin
ID_LIKE="fedora"
VERSION_ID=44
VERSION="44"
PLATFORM_ID="platform:f44"
PRETTY_NAME="speakfin 44"
ANSI_COLOR="0;34"
HOME_URL="https://github.com/ctsdownloads/speakfin"
DOCUMENTATION_URL="https://github.com/ctsdownloads/speakfin"
SUPPORT_URL="https://github.com/ctsdownloads/speakfin/issues"
BUG_REPORT_URL="https://github.com/ctsdownloads/speakfin/issues"
OSREL
ln -sf ../usr/lib/os-release /etc/os-release
echo "rebranded: $(. /usr/lib/os-release; echo "$PRETTY_NAME")"
