#!/bin/bash
set -ouex pipefail

NAME=easyspeak-os

dnf5 -y install firefox qutebrowser v4l-utils wtype ydotool xdg-terminal-exec
xargs -a /ctx/bluefin-packages.txt dnf5 -y install
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
install -Dm644 /ctx/negativo17-multimedia.repo /usr/share/easyspeak-os/negativo17-multimedia.repo
install -Dm644 /ctx/RPM-GPG-KEY-negativo17 /usr/share/easyspeak-os/RPM-GPG-KEY-negativo17
install -Dm644 /ctx/easyspeak-os-codecs-setup.service /usr/lib/systemd/system/easyspeak-os-codecs-setup.service
systemctl enable easyspeak-os-flathub.service easyspeak-os-codecs-setup.service

rm -rf /opt
mkdir /opt
curl -fsSL --retry 3 --retry-all-errors 'https://api.github.com/repos/ctsdownloads/easyspeak/releases?per_page=100' -o /tmp/releases.json
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

# Offline cheat sheet of EasySpeak's commands (and the phrase list for the "did you mean" card),
# from its docs for the installed version. If anything here fails, the image still builds,
# just without them.
ver=$(rpm -q --qf '%{VERSION}' easyspeak)
cheat_ok=0
for tag in "$ver" "v$ver"; do
  if curl -fsSL --retry 3 -o /tmp/commands.md "https://raw.githubusercontent.com/ctsdownloads/easyspeak/$tag/docs/commands.md" &&
     python3 /ctx/make-cheatsheet.py /tmp/commands.md /usr/share/easyspeak-os/easyspeak-commands.html "$ver"; then
    cheat_ok=1
    break
  fi
done
if [ "$cheat_ok" = 1 ]; then
  install -Dm644 /ctx/easyspeak-os-commands.desktop /usr/share/applications/easyspeak-os-commands.desktop
else
  echo "WARNING: EasySpeak command cheat sheet was not generated"
fi
rm -f /tmp/commands.md
mkdir -p /usr/lib/opt
mv /opt/easyspeak /usr/lib/opt/easyspeak
echo 'L+ /opt/easyspeak - - - - /usr/lib/opt/easyspeak' > /usr/lib/tmpfiles.d/easyspeak-opt.conf
rm -rf /opt
ln -s /var/opt /opt

install -Dm644 /ctx/$NAME.pub /etc/pki/containers/$NAME.pub
mkdir -p /etc/containers/registries.d
printf 'docker:\n  ghcr.io/ctsdownloads/%s:\n    use-sigstore-attachments: true\n' "$NAME" > /etc/containers/registries.d/$NAME.yaml
[ -f /etc/containers/policy.json ] || cp /usr/etc/containers/policy.json /etc/containers/policy.json
jq --arg n "ghcr.io/ctsdownloads/$NAME" --arg k "/etc/pki/containers/$NAME.pub" '.transports.docker[$n] = [{"type":"sigstoreSigned","keyPath":$k,"signedIdentity":{"type":"matchRepository"}}]' /etc/containers/policy.json > /tmp/policy.json
mv /tmp/policy.json /etc/containers/policy.json
