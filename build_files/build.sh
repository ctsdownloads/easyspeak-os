#!/bin/bash
set -ouex pipefail

NAME=easyspeak-os

dnf5 -y install firefox qutebrowser v4l-utils wtype ydotool xdg-terminal-exec
xargs -a /ctx/bluefin-packages.txt dnf5 -y install
# EasySpeakOS default apps from Fedora's packages (see default-apps.txt); the build fails if any is missing.
grep -v '^#' /ctx/default-apps.txt | xargs dnf5 -y install
for p in $(grep -v '^#' /ctx/default-apps.txt) firefox qutebrowser nautilus ptyxis gnome-control-center orca; do
  rpm -q "$p" >/dev/null || { echo "ERROR: default app $p is not installed"; exit 1; }
done
# Updates and Homebrew the Bluefin way, from Universal Blue's package repository: the updater (uupd) on its daily
# timer, and Homebrew (ublue-brew, unpacked at boot by brew-setup.service, kept updated by uupd). From the same
# repository: Bazaar, the app store (Flathub apps), with its own Super-search provider. It replaces GNOME Software,
# which is removed completely; uupd is the one OS updater.
# Update by hand any time:  sudo uupd
curl -fsSL --retry 3 "https://copr.fedorainfracloud.org/coprs/ublue-os/packages/repo/fedora-$(rpm -E %fedora)/ublue-os-packages-fedora-$(rpm -E %fedora).repo" -o /etc/yum.repos.d/ublue-os-packages.repo
dnf5 -y install uupd ublue-brew ublue-os-just bazaar
rm -f /etc/yum.repos.d/ublue-os-packages.repo
dnf5 -y remove gnome-software gnome-software-rpm-ostree
# GNOME's tour app, and its "Welcome" popup at first login, which would open on top of the setup checklist.
dnf5 -y remove gnome-tour
for p in gnome-software gnome-software-rpm-ostree; do rpm -q "$p" >/dev/null 2>&1 && { echo "ERROR: $p is still installed"; exit 1; }; done
rpm -q bazaar >/dev/null || { echo "ERROR: Bazaar is not installed"; exit 1; }
[ -f /usr/share/gnome-shell/search-providers/io.github.kolunmi.Bazaar.search-provider.ini ] && [ -f /usr/share/dbus-1/services/io.github.kolunmi.Bazaar.SearchProvider.service ] || { echo "ERROR: Bazaar's Super-search provider is missing"; exit 1; }
command -v ujust >/dev/null || { echo 'ERROR: ujust is missing'; exit 1; }
# System Update in the app grid: runs uupd now, with a progress window. uupd's own polkit rule lets it run without a password.
install -Dm755 /ctx/easyspeak-os-update /usr/bin/easyspeak-os-update
install -Dm644 /ctx/easyspeak-os-update.desktop /usr/share/applications/easyspeak-os-update.desktop
# Install Package File and Remove Apps: .rpm and .deb files go into a Fedora or Ubuntu box (Distrobox), made the first
# time it is needed. Hardware rules that only set permissions go onto the system through a polkit helper
# (password every time); drivers and other system parts are offered as a layered .rpm, or refused for a .deb.
install -Dm755 /ctx/easyspeak-os-packages /usr/bin/easyspeak-os-packages
# zenity plus voice: the EasySpeakOS windows go through it, so EasySpeak can press their buttons (see the
# easyspeak_os_dialogs plugin).
install -Dm755 /ctx/easyspeak-os-dialog /usr/bin/easyspeak-os-dialog
install -Dm755 /ctx/easyspeak-os-hwrules /usr/libexec/easyspeak-os-hwrules
# Starts and stops box apps for their app grid entries: their messages go to a log file (so an app does not crash
# when its link to the desktop goes away), and a right-click Quit stops the app inside the box.
install -Dm755 /ctx/easyspeak-os-box-run /usr/libexec/easyspeak-os-box-run
install -Dm644 /ctx/dev.easyspeak.os.hwrules.policy /usr/share/polkit-1/actions/dev.easyspeak.os.hwrules.policy
# System Tools: firmware, automatic disk unlock (TPM), free space, BIOS settings and automatic updates in windows,
# with a root helper for the two jobs that change the system (polkit: administrator password).
install -Dm755 /ctx/easyspeak-os-tools /usr/bin/easyspeak-os-tools
install -Dm755 /ctx/easyspeak-os-tools-admin /usr/libexec/easyspeak-os-tools-admin
install -Dm644 /ctx/dev.easyspeak.os.tools.policy /usr/share/polkit-1/actions/dev.easyspeak.os.tools.policy
# The System Tools jobs no program could do harm with run without a password for an administrator at the computer.
install -Dm755 /ctx/easyspeak-os-tools-safe /usr/libexec/easyspeak-os-tools-safe
install -Dm644 /ctx/50-easyspeak-os-tools.rules /usr/share/polkit-1/rules.d/50-easyspeak-os-tools.rules
python3 -c 'import xml.dom.minidom,sys; [xml.dom.minidom.parse(f) for f in sys.argv[1:]]' \
  /ctx/dev.easyspeak.os.tools.policy /ctx/dev.easyspeak.os.codecs.policy \
  || { echo "ERROR: a System Tools or codecs polkit policy is not valid XML"; exit 1; }
# At every start, the note that says automatic disk unlock is on is made to match the disk itself.
install -Dm644 /ctx/easyspeak-os-disk-unlock-check.service /usr/lib/systemd/system/easyspeak-os-disk-unlock-check.service
systemctl enable easyspeak-os-disk-unlock-check.service
install -Dm644 /ctx/easyspeak-os-tools.desktop /usr/share/applications/easyspeak-os-tools.desktop
# The setup checklist (System Tools' "Setup checklist") opens once at a new user's first login. It also asks the
# media codecs question, so Install Media Codecs no longer has a first-login window of its own.
install -Dm644 /ctx/easyspeak-os-setup-checklist.desktop /etc/xdg/autostart/easyspeak-os-setup-checklist.desktop
rm -f /etc/xdg/autostart/easyspeak-os-codecs-prompt.desktop
# The list of changes (written by the build workflow from the commit titles) goes into the image, so System Update
# can say what a new version changes. A local build without it gets an empty list.
install -Dm644 /dev/null /usr/share/easyspeak-os/changes.txt
[ -f /ctx/changes.txt ] && install -Dm644 /ctx/changes.txt /usr/share/easyspeak-os/changes.txt
# The setup checklist's microphone test records with pw-record (PipeWire's recorder, in pipewire-utils).
rpm -q pipewire-utils >/dev/null || dnf5 -y install pipewire-utils
for c in fwupdmgr systemd-cryptenroll cryptsetup flatpak podman pw-record gnome-control-center; do command -v "$c" >/dev/null || { echo "ERROR: System Tools needs $c"; exit 1; }; done
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
# EasySpeakOS's own default apps (.rpm and .deb files open in Install Package File) in /etc/xdg, which GNOME reads
# first. Fedora's /usr/share/applications/gnome-mimeapps.list stays as it is: it holds all of GNOME's other defaults
# (replacing it made text files open in LibreOffice Writer).
install -Dm644 /ctx/gnome-mimeapps.list /etc/xdg/gnome-mimeapps.list
grep -q '^text/plain=org.gnome.TextEditor.desktop$' /usr/share/applications/gnome-mimeapps.list || { echo "ERROR: Fedora's GNOME default apps file is missing or changed"; exit 1; }
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
# EasySpeakOS's own two services, and what Bluefin switches on for the Bluefin parts we carry.
printf 'enable brew-setup.service\nenable easyspeak-os-codecs-setup.service\nenable easyspeak-os-flathub.service\nenable easyspeak-os-flatpak-apps.service\ndisable flatpak-add-fedora-repos.service\nenable easyspeak-os-disk-unlock-check.service\nenable tailscaled.service\nenable podman-auto-update.timer\nenable uupd.timer\n' > /usr/lib/systemd/system-preset/80-easyspeak-os.preset
systemctl enable tailscaled.service podman-auto-update.timer uupd.timer brew-setup.service
for u in tailscaled.service uupd.timer brew-setup.service; do [ "$(systemctl is-enabled "$u")" = enabled ] || { echo "ERROR: $u is not enabled"; exit 1; }; done
# tuned: use the same version Bluefin ships (Bluefin stable: tuned and tuned-ppd 2.27.0-1.fc44).
if [ "$(rpm -q --qf '%{VERSION}' tuned)" != "2.27.0" ]; then dnf5 -y downgrade tuned-2.27.0-1.fc44 tuned-ppd-2.27.0-1.fc44; fi
[ "$(rpm -q --qf '%{VERSION}' tuned)" = 2.27.0 ] && [ "$(rpm -q --qf '%{VERSION}' tuned-ppd)" = 2.27.0 ] || { echo "ERROR: tuned does not match Bluefin's 2.27.0"; exit 1; }
bash /ctx/rebrand.sh
# System Tools' "Unlock disk automatically" lets the TPM unlock the disk at startup: the boot image needs the TPM
# support for that (what Universal Blue's ublue-os-luks adds). initramfs.sh checks it is in the new boot image.
dnf5 -y install tpm2-tss
printf 'add_dracutmodules+=" tpm2-tss "\n' > /usr/lib/dracut/dracut.conf.d/90-easyspeak-os-tpm.conf
bash /ctx/initramfs.sh
install -Dm755 /ctx/easyspeak-os-boot-label /usr/bin/easyspeak-os-boot-label
install -Dm644 /ctx/NOTICE /usr/share/doc/easyspeak-os/NOTICE
dnf5 -y remove fedora-flathub-remote || echo "note: fedora-flathub-remote was not removed"
install -Dm644 /ctx/flathub.flatpakrepo /usr/share/easyspeak-os/flathub.flatpakrepo
install -Dm644 /ctx/easyspeak-os-flathub.service /usr/lib/systemd/system/easyspeak-os-flathub.service
# The default apps Fedora doesn't package, from Flathub on the first start with internet (see those files). Fedora's
# own Flatpak store is not added (flatpak-add-fedora-repos.service): apps come from Flathub only.
install -Dm644 /ctx/flathub-apps.txt /usr/share/easyspeak-os/flathub-apps.txt
install -Dm755 /ctx/easyspeak-os-flathub-apps /usr/libexec/easyspeak-os-flathub-apps
systemctl disable flatpak-add-fedora-repos.service
install -Dm644 /ctx/easyspeak-os-flatpak-apps.service /usr/lib/systemd/system/easyspeak-os-flatpak-apps.service
install -Dm755 /ctx/easyspeak-os-codecs /usr/bin/easyspeak-os-codecs
ln -sf easyspeak-os-codecs /usr/bin/codecs
ln -sf easyspeak-os-codecs /usr/bin/install-codecs
install -Dm644 /ctx/easyspeak-os-codecs.desktop /usr/share/applications/easyspeak-os-codecs.desktop
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
systemctl enable easyspeak-os-flathub.service easyspeak-os-flatpak-apps.service easyspeak-os-codecs-setup.service
# Default wallpaper. The override file sorts after Fedora's own 10_ overrides, so it wins.
install -Dm644 /ctx/branding/wallpaper.png /usr/share/backgrounds/easyspeak-os/wallpaper.png
install -Dm644 /ctx/branding/easyspeak-os.xml /usr/share/gnome-background-properties/easyspeak-os.xml
install -Dm644 /ctx/branding/zz-easyspeak-os-background.gschema.override /usr/share/glib-2.0/schemas/zz-easyspeak-os-background.gschema.override
install -Dm644 /ctx/zz-easyspeak-os-windows.gschema.override /usr/share/glib-2.0/schemas/zz-easyspeak-os-windows.gschema.override
install -Dm644 /ctx/zz-easyspeak-os-no-tour.gschema.override /usr/share/glib-2.0/schemas/zz-easyspeak-os-no-tour.gschema.override
install -Dm644 /ctx/zz-easyspeak-os-desktop.gschema.override /usr/share/glib-2.0/schemas/zz-easyspeak-os-desktop.gschema.override
install -Dm644 /ctx/zz-easyspeak-os-login.gschema.override /usr/share/glib-2.0/schemas/zz-easyspeak-os-login.gschema.override
install -Dm644 /ctx/branding/easyspeak-os-gdm-logo.png /usr/share/pixmaps/easyspeak-os-gdm-logo.png
glib-compile-schemas /usr/share/glib-2.0/schemas 2>&1 | grep -v 'deprecated' || true
got=$(GSETTINGS_BACKEND=memory gsettings get org.gnome.desktop.background picture-uri)
[ "$got" = "'file:///usr/share/backgrounds/easyspeak-os/wallpaper.png'" ] || { echo "ERROR: the default wallpaper is $got, not the EasySpeakOS one"; exit 1; }
got=$(GSETTINGS_BACKEND=memory gsettings get org.gnome.desktop.wm.preferences button-layout)
[ "$got" = "'appmenu:minimize,maximize,close'" ] || { echo "ERROR: windows have no minimize button by default ($got)"; exit 1; }
got=$(GSETTINGS_BACKEND=memory gsettings get org.gnome.shell welcome-dialog-last-shown-version)
[ "$got" = "'4294967295'" ] || { echo "ERROR: GNOME's welcome popup would still open at first login ($got)"; exit 1; }
rpm -q gnome-tour >/dev/null 2>&1 && { echo "ERROR: GNOME's tour app is still installed"; exit 1; }
[ "$(. /usr/lib/os-release; echo "$PRETTY_NAME")" = "EasySpeakOS" ] || { echo "ERROR: the system's display name is not EasySpeakOS"; exit 1; }
got=$(GSETTINGS_BACKEND=memory gsettings get org.gnome.desktop.interface enable-hot-corners)
[ "$got" = "false" ] || { echo "ERROR: the hot corner is still on by default ($got)"; exit 1; }
got=$(GSETTINGS_BACKEND=memory gsettings get org.gnome.desktop.interface show-battery-percentage)
[ "$got" = "true" ] || { echo "ERROR: the battery percentage is not shown by default ($got)"; exit 1; }
got=$(GSETTINGS_BACKEND=memory gsettings get org.gnome.login-screen logo)
[ "$got" = "'/usr/share/pixmaps/easyspeak-os-gdm-logo.png'" ] && [ -s /usr/share/pixmaps/easyspeak-os-gdm-logo.png ] || { echo "ERROR: the login screen does not show the EasySpeakOS logo ($got)"; exit 1; }

# The EasySpeakOS tools in Show Apps' Utilities folder (see that file).
install -Dm644 /ctx/easyspeak-os-app-folders.dconf /etc/dconf/db/distro.d/50-easyspeak-os-app-folders

# The firmware boot menu names a boot entry from shim's BOOT*.CSV files ("shimx64.efi,Fedora,,..."), when shim's
# fallback creates the entry: EasySpeakOS instead. Plain UTF-16 text files; Secure Boot checks only the .efi files.
for f in /usr/lib/efi/shim/*/EFI/*/BOOT*.CSV; do
  iconv -f UTF-16LE -t UTF-8 "$f" | sed 's/Fedora/EasySpeakOS/g' | iconv -f UTF-8 -t UTF-16LE > "$f.new"
  mv "$f.new" "$f"
done
ls /usr/lib/efi/shim/*/EFI/*/BOOTX64.CSV >/dev/null || { echo "ERROR: shim's BOOTX64.CSV was not found"; exit 1; }
for f in /usr/lib/efi/shim/*/EFI/*/BOOT*.CSV; do
  iconv -f UTF-16LE -t UTF-8 "$f" | grep -q ',EasySpeakOS,' || { echo "ERROR: $f does not name EasySpeakOS"; exit 1; }
  iconv -f UTF-16LE -t UTF-8 "$f" | grep -q Fedora && { echo "ERROR: $f still names Fedora"; exit 1; }
done

# EasySpeak's toggle in the Quick Settings menu, on from the start (see that file).
install -Dm644 /ctx/easyspeak-os-quick-settings.dconf /etc/dconf/db/distro.d/50-easyspeak-os-quick-settings
dconf update
got=$(HOME=/tmp dconf read /org/gnome/shell/extensions/easyspeak/show-in-quick-settings)
for a in easyspeak-os-tools easyspeak-os-update easyspeak-os-install-package easyspeak-os-remove-apps easyspeak-os-repair-boxes easyspeak-os-login-apps easyspeak-os-codecs easyspeak-os-commands; do
  HOME=/tmp dconf read /org/gnome/desktop/app-folders/folders/Utilities/apps | grep -q "'$a.desktop'" || { echo "ERROR: $a is not in the Utilities folder"; exit 1; }
done
[ "$got" = "true" ] || { echo "ERROR: EasySpeak's Quick Settings toggle is not on by default ($got)"; exit 1; }

# Firefox: its own home page instead of Fedora's start page, no "Fedora Project - Start Page" tile, and its About
# window says "Mozilla Firefox", not "Mozilla Firefox for Fedora". Fails if Fedora's Firefox package changes these.
ffprefs=/usr/lib64/firefox/browser/defaults/preferences/firefox-redhat-default-prefs.js
ffdist=/usr/lib64/firefox/distribution/distribution.ini
grep -q '^pref("browser.startup.homepage", *"https://start.fedoraproject.org/");' "$ffprefs" || { echo "ERROR: Firefox's Fedora home page setting was not found"; exit 1; }
grep -q '^pref("browser.newtabpage.pinned",' "$ffprefs" || { echo "ERROR: Firefox's Fedora tile setting was not found"; exit 1; }
sed -i -e 's|^pref("browser.startup.homepage", *"https://start.fedoraproject.org/");|pref("browser.startup.homepage", "about:home");|' \
       -e 's|^pref("browser.newtabpage.pinned",.*|pref("browser.newtabpage.pinned", "[]");|' "$ffprefs"
grep -q '^about=Mozilla Firefox for Fedora$' "$ffdist" || { echo "ERROR: Firefox's About text was not found"; exit 1; }
sed -i 's/^about=Mozilla Firefox for Fedora$/about=Mozilla Firefox/' "$ffdist"
grep -qi 'fedoraproject' "$ffprefs" && { echo "ERROR: Firefox still points at Fedora's pages"; exit 1; }
grep -qi '^about=.*fedora' "$ffdist" && { echo "ERROR: Firefox's About window still says Fedora"; exit 1; }

# fastfetch: the EasySpeakOS logo instead of Fedora's, with fastfetch's usual information next to it.
install -Dm644 /ctx/fastfetch-logo.txt /usr/share/easyspeak-os/fastfetch-logo.txt
install -Dm644 /ctx/fastfetch-config.jsonc /etc/xdg/fastfetch/config.jsonc
out=$(HOME=/tmp fastfetch --pipe false -s OS 2>&1)
printf '%s' "$out" | grep -qF '_.-##' && printf '%s' "$out" | grep -qF 'EasySpeakOS' || { echo "ERROR: fastfetch does not show the EasySpeakOS logo"; printf '%s\n' "$out" | head -5; exit 1; }

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
# the EasySpeakOS windows: plugin files in EasySpeak's own plugin
# folder; EasySpeak itself is unchanged. Fail the build if a new EasySpeak release would no longer load them the way
# EasySpeak loads its own plugins.
plugins=$(echo /opt/easyspeak/venv/lib/python3*/site-packages/easyspeak/plugins)
[ -d "$plugins" ] || { echo "ERROR: EasySpeak's plugin folder was not found"; exit 1; }
# "open software" must reach the Bazaar plugin before EasySpeak's own apps plugin (which looks for GNOME Software):
# EasySpeak must still order plugins by PRIORITY.
grep -qF 'getattr(m, "PRIORITY", 50)' "$core/main.py" || { echo 'ERROR: EasySpeak no longer orders plugins by PRIORITY'; exit 1; }
install -Dm644 /ctx/easyspeak_os_update.py "$plugins/easyspeak_os_update.py"
install -Dm644 /ctx/easyspeak_os_apps.py "$plugins/easyspeak_os_apps.py"
install -Dm644 /ctx/easyspeak_os_tools.py "$plugins/easyspeak_os_tools.py"
install -Dm644 /ctx/easyspeak_os_dialogs.py "$plugins/easyspeak_os_dialogs.py"
install -Dm644 /ctx/easyspeak_os_software.py "$plugins/easyspeak_os_software.py"
py=$(ls /opt/easyspeak/venv/bin/python3 2>/dev/null || command -v python3)
"$py" /ctx/check-easyspeak-plugin.py "$plugins" /usr/bin/easyspeak-os-dialog || { echo 'ERROR: EasySpeak would not load the EasySpeakOS plugins'; exit 1; }

# The EasySpeakOS voice commands, read from the plugins, go into the cheat sheet, the "help" overlay and
# "did you mean" as their own section.
"$py" /ctx/os-commands.py "$plugins" /tmp/os-commands.json || { echo 'ERROR: the EasySpeakOS command list could not be made'; exit 1; }

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
  # every EasySpeakOS command must be in the "help" overlay's list
  python3 - /tmp/os-commands.json /usr/share/easyspeak-os/cheatsheet.json <<'PY' || { echo "ERROR: EasySpeakOS commands are missing from the help overlay"; exit 1; }
import json, sys
want = [r["say"] for r in json.load(open(sys.argv[1]))]
have = {s for sec in json.load(open(sys.argv[2])) for s in sec["say"]}
missing = [w for w in want if w not in have]
print("missing from help:", missing) if missing else print(f"help overlay has all {len(want)} EasySpeakOS commands")
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
