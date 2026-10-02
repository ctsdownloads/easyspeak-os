#!/bin/bash
set -ouex pipefail

NAME=speakfin

dnf5 -y install firefox qutebrowser v4l-utils wtype ydotool

rm -f /opt
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
cp -a /ctx/system_files/usr/share/gnome-shell/extensions/ready-dot@speakfin /usr/share/gnome-shell/extensions/
install -Dm755 /ctx/system_files/usr/libexec/speakfin-ready-dot-enable /usr/libexec/speakfin-ready-dot-enable
install -Dm644 /ctx/system_files/etc/xdg/autostart/speakfin-ready-dot.desktop /etc/xdg/autostart/speakfin-ready-dot.desktop
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
