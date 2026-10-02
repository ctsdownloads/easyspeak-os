# Shared by the two privileged codecs helpers. Sourced, never run directly. Owned by root.
# Everything here is fixed: the packages, the repository and its key. Nothing comes from the caller.
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
umask 022

STATE=/var/lib/easyspeak-os
OPEN=$STATE/codecs-setup-open        # exists during the one-time setup window
DONE=$STATE/codecs-setup-done        # exists once the setup question has been answered
WINDOW_MINUTES=1440                  # the setup window lasts 24 hours at most
REPO_SRC=/usr/share/easyspeak-os/negativo17-multimedia.repo
REPO_DST=/etc/yum.repos.d/negativo17-multimedia.repo
FREE="ffmpeg-free libavcodec-free libavdevice-free libavfilter-free libavformat-free libavutil-free libswresample-free libswscale-free"
REPLACE="xevd-libs xeve-libs"   # Fedora ships different library files under these names
FULL="ffmpeg ffmpeg-libs libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale x264-libs x265-libs"
WEB="openh264 mozilla-openh264 gstreamer1-plugin-openh264"

log()    { logger -t easyspeak-os-codecs -- "$*"; }
caller() { printf '%s' "${PKEXEC_UID:-unknown}"; }
present() { local p; for p in "$@"; do rpm -q "$p" >/dev/null 2>&1 && printf '%s ' "$p"; done; }
need_root() { [ "$(id -u)" -eq 0 ] || { echo "This helper must run as root, through polkit."; exit 1; }; }

# Run a command and show its output. If it fails, keep a full copy in the system log, because the
# window can only show a few lines:  journalctl -t easyspeak-os-codecs
run_logged() {
  local out rc
  out=$("$@" 2>&1); rc=$?
  printf '%s\n' "$out"
  [ "$rc" -eq 0 ] || printf '%s\n' "$out" | logger -t easyspeak-os-codecs
  return "$rc"
}

do_web() {
  run_logged rpm-ostree install --idempotent $WEB
}

do_full() {
  install -m 0644 "$REPO_SRC" "$REPO_DST" || return 1
  local cmd=(override replace --experimental --from=repo=fedora-multimedia) p
  for p in $(present $REPLACE); do cmd+=("$p"); done
  for p in $(present $FREE); do cmd+=(--remove "$p"); done
  for p in $FULL; do cmd+=(--install "$p"); done
  if ! run_logged rpm-ostree "${cmd[@]}"; then
    rm -f "$REPO_DST"
    echo "The change was not made, and nothing was left behind."
    return 1
  fi
}

do_remove() {
  local layered; layered=$(present $FULL $WEB)
  [ -z "$layered" ] || rpm-ostree uninstall $layered || true
  rpm-ostree override reset $FREE $REPLACE || true
  rm -f "$REPO_DST"
  echo "Removed. Restart to finish."
}
