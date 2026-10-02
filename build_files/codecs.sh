#!/bin/bash
# Full ffmpeg codecs from negativo17, the repo Universal Blue uses.
# This step never fails the build. If anything looks risky it skips the swap and says why.
set -uo pipefail
warn() { echo "WARNING: full codecs not installed: $*"; }
REPO=/etc/yum.repos.d/fedora-multimedia.repo
PKGS="ffmpeg ffmpeg-libs libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale x264-libs x265-libs"
curl -fsSL --retry 3 https://negativo17.org/repos/fedora-multimedia.repo -o "$REPO" || { warn "could not download the repo file"; exit 0; }
dnf5 config-manager setopt fedora-multimedia.priority=90 || { warn "could not set the repo priority"; rm -f "$REPO"; exit 0; }
plan=$(dnf5 install --assumeno --allowerasing --setopt=install_weak_deps=False $PKGS 2>&1) || true
# dnf5 lists swapped-out packages as "replacing NAME" lines (an upgrade of the same name is not a removal)
# and real removals under "Removing:". Collect every package name that would go away.
removed=$(printf '%s\n' "$plan" | awk '
/^Removing:/ {rm=1; next}
/^[A-Z][A-Za-z ]*:$/ {rm=0}
rm && NF {print $1; next}
/^[[:space:]]+replacing[[:space:]]/ { if ($2 != prev) print $2; next }
/^[[:space:]]+[A-Za-z0-9]/ { prev=$1 }')
bad=$(printf '%s\n' "$removed" | grep -vE '^(ffmpeg-free|lib(av|sw|postproc)[a-z]*-free)$' | grep . || true)
if [ -n "$bad" ]; then warn "the swap would also remove: $(echo $bad)"; rm -f "$REPO"; exit 0; fi
dnf5 -y install --allowerasing --setopt=install_weak_deps=False $PKGS || { warn "the install failed"; rm -f "$REPO"; exit 0; }
rpm -q ffmpeg libavcodec x264-libs x265-libs || { warn "packages missing after install"; exit 0; }
echo "full codecs installed: $(rpm -q --qf '%{NAME}-%{VERSION} ' ffmpeg x264-libs x265-libs)"
# keep the repo out of the running system: it is only needed while the image is built
dnf5 config-manager setopt fedora-multimedia.enabled=0 || true
