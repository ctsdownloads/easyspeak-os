#!/bin/bash
set -ouex pipefail

NAME=speakfin

dnf5 -y install firefox qutebrowser v4l-utils wtype ydotool

rm -f /opt
mkdir /opt
base=https://github.com/ctsdownloads/easyspeak/releases/download
cd /tmp
curl -fsSL -o app.rpm  $base/0.12.0/easyspeak-0.12.0-1.x86_64.rpm
curl -fsSL -o stt.rpm  $base/stt-parakeet-1.0.0/easyspeak-stt-parakeet-1.0.0-1.noarch.rpm
curl -fsSL -o lang.rpm $base/lang-en-1.1.0/easyspeak-lang-en-1.1.0-1.noarch.rpm
echo "9c534c6e251408eed7d62bb1c41b8496f37591cc9c2fa747306a3d45e9b2829c  app.rpm"  | sha256sum -c -
echo "2b901090fc5028ba58df81ca4335ecd4ed21a0cc9fff5239ae74a5cee0866105  stt.rpm"  | sha256sum -c -
echo "3e1b3af43183ecfbe9acf4f7ca0ce086c112faccf3733654ea2e05b91acb8176  lang.rpm" | sha256sum -c -
dnf5 -y install ./app.rpm ./stt.rpm ./lang.rpm
rm -f app.rpm stt.rpm lang.rpm
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
