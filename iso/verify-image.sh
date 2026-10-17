#!/usr/bin/bash
# Checks, inside the built images, that every EasySpeakOS change is really there, and prints PASS or FAIL for each.
# build-local-iso.sh runs it before making the ISO and stops on any FAIL. To run it yourself, at the top of the
# repository, after a build:
#   iso/verify-image.sh
# It looks at two images: the system that gets installed (localhost/easyspeak-os) and the live USB system with the
# installer (localhost/easyspeak-os-live). Leave out the second (iso/verify-image.sh localhost/easyspeak-os "") to
# check only the system.
set -uo pipefail
cd "$(dirname "$0")/.."
sys=${1-localhost/easyspeak-os}
live=${2-localhost/easyspeak-os-live}
logo_sum=$(sha256sum build_files/fastfetch-logo.txt | cut -d' ' -f1)
apps="$(grep -v '^#' build_files/default-apps.txt | tr '\n' ' ')firefox qutebrowser nautilus ghostty gnome-control-center orca bazaar"

# Run inside an image; each check prints "PASS: ..." or "FAIL: ...".
run_in() { sudo podman run --rm --pull=never --network=none --entrypoint /usr/bin/bash -e LOGO_SUM="$logo_sum" -e APPS="$apps" "$1" -c "$2"; }

system_checks='
ok()  { if eval "$2" >/dev/null 2>&1; then echo "PASS: $1"; else echo "FAIL: $1"; fi; }
gs()  { GSETTINGS_BACKEND=memory gsettings get "$1" "$2" 2>/dev/null; }
none() { "$@"; [ $? -eq 1 ]; }   # searched existing files and found nothing (a missing file is an error, not a pass)
export HOME=/tmp
ok "system name is EasySpeakOS (no dash)"         "grep -qx \"NAME=\\\"EasySpeakOS\\\"\" /usr/lib/os-release && grep -qx \"PRETTY_NAME=\\\"EasySpeakOS\\\"\" /usr/lib/os-release"
ok "no \"EasySpeak-OS\" in EasySpeakOS windows, help or voice commands" "none grep -rIl \"EasySpeak-OS\" /usr/lib/os-release /usr/bin/easyspeak-os-* /usr/share/easyspeak-os /usr/share/applications /etc/xdg/autostart /usr/share/gnome-shell/extensions/ready-dot@easyspeak-os /usr/lib/opt/easyspeak/venv/lib/python3*/site-packages/easyspeak/plugins/easyspeak_os_*.py"
ok "hot corners off"                              "[ \"\$(gs org.gnome.desktop.interface enable-hot-corners)\" = false ]"
ok "battery percentage shown"                     "[ \"\$(gs org.gnome.desktop.interface show-battery-percentage)\" = true ]"
ok "minimize and maximize buttons"                "[ \"\$(gs org.gnome.desktop.wm.preferences button-layout)\" = \"'"'"'appmenu:minimize,maximize,close'"'"'\" ]"
ok "no GNOME tour popup"                          "[ \"\$(gs org.gnome.shell welcome-dialog-last-shown-version)\" = \"'"'"'4294967295'"'"'\" ]"
ok "GNOME Tour app removed"                       "! rpm -q gnome-tour"
ok "EasySpeak toggle in Quick Settings"           "[ \"\$(dconf read /org/gnome/shell/extensions/easyspeak/show-in-quick-settings)\" = true ]"
ok "Firefox: no Fedora start page or tile"        "none grep -qi fedoraproject /usr/lib64/firefox/browser/defaults/preferences/firefox-redhat-default-prefs.js"
ok "Firefox: About says Mozilla Firefox"          "grep -qx \"about=Mozilla Firefox\" /usr/lib64/firefox/distribution/distribution.ini"
ok "fastfetch logo is the approved one"           "[ \"\$(sha256sum /usr/share/easyspeak-os/fastfetch-logo.txt | cut -d\" \" -f1)\" = \"\$LOGO_SUM\" ]"
ok "fastfetch shows the EasySpeakOS logo"         "out=\$(fastfetch --pipe false -s OS 2>&1); printf %s \"\$out\" | grep -qF _.-## && printf %s \"\$out\" | grep -qF EasySpeakOS"
ok "no Fedora logo package"                       "! rpm -q fedora-logos"
for a in $APPS; do ok "default app installed: $a" "rpm -q $a"; done
ok "Flathub apps listed: Errands, Shortwave, Podcasts, Pika Backup (no Secrets)" "( for i in io.github.mrvladus.List de.haeckerfelix.Shortwave org.gnome.Podcasts org.gnome.World.PikaBackup; do grep -qx \$i /usr/share/easyspeak-os/flathub-apps.txt || exit 1; done; ! grep -qi secrets /usr/share/easyspeak-os/flathub-apps.txt )"
ok "Flathub apps install at first start (service on)" "[ \"\$(systemctl is-enabled easyspeak-os-flatpak-apps.service)\" = enabled ]"
ok "Flathub apps come from Flathub only (Fedora Flatpak store off)" "[ \"\$(systemctl is-enabled flatpak-add-fedora-repos.service 2>/dev/null)\" != enabled ]"
ok "GNOME Software removed"                       "! rpm -q gnome-software && ! rpm -q gnome-software-rpm-ostree"
ok "Bazaar in Super search"                       "[ -f /usr/share/gnome-shell/search-providers/io.github.kolunmi.Bazaar.search-provider.ini ] && [ -f /usr/share/dbus-1/services/io.github.kolunmi.Bazaar.SearchProvider.service ]"
ok "voice: open software / close software opens and closes Bazaar" "grep -q \"^PRIORITY = 40\" /usr/lib/opt/easyspeak/venv/lib/python3*/site-packages/easyspeak/plugins/easyspeak_os_software.py"
ok "text files open in Text Editor"               "[ \"\$(XDG_CURRENT_DESKTOP=GNOME gio mime text/plain 2>/dev/null | head -1 | sed \"s/.*: //\")\" = org.gnome.TextEditor.desktop ]"
ok ".rpm and .deb files open in Install Package File" "[ \"\$(XDG_CURRENT_DESKTOP=GNOME gio mime application/x-rpm 2>/dev/null | head -1 | sed \"s/.*: //\")\" = easyspeak-os-install-package.desktop ]"
ok "Flatpak files open in Bazaar"                 "[ \"\$(XDG_CURRENT_DESKTOP=GNOME gio mime application/vnd.flatpak.ref 2>/dev/null | head -1 | sed \"s/.*: //\")\" = io.github.kolunmi.Bazaar.desktop ]"
ok "EasySpeakOS tools in the Utilities folder"    "( u=\$(dconf read /org/gnome/desktop/app-folders/folders/Utilities/apps); for a in easyspeak-os-tools easyspeak-os-update easyspeak-os-install-package easyspeak-os-remove-apps easyspeak-os-repair-boxes easyspeak-os-login-apps easyspeak-os-codecs easyspeak-os-commands; do printf %s \"\$u\" | grep -qF \"\$a.desktop\" || exit 1; done )"
ok "login screen shows the EasySpeakOS logo"      "gs org.gnome.login-screen logo | grep -qF /usr/share/pixmaps/easyspeak-os-gdm-logo.png && [ -s /usr/share/pixmaps/easyspeak-os-gdm-logo.png ]"
ok "installed boot-menu entry will be named EasySpeakOS (system-release)" "[ \"\$(sed \"s/ *release.*//\" /etc/system-release)\" = EasySpeakOS ]"
ok "voice: Install EasySpeakOS can be said as separate words" "grep -qF \"replace(\\\" \\\", \\\"\\\")\" /usr/lib/opt/easyspeak/venv/lib/python3*/site-packages/easyspeak/plugins/easyspeak_os_dialogs.py"
'

live_checks='
ok()  { if eval "$2" >/dev/null 2>&1; then echo "PASS: $1"; else echo "FAIL: $1"; fi; }
i=/usr/lib/easyspeak-os-installer
e=/usr/libexec/easyspeak-os-install-engine
ok "system name is EasySpeakOS (no dash)"          "grep -qx \"PRETTY_NAME=\\\"EasySpeakOS\\\"\" /usr/lib/os-release && grep -qx \"EasySpeakOS release 44\" /etc/system-release"
ok "no Fedora installer (Anaconda) on the USB"     "! rpm -q anaconda-core"
ok "installer launcher: Install EasySpeakOS"       "grep -qx \"Name=Install EasySpeakOS\" /usr/share/applications/io.github.ctsdownloads.EasySpeakOS.Installer.desktop"
ok "welcome window: Install EasySpeakOS / Try it first" "grep -qF \"Install EasySpeakOS\" /usr/libexec/easyspeak-os-live-welcome && grep -qF \"Try it first\" /usr/libexec/easyspeak-os-live-welcome && grep -qF /usr/bin/easyspeak-os-installer /usr/libexec/easyspeak-os-live-welcome"
ok "installer: Alpha badge and EasySpeakOS logo"   "grep -qF \"label=\\\"Alpha\\\"\" \$i/easyspeak-os-installer && [ -s /usr/share/easyspeak-os-installer/logo-wide.svg ]"
ok "installer: problem reports go to GitHub"       "grep -qF github.com/ctsdownloads/easyspeak-os/issues/new \$i/screens.py && command -v qrencode"
ok "installer: disk changes only through its polkit action" "[ -x \$e ] && grep -qF \"<annotate key=\\\"org.freedesktop.policykit.exec.path\\\">\$e<\" /usr/share/polkit-1/actions/io.github.ctsdownloads.easyspeak-os.install.policy"
ok "installer installs EasySpeakOS from the USB, with signed updates" "grep -qF \"IMAGE = \\\"ghcr.io/ctsdownloads/easyspeak-os:latest\\\"\" \$e && grep -qF containers-storage: \$e && grep -qF ostree-image-signed:docker:// \$e"
ok "live session does not install Flathub apps" "[ \"\$(systemctl is-enabled easyspeak-os-flatpak-apps.service 2>/dev/null)\" != enabled ]"
ok "USB boots the EasySpeakOS grub without shim, from EFI/BOOT and EFI/EasySpeakOS only, no Fedora" "! grep -rqi fedora /boot/efi && [ \"\$(ls /boot/efi/EFI | tr \"\\n\" \" \")\" = \"BOOT EasySpeakOS \" ] && [ \"\$(ls /boot/efi/EFI/BOOT)\" = BOOTX64.EFI ] && [ \"\$(ls /boot/efi/EFI/EasySpeakOS)\" = grubx64.efi ]"
ok "copy to install is on the USB"                 "grep -qF ghcr.io/ctsdownloads/easyspeak-os:latest /var/lib/containers/storage/overlay-images/images.json"
'

out=$(run_in "$sys" "$system_checks" 2>&1)
echo "== The system that gets installed ($sys)"
echo "$out"
fails=$(grep -c '^FAIL' <<<"$out")
[ "$(grep -c '^\(PASS\|FAIL\): ' <<<"$out")" -ge $((26 + $(wc -w <<<"$apps"))) ] || { echo "FAIL: not all system checks ran"; fails=$((fails+1)); }
if [ -n "$live" ]; then
  out=$(run_in "$live" "$live_checks" 2>&1)
  echo "== The live USB system and installer ($live)"
  echo "$out"
  fails=$((fails + $(grep -c '^FAIL' <<<"$out")))
  [ "$(grep -c '^\(PASS\|FAIL\): ' <<<"$out")" -ge 11 ] || { echo "FAIL: not all USB checks ran"; fails=$((fails+1)); }
  # The copy on the USB must be exactly the system checked above.
  id=$(sudo podman image inspect "$sys" --format '{{.Id}}')
  if run_in "$live" "grep -qF $id /var/lib/containers/storage/overlay-images/images.json" >/dev/null 2>&1; then
    echo "PASS: the copy on the USB is exactly the system checked above"
  else
    echo "FAIL: the copy on the USB is not the system checked above"; fails=$((fails+1))
  fi
fi
if [ "$fails" -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "$fails CHECK(S) FAILED"; exit 1; fi
