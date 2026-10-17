# Shared by the two privileged codecs helpers. Sourced, never run directly. Owned by root.
# Everything here is fixed: the packages, the repositories and their keys. Nothing comes from the caller.
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
umask 022

STATE=/var/lib/easyspeak-os
OPEN=$STATE/codecs-setup-open        # exists during the one-time setup window
DONE=$STATE/codecs-setup-done        # exists once the setup question has been answered
WINDOW_MINUTES=1440                  # the setup window lasts 24 hours at most

# "Everything" comes from RPM Fusion free, the source standard Fedora uses. Its two repository files ship
# in the image and are copied into /etc only when someone chooses it. Their signing key comes from Fedora's
# own distribution-gpg-keys package.
REPO_DIR=/usr/share/easyspeak-os
REPOS="rpmfusion-free.repo rpmfusion-free-updates.repo"
FREE="ffmpeg-free libavcodec-free libavdevice-free libavfilter-free libavformat-free libavutil-free libswresample-free libswscale-free"
FULL="ffmpeg ffmpeg-libs libavdevice x264-libs x265-libs"
WEB="openh264 mozilla-openh264 gstreamer1-plugin-openh264"
# Fedora's empty stand-in for OpenH264, in the base image. A package added on top can't replace a base one, so
# "web" removes it in the same step, and "remove" puts it back.
STAND_IN="noopenh264"

# Earlier EasySpeakOS builds used negativo17. These are only used to remove that setup cleanly.
OLD_REPO=/etc/yum.repos.d/negativo17-multimedia.repo
OLD_FULL="ffmpeg ffmpeg-libs libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale x264-libs x265-libs"
OLD_REPLACE="xevd-libs xeve-libs"

log()    { logger -t easyspeak-os-codecs -- "$*"; }
caller() { printf '%s' "${PKEXEC_UID:-unknown}"; }
present() { local p; for p in "$@"; do rpm -q "$p" >/dev/null 2>&1 && printf '%s ' "$p"; done; }
need_root() { [ "$(id -u)" -eq 0 ] || { echo "This helper must run as root, through polkit."; exit 1; }; }

# Names from the current rpm-ostree request ($1 = requested-packages or requested-base-removals) that are
# also in the given list. Only these can be uninstalled or reset without rpm-ostree refusing.
requested() {
  local field=$1; shift
  rpm-ostree status --json | python3 -c '
import json, sys
d = json.load(sys.stdin)["deployments"][0]
want = set(sys.argv[2:])
print(" ".join(sorted(set(d.get(sys.argv[1], [])) & want)))' "$field" "$@"
}

old_setup_present() {   # anything left from the negativo17 version
  [ -e "$OLD_REPO" ] && return 0
  [ "$(rpm -q --qf '%{EPOCH}' xevd-libs 2>/dev/null)" = 1 ] && return 0
  [ -n "$(requested requested-packages libavcodec libavfilter libavformat libavutil libswresample libswscale)" ]
}

repos_on()  { local r; for r in $REPOS; do install -m 0644 "$REPO_DIR/$r" "/etc/yum.repos.d/$r" || return 1; done; }
repos_off() { local r; for r in $REPOS; do grep -qs 'EasySpeakOS' "/etc/yum.repos.d/$r" && rm -f "/etc/yum.repos.d/$r"; done; return 0; }

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
  if [ -n "$(requested requested-base-removals $STAND_IN)" ]; then   # already chosen, booted or pending
    echo "Web video is already installed. Restart if you have not yet."; return 0
  fi
  local cmd=(override remove $STAND_IN) p
  for p in $WEB; do cmd+=(--install "$p"); done
  run_logged rpm-ostree "${cmd[@]}"
}

do_full() {
  if old_setup_present; then
    echo "error: codecs from an earlier version of this system (negativo17) are still installed."
    echo "Remove them first: run  codecs remove , restart, then choose Everything again."
    return 1
  fi
  if [ -n "$(requested requested-base-removals ffmpeg-free)" ]; then   # already chosen, booted or pending
    echo "The full codecs are already installed. Restart if you have not yet."; return 0
  fi
  repos_on || return 1
  local cmd=(override remove) p
  for p in $(present $FREE); do cmd+=("$p"); done
  for p in $FULL; do cmd+=(--install "$p"); done
  if ! run_logged rpm-ostree "${cmd[@]}"; then
    repos_off
    echo "The change was not made, and nothing was left behind."
    return 1
  fi
}

do_remove() {
  local uninstall resets old_replaced="" p cmd
  uninstall=$(requested requested-packages $FULL $OLD_FULL $WEB)
  resets=$(requested requested-base-removals $FREE $STAND_IN)
  [ "$(rpm -q --qf '%{EPOCH}' xevd-libs 2>/dev/null)" = 1 ] && old_replaced="$OLD_REPLACE"
  if [ -n "$resets$old_replaced" ]; then
    cmd=(override reset $resets $old_replaced)
    for p in $uninstall; do cmd+=(--uninstall "$p"); done
    run_logged rpm-ostree "${cmd[@]}" || return 1
  elif [ -n "$uninstall" ]; then
    run_logged rpm-ostree uninstall $uninstall || return 1
  fi
  repos_off
  rm -f "$OLD_REPO"
  echo "Removed. Restart to finish."
}
