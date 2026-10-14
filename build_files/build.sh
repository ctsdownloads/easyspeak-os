#!/bin/bash
set -ouex pipefail

NAME=easyspeak-os

dnf5 -y install firefox qutebrowser v4l-utils wtype ydotool xdg-terminal-exec
xargs -a /ctx/bluefin-packages.txt dnf5 -y install
# Updates and Homebrew the Bluefin way, from Universal Blue's package repository: the updater (uupd) on its daily
# timer, and Homebrew (ublue-brew, unpacked at boot by brew-setup.service, kept updated by uupd). No second updater:
# remove only GNOME Software's OS-update plugin, as Bluefin does; the Software app itself stays.
# Update by hand any time:  sudo uupd
curl -fsSL --retry 3 "https://copr.fedorainfracloud.org/coprs/ublue-os/packages/repo/fedora-$(rpm -E %fedora)/ublue-os-packages-fedora-$(rpm -E %fedora).repo" -o /etc/yum.repos.d/ublue-os-packages.repo
dnf5 -y install uupd ublue-brew ublue-os-just
rm -f /etc/yum.repos.d/ublue-os-packages.repo
dnf5 -y remove gnome-software-rpm-ostree
# The rpm-ostree plugin is also what switches off GNOME Software's dnf plugin. Without it, the dnf plugin would offer
# dnf package updates, which cannot apply to an image. Remove that plugin too: GNOME Software then handles Flatpak
# apps and firmware only, and uupd is the one OS updater.
rm -f /usr/lib64/gnome-software/plugins-*/libgs_plugin_dnf5.so
ls /usr/lib64/gnome-software/plugins-*/libgs_plugin_dnf5.so >/dev/null 2>&1 && { echo "ERROR: GNOME Software's dnf plugin is still installed"; exit 1; }
command -v ujust >/dev/null || { echo 'ERROR: ujust is missing'; exit 1; }
# System Update in the app grid: runs uupd now, with a progress window. uupd's own polkit rule lets it run without a password.
install -Dm755 /ctx/easyspeak-os-update /usr/bin/easyspeak-os-update
install -Dm644 /ctx/easyspeak-os-update.desktop /usr/share/applications/easyspeak-os-update.desktop
# Install Package File and Remove Apps: .rpm and .deb files go into a Fedora or Ubuntu box (Distrobox), made the first
# time it is needed. Hardware rules that only set permissions go onto the system through a polkit helper
# (password every time); drivers and other system parts are offered as a layered .rpm, or refused for a .deb.
install -Dm755 /ctx/easyspeak-os-packages /usr/bin/easyspeak-os-packages
# zenity plus voice: the EasySpeak-OS windows go through it, so EasySpeak can press their buttons (see the
# easyspeak_os_dialogs plugin).
install -Dm755 /ctx/easyspeak-os-dialog /usr/bin/easyspeak-os-dialog
install -Dm755 /ctx/easyspeak-os-hwrules /usr/libexec/easyspeak-os-hwrules
# Starts and stops box apps for their app grid entries: their messages go to a log file (so an app does not crash
# when its link to the desktop goes away), and a right-click Quit stops the app inside the box.
install -Dm755 /ctx/easyspeak-os-box-run /usr/libexec/easyspeak-os-box-run
install -Dm644 /ctx/dev.easyspeak.os.hwrules.policy /usr/share/polkit-1/actions/dev.easyspeak.os.hwrules.policy
install -Dm644 /ctx/easyspeak-os-install-package.desktop /usr/share/applications/easyspeak-os-install-package.desktop
install -Dm644 /ctx/easyspeak-os-remove-apps.desktop /usr/share/applications/easyspeak-os-remove-apps.desktop
install -Dm644 /ctx/easyspeak-os-repair-boxes.desktop /usr/share/applications/easyspeak-os-repair-boxes.desktop
install -Dm644 /ctx/easyspeak-os-login-apps.desktop /usr/share/applications/easyspeak-os-login-apps.desktop
# At login, once: says whether a package added to the system is ready, and for a printer driver offers to add the printer.
install -Dm644 /ctx/easyspeak-os-packages-after-restart.desktop /etc/xdg/autostart/easyspeak-os-packages-after-restart.desktop
# On GNOME, systemd skips an autostart entry that names a GNOME startup phase (it leaves those to gnome-session,
# which does not start them), so such an entry would silently never run. Fail the build if one of ours has it.
if grep -l '^X-GNOME-Autostart-Phase=' /etc/xdg/autostart/easyspeak-os-*.desktop 2>/dev/null; then
  echo "ERROR: the autostart entries above name a GNOME startup phase, so they would never run at login"; exit 1
fi
# .rpm and .deb files open in Install Package File (GNOME reads gnome-mimeapps.list before Fedora's mimeapps.list).
install -Dm644 /ctx/gnome-mimeapps.list /usr/share/applications/gnome-mimeapps.list
update-desktop-database /usr/share/applications
for t in application/x-rpm application/vnd.debian.binary-package; do
  first=$(XDG_CURRENT_DESKTOP=GNOME gio mime "$t" | sed -n 1p)
  [[ "$first" == *easyspeak-os-install-package.desktop* ]] || { echo "ERROR: $t files do not open in Install Package File"; exit 1; }
done
for c in distrobox podman flatpak rpm2archive pkexec zenity dnf5; do command -v "$c" >/dev/null || { echo "ERROR: Install Package File needs $c"; exit 1; }; done
mkdir -p /tmp/pkgtest && (cd /tmp/pkgtest && dnf5 -q download gnome-mines openvpn solaar-udev fedora-repos-archive)
python3 -I /ctx/check-packages.py /tmp/pkgtest || { echo 'ERROR: Install Package File does not read packages correctly'; exit 1; }
rm -rf /tmp/pkgtest
# Services that must be on by default, also after a first boot (which applies these preset rules):
# EasySpeak-OS's own two services, and what Bluefin switches on for the Bluefin parts we carry.
printf 'enable brew-setup.service\nenable easyspeak-os-codecs-setup.service\nenable easyspeak-os-flathub.service\nenable tailscaled.service\nenable podman-auto-update.timer\nenable uupd.timer\n' > /usr/lib/systemd/system-preset/80-easyspeak-os.preset
systemctl enable tailscaled.service podman-auto-update.timer uupd.timer brew-setup.service
for u in tailscaled.service uupd.timer brew-setup.service; do [ "$(systemctl is-enabled "$u")" = enabled ] || { echo "ERROR: $u is not enabled"; exit 1; }; done
rpm -q gnome-software-rpm-ostree >/dev/null 2>&1 && { echo "ERROR: a second OS updater is still installed"; exit 1; }
# tuned: use the same version Bluefin ships (Bluefin stable: tuned and tuned-ppd 2.27.0-1.fc44).
if [ "$(rpm -q --qf '%{VERSION}' tuned)" != "2.27.0" ]; then dnf5 -y downgrade tuned-2.27.0-1.fc44 tuned-ppd-2.27.0-1.fc44; fi
[ "$(rpm -q --qf '%{VERSION}' tuned)" = 2.27.0 ] && [ "$(rpm -q --qf '%{VERSION}' tuned-ppd)" = 2.27.0 ] || { echo "ERROR: tuned does not match Bluefin's 2.27.0"; exit 1; }
bash /ctx/rebrand.sh
bash /ctx/initramfs.sh
install -Dm755 /ctx/easyspeak-os-boot-label /usr/bin/easyspeak-os-boot-label
install -Dm644 /ctx/NOTICE /usr/share/doc/easyspeak-os/NOTICE
dnf5 -y remove fedora-flathub-remote || echo "note: fedora-flathub-remote was not removed"
install -Dm644 /ctx/flathub.flatpakrepo /usr/share/easyspeak-os/flathub.flatpakrepo
install -Dm644 /ctx/easyspeak-os-flathub.service /usr/lib/systemd/system/easyspeak-os-flathub.service
install -Dm755 /ctx/easyspeak-os-codecs /usr/bin/easyspeak-os-codecs
ln -sf easyspeak-os-codecs /usr/bin/codecs
ln -sf easyspeak-os-codecs /usr/bin/install-codecs
install -Dm644 /ctx/easyspeak-os-codecs.desktop /usr/share/applications/easyspeak-os-codecs.desktop
install -Dm644 /ctx/easyspeak-os-codecs-prompt.desktop /etc/xdg/autostart/easyspeak-os-codecs-prompt.desktop
install -Dm644 /ctx/easyspeak-os-codecs-lib.sh /usr/libexec/easyspeak-os-codecs-lib.sh
install -Dm755 /ctx/easyspeak-os-codecs-setup /usr/libexec/easyspeak-os-codecs-setup
install -Dm755 /ctx/easyspeak-os-codecs-admin /usr/libexec/easyspeak-os-codecs-admin
install -Dm644 /ctx/dev.easyspeak.os.codecs.policy /usr/share/polkit-1/actions/dev.easyspeak.os.codecs.policy
install -Dm644 /ctx/50-easyspeak-os-codecs.rules /usr/share/polkit-1/rules.d/50-easyspeak-os-codecs.rules
# "Everything" comes from RPM Fusion free, copied into /etc only when chosen. Its key comes from Fedora's
# distribution-gpg-keys package; fail the build if that key is missing.
install -Dm644 /ctx/rpmfusion-free.repo /usr/share/easyspeak-os/rpmfusion-free.repo
install -Dm644 /ctx/rpmfusion-free-updates.repo /usr/share/easyspeak-os/rpmfusion-free-updates.repo
[ -s "/usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-free-fedora-$(rpm -E %fedora)" ] || { echo 'ERROR: the RPM Fusion signing key is missing'; exit 1; }
# Fail the build if "Everything" would not install on this image, for example right after a move to a new
# Fedora version, before RPM Fusion has caught up. This is a test run of the same swap the codecs helper makes:
# nothing is installed, and the RPM Fusion key it imports is removed again.
( . /ctx/easyspeak-os-codecs-lib.sh   # in a subshell, so its PATH and umask stay out of the rest of the build
  keys_before=$(rpm -qa gpg-pubkey --qf '%{VERSION}\n')
  cp /usr/share/easyspeak-os/rpmfusion-free.repo /usr/share/easyspeak-os/rpmfusion-free-updates.repo /etc/yum.repos.d/
  swap_ok=1
  dnf5 -y --setopt=tsflags=test --setopt=clean_requirements_on_remove=0 do \
    --action=remove $(present $FREE) \
    --action=install --from-repo=rpmfusion-free,rpmfusion-free-updates $FULL || swap_ok=0
  rm -f /etc/yum.repos.d/rpmfusion-free.repo /etc/yum.repos.d/rpmfusion-free-updates.repo
  for k in $(rpm -qa gpg-pubkey --qf '%{VERSION}\n'); do
    grep -qx "$k" <<<"$keys_before" || rpmkeys --delete "$k"
  done
  [ "$swap_ok" = 1 ] || { echo "ERROR: RPM Fusion's codecs do not install on Fedora $(rpm -E %fedora) yet, so \"Everything\" would fail for users. Wait for RPM Fusion, then rebuild."; exit 1; } )
# Kept only so machines that still have the old negativo17 codecs can update until they run  codecs remove .
install -Dm644 /ctx/RPM-GPG-KEY-negativo17 /usr/share/easyspeak-os/RPM-GPG-KEY-negativo17
install -Dm644 /ctx/easyspeak-os-codecs-setup.service /usr/lib/systemd/system/easyspeak-os-codecs-setup.service
systemctl enable easyspeak-os-flathub.service easyspeak-os-codecs-setup.service
# Default wallpaper. The override file sorts after Fedora's own 10_ overrides, so it wins.
install -Dm644 /ctx/branding/wallpaper.png /usr/share/backgrounds/easyspeak-os/wallpaper.png
install -Dm644 /ctx/branding/easyspeak-os.xml /usr/share/gnome-background-properties/easyspeak-os.xml
install -Dm644 /ctx/branding/zz-easyspeak-os-background.gschema.override /usr/share/glib-2.0/schemas/zz-easyspeak-os-background.gschema.override
glib-compile-schemas /usr/share/glib-2.0/schemas 2>&1 | grep -v 'deprecated' || true
got=$(GSETTINGS_BACKEND=memory gsettings get org.gnome.desktop.background picture-uri)
[ "$got" = "'file:///usr/share/backgrounds/easyspeak-os/wallpaper.png'" ] || { echo "ERROR: the default wallpaper is $got, not the EasySpeak-OS one"; exit 1; }

rm -rf /opt
mkdir /opt
# The release list comes from GitHub's API. Anonymous calls are limited to 60 an hour per address, and GitHub's
# build machines share addresses, so the build uses the repository's own token when it has one (passed in as a
# build secret, never stored in the image). It is read with tracing off and sent from a file, so it is not logged.
gh_auth=()
if [ -s /run/secrets/GITHUB_TOKEN ]; then
  { set +x; } 2>/dev/null
  printf 'Authorization: Bearer %s\n' "$(cat /run/secrets/GITHUB_TOKEN)" > /tmp/gh-auth
  set -x
  gh_auth=(-H @/tmp/gh-auth)
fi
curl -fsSL --retry 3 --retry-all-errors "${gh_auth[@]}" 'https://api.github.com/repos/ctsdownloads/easyspeak/releases?per_page=100' -o /tmp/releases.json
rm -f /tmp/gh-auth
pick() {
  jq -r --arg re "$1" '
    [ .[] | select(.draft == false and .prerelease == false)
      | .assets[]
      | (.name | capture($re)) as $m
      | { v: ($m.v | split(".") | map(tonumber)), u: .browser_download_url, d: .digest } ]
    | sort_by(.v) | last | "\(.u) \(.d)"' /tmp/releases.json
}
for re in '^easyspeak-(?<v>[0-9]+\.[0-9]+\.[0-9]+)-[0-9]+\.x86_64\.rpm$' \
          '^easyspeak-stt-parakeet-(?<v>[0-9]+\.[0-9]+\.[0-9]+)-[0-9]+\.noarch\.rpm$' \
          '^easyspeak-lang-en-(?<v>[0-9]+\.[0-9]+\.[0-9]+)-[0-9]+\.noarch\.rpm$'; do
  read -r url digest <<< "$(pick "$re")"
  [[ "$url" == https://github.com/ctsdownloads/easyspeak/releases/download/* && "$digest" == sha256:* ]] || { echo "no valid release for $re"; exit 1; }
  curl -fsSL -o "/tmp/$(basename "$url")" "$url"
  echo "${digest#sha256:}  /tmp/$(basename "$url")" | sha256sum -c -
done
dnf5 -y install /tmp/easyspeak-*.rpm
rm -f /tmp/easyspeak-*.rpm /tmp/releases.json

# The ready dot reads these EasySpeak log lines; fail the build if they change
core=$(echo /opt/easyspeak/venv/lib/python3*/site-packages/easyspeak/core)
for s in 'Wake! (confidence' 'Listening for wake word' 'Hotkey dictation' '👂 %s'; do
  grep -qF "$s" "$core/main.py" || { echo "EasySpeak log line changed: $s"; exit 1; }
done
grep -qF 'Muted; microphone released' "$core/tray.py" || { echo "EasySpeak log line changed: Muted"; exit 1; }
grep -qF '💬 %s' "$core/speech.py" || { echo "EasySpeak log line changed: speak"; exit 1; }
grep -qF "didn't understand" "$core/main.py" || { echo "EasySpeak log line changed: didn't understand"; exit 1; }
cp -a /ctx/system_files/usr/share/gnome-shell/extensions/ready-dot@easyspeak-os /usr/share/gnome-shell/extensions/
install -Dm755 /ctx/system_files/usr/libexec/easyspeak-os-ready-dot-enable /usr/libexec/easyspeak-os-ready-dot-enable
install -Dm644 /ctx/system_files/etc/xdg/autostart/easyspeak-os-ready-dot.desktop /etc/xdg/autostart/easyspeak-os-ready-dot.desktop
# Voice commands "update system", "install a package", "remove an app", "repair app boxes", "start apps at login" and
# the EasySpeak-OS windows: plugin files in EasySpeak's own plugin
# folder; EasySpeak itself is unchanged. Fail the build if a new EasySpeak release would no longer load them the way
# EasySpeak loads its own plugins.
plugins=$(echo /opt/easyspeak/venv/lib/python3*/site-packages/easyspeak/plugins)
[ -d "$plugins" ] || { echo "ERROR: EasySpeak's plugin folder was not found"; exit 1; }
install -Dm644 /ctx/easyspeak_os_update.py "$plugins/easyspeak_os_update.py"
install -Dm644 /ctx/easyspeak_os_apps.py "$plugins/easyspeak_os_apps.py"
install -Dm644 /ctx/easyspeak_os_dialogs.py "$plugins/easyspeak_os_dialogs.py"
py=$(ls /opt/easyspeak/venv/bin/python3 2>/dev/null || command -v python3)
"$py" /ctx/check-easyspeak-plugin.py "$plugins" /usr/bin/easyspeak-os-dialog || { echo 'ERROR: EasySpeak would not load the EasySpeak-OS plugins'; exit 1; }

# The EasySpeak-OS voice commands, read from the plugins, go into the cheat sheet, the "help" overlay and
# "did you mean" as their own section.
"$py" /ctx/os-commands.py "$plugins" /tmp/os-commands.json || { echo 'ERROR: the EasySpeak-OS command list could not be made'; exit 1; }

# Offline cheat sheet of EasySpeak's commands (and the phrase list for the "did you mean" card),
# from its docs for the installed version. If anything here fails, the image still builds,
# just without them.
ver=$(rpm -q --qf '%{VERSION}' easyspeak)
cheat_ok=0
for tag in "$ver" "v$ver"; do
  if curl -fsSL --retry 3 -o /tmp/commands.md "https://raw.githubusercontent.com/ctsdownloads/easyspeak/$tag/docs/commands.md" &&
     python3 /ctx/make-cheatsheet.py /tmp/commands.md /usr/share/easyspeak-os/easyspeak-commands.html "$ver" /tmp/os-commands.json; then
    cheat_ok=1
    break
  fi
done
if [ "$cheat_ok" = 1 ]; then
  # every EasySpeak-OS command must be in the "help" overlay's list
  python3 - /tmp/os-commands.json /usr/share/easyspeak-os/cheatsheet.json <<'PY' || { echo "ERROR: EasySpeak-OS commands are missing from the help overlay"; exit 1; }
import json, sys
want = [r["say"] for r in json.load(open(sys.argv[1]))]
have = {s for sec in json.load(open(sys.argv[2])) for s in sec["say"]}
missing = [w for w in want if w not in have]
print("missing from help:", missing) if missing else print(f"help overlay has all {len(want)} EasySpeak-OS commands")
sys.exit(1 if missing else 0)
PY
  install -Dm644 /ctx/easyspeak-os-commands.desktop /usr/share/applications/easyspeak-os-commands.desktop
else
  echo "WARNING: EasySpeak command cheat sheet was not generated"
fi
rm -f /tmp/commands.md /tmp/os-commands.json
mkdir -p /usr/lib/opt
mv /opt/easyspeak /usr/lib/opt/easyspeak
# Create /var/opt first, then link EasySpeak inside it. (A rule on /opt/easyspeak fails on a first boot, because
# /opt points at a /var/opt that does not exist yet when the rule runs.)
printf 'd /var/opt 0755 root root -\nL+ /var/opt/easyspeak - - - - /usr/lib/opt/easyspeak\n' > /usr/lib/tmpfiles.d/easyspeak-opt.conf
grep -q '^L+ /var/opt/easyspeak ' /usr/lib/tmpfiles.d/easyspeak-opt.conf || { echo 'ERROR: the EasySpeak link rule is wrong'; exit 1; }
rm -rf /opt
ln -s /var/opt /opt

install -Dm644 /ctx/$NAME.pub /etc/pki/containers/$NAME.pub
mkdir -p /etc/containers/registries.d
printf 'docker:\n  ghcr.io/ctsdownloads/%s:\n    use-sigstore-attachments: true\n' "$NAME" > /etc/containers/registries.d/$NAME.yaml
[ -f /etc/containers/policy.json ] || cp /usr/etc/containers/policy.json /etc/containers/policy.json
# Refuse by default, but allow every transport the way Fedora's stock policy effectively does, and
# require our signature for our own image. rpm-ostree will not use `ostree-image-signed` with a policy
# whose default is insecureAcceptAnything.
jq --arg n "ghcr.io/ctsdownloads/$NAME" --arg k "/etc/pki/containers/$NAME.pub" '
  .default = [{"type":"reject"}]
  | reduce ("docker","docker-daemon","containers-storage","oci","oci-archive","dir","docker-archive","tarball","sif","atomic") as $t (.; .transports[$t][""] = [{"type":"insecureAcceptAnything"}])
  | .transports.docker[$n] = [{"type":"sigstoreSigned","keyPath":$k,"signedIdentity":{"type":"matchRepository"}}]
' /etc/containers/policy.json > /tmp/policy.json
mv /tmp/policy.json /etc/containers/policy.json
jq -e --arg n "ghcr.io/ctsdownloads/$NAME" '(.default | length == 1 and .[0].type == "reject") and (.transports.docker[$n][0].type == "sigstoreSigned") and (.transports.docker[""][0].type == "insecureAcceptAnything")' /etc/containers/policy.json > /dev/null || { echo "ERROR: the container policy is not what the signed rebase needs"; exit 1; }
