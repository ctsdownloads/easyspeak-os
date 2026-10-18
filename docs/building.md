# How it's built

[Back to the EasySpeakOS README](../README.md)

## How it's built

[GitHub Actions](../.github/workflows/build.yml) builds and signs the image on
every push (except README-only ones) and daily at 10:05 UTC from the latest
Fedora Silverblue 44 image, and publishes it to `ghcr.io/ctsdownloads/easyspeak-os`.

| Path | Purpose |
|------|---------|
| `Containerfile` | Starts from `silverblue:44` and runs the build script |
| `build_files/build.sh` | Installs the packages and EasySpeak, ships the signing policy, and runs the checks below |
| `build_files/bluefin-packages.txt` | The Fedora packages carried over from Bluefin |
| `build_files/easyspeak-os-codecs` | Installed as `easyspeak-os-codecs` (also `codecs` and `install-codecs`), the optional command and windows that add media codecs |
| `build_files/easyspeak-os-codecs-setup`, `-admin`, `-lib.sh` | The two privileged helpers and their shared fixed settings, run through polkit |
| `build_files/dev.easyspeak.os.codecs.policy`, `50-easyspeak-os-codecs.rules` | The polkit policy and the one narrow rule that lets the codecs be added without a password |
| `build_files/rpmfusion-free.repo`, `rpmfusion-free-updates.repo` | The RPM Fusion free repositories, copied into place only when you choose Everything |
| `build_files/easyspeak-os-update`, `easyspeak-os-update.desktop` | **System Update** in Show Apps, which runs `uupd` and shows each step |
| `build_files/easyspeak_os_update.py`, `easyspeak_os_apps.py`, `check-easyspeak-plugin.py` | The "update system", "install a package", "remove an app", "repair app boxes" and "start apps at login" voice commands, added to EasySpeak's plugin folder, and the build test that they load |
| `build_files/easyspeak-os-packages`, `easyspeak-os-install-package.desktop`, `easyspeak-os-remove-apps.desktop`, `easyspeak-os-repair-boxes.desktop`, `easyspeak-os-login-apps.desktop`, `gnome-mimeapps.list` | **Install Package File**, **Remove Apps**, **Repair App Boxes** and **Start Apps at Login**, and the setting that opens .rpm and .deb files in them (`gnome-mimeapps.list`, installed as `/etc/xdg/gnome-mimeapps.list`, which also opens Flatpak files in Bazaar and leaves Fedora's own list, with text files in Text Editor, as it is) |
| `build_files/easyspeak-os-packages-after-restart.desktop` | Runs once at login after something was added to the system, to say whether it is ready (and, for a printer driver, to add the printer) |
| `build_files/easyspeak-os-dialog`, `easyspeak_os_dialogs.py` | zenity plus voice: the EasySpeakOS windows go through it, and the plugin lets EasySpeak press their buttons, pick list lines and read them out |
| `build_files/os-commands.py` | Reads the EasySpeakOS voice commands from the plugins for the help overlay, the cheat sheet and "did you mean" |
| `build_files/easyspeak-os-box-run` | Starts box apps for their Show Apps entries with their messages in a log file, and stops them (the Quit action) |
| `build_files/easyspeak-os-hwrules`, `dev.easyspeak.os.hwrules.policy` | The helper that adds or removes an app's hardware rules on the system, and its polkit policy (password every time) |
| `build_files/check-packages.py` | The build test that Install Package File reads real packages correctly |
| `build_files/check-docs.py` | The build test that the README's table of contents and the help keep up with the software |
| `build_files/easyspeak-os-tools`, `easyspeak-os-tools.desktop`, `easyspeak_os_tools.py` | **System Tools** in Show Apps, and the "system tools" and "setup checklist" voice commands |
| `build_files/easyspeak-os-setup-checklist.desktop` | Opens the setup checklist once, at a new user's first login |
| `build_files/zz-easyspeak-os-windows.gschema.override` | Gives every window a minimize and a maximize button |
| `build_files/zz-easyspeak-os-desktop.gschema.override` | No hot corner, the battery percentage in the top bar, and the dock |
| `build_files/easyspeak-os-logo-menu.dconf`, `branding/logo-EasySpeak-mark.svg` | Turns on the Logo Menu extension for every user, with its defaults: the EasySpeakOS logo (the speech bubble of `branding/logo-EasySpeak.svg`, without the name) as its icon, Bazaar, Ghostty, no Activities button and no Force Quit |
| `build_files/xdg-terminals.list` | Makes Ghostty the default terminal for xdg-terminal-exec |
| `build_files/60-easyspeak-os-mic.conf` | WirePlumber setting: a microphone with no saved volume starts at 50% |
| `build_files/easyspeak-os-quick-settings.dconf` | Turns on EasySpeak's toggle in the Quick Settings menu for every user (a system default; EasySpeak itself is unchanged) |
| `build_files/default-apps.txt`, `flathub-apps.txt`, `easyspeak-os-flathub-apps`, `easyspeak-os-flatpak-apps.service` | The default apps: Fedora packages in the image, and the four from Flathub, installed straight from Flathub at the first start with internet (tried again every 15 minutes until it works). Fedora's own Flatpak store is not added |
| `build_files/easyspeak_os_software.py` | The "open software", "open app store" and "open bazaar" voice commands, which open Bazaar (and "close software"). It goes before EasySpeak's own apps plugin, which would look for GNOME Software |
| `build_files/easyspeak-os-app-folders.dconf` | The Show Apps folders for every new user: GNOME's Utilities and System folders, with the EasySpeakOS tools added to Utilities |
| `build_files/zz-easyspeak-os-login.gschema.override`, `branding/easyspeak-os-gdm-logo.png` | The EasySpeakOS logo at the bottom of the login screen (`branding/logo-EasySpeak-wide.svg` is its source) |
| `build_files/fastfetch-logo.txt`, `fastfetch-config.jsonc` | fastfetch's EasySpeakOS logo, and the system-wide setting that uses it |
| `build_files/zz-easyspeak-os-no-tour.gschema.override` | No GNOME "Welcome" tour popup at first login, so the setup checklist is the first window. The GNOME Tour app is also removed |
| `build_files/changes.txt` | Not in the repository: the build writes it from the last 60 changes' titles, and System Update reads it to say what's new |
| `build_files/easyspeak-os-tools-admin`, `dev.easyspeak.os.tools.policy` | The helper that turns automatic updates off (administrator password) and checks automatic disk unlock, and the polkit policy for both helpers |
| `build_files/easyspeak-os-tools-safe`, `50-easyspeak-os-tools.rules` | The helper for the System Tools jobs with no password (automatic updates on, automatic disk unlock, freeing up space), and the narrow rule that lets an administrator at the computer run only it without one |
| `iso/Containerfile`, `iso/src/`, `.github/workflows/build-iso.yml` | The live USB: the live session, its welcome window, and the EasySpeakOS installer, which installs EasySpeakOS from the copy on the stick. Its screens (`iso/src/easyspeak-os-installer/`) run as the live user and are answered by voice through the dialogs plugin; the part that changes the disk (`iso/src/easyspeak-os-install-engine`) runs as root through its own polkit action, on the live USB only. It partitions the disk (EFI, /boot, root), encrypts the root with LUKS2 when chosen, installs with `bootc install to-filesystem`, points updates at the signed image on GitHub, and writes the choices into the new system. The build fails if Fedora's installer is still on the USB, or if the installer's files or lists are missing |
| `iso/build-local-iso.sh` | Builds a test live ISO on your own computer from the code in the folder, before anything goes to GitHub |
| `iso/verify-image.sh` | Checks inside the built system and the live USB system that every EasySpeakOS change is there (name, installer, desktop defaults, Firefox, fastfetch), and prints PASS or FAIL for each; the local build stops before making the ISO if any fail |
| `build_files/easyspeak-os-disk-unlock-check.service` | At every start, checks on the disk whether automatic disk unlock is on, for System Tools and the setup checklist |
| `build_files/easyspeak-os-flathub.service`, `flathub.flatpakrepo` | Add the Flathub remote on first boot |
| `build_files/rebrand.sh` | Replaces the logo and release packages from Fedora with the generic ones and sets the system name, shown as "EasySpeakOS" |
| `build_files/initramfs.sh` | Rebuilds the boot image so the boot and disk-unlock screens carry no Fedora logo |
| `build_files/easyspeak-os-boot-label` | Installed as `easyspeak-os-boot-label`, an optional command that renames the firmware boot-menu entry |
| `build_files/make-cheatsheet.py` | Turns EasySpeak's command docs, plus the EasySpeakOS commands, into the cheat sheet and the on-screen list |
| `system_files/` | Files copied into the image, including the Ready Dot extension |
| `cosign.pub` | Public key for verifying the image |

What the build checks:

- Each EasySpeak RPM is verified against the sha256 digest GitHub publishes for
  it before it is installed. The release list is read from GitHub's API with the
  repository's own token, passed to the build as a secret and never stored in the
  image, because anonymous API calls from GitHub's shared build machines are
  often refused.
- The build fails if a new EasySpeak release changes the log lines Ready Dot
  reads, so the image does not ship a dot that shows the wrong thing.
- If the build fails before the push step, no image is published and the last
  good one stays. Signing runs after the push, so a failed signing step leaves
  an unsigned image that a signed rebase rejects.
- If the cheat sheet cannot be generated, the image still builds without it.
- The rebrand and boot-image steps fail the build if anything unexpected would be removed, if the logo or release packages from Fedora are still installed, or if the new boot image lacks what is needed to unlock a disk, including with the security chip (TPM).
- GNOME Software is removed; Bazaar is the app store. The build fails if GNOME Software is still installed, if Bazaar or its Super-search files are missing, if text files would not open in Text Editor, if an EasySpeakOS tool is missing from the Utilities folder, or if the login logo is not set. `uupd` is the only OS updater.
- The build fails if EasySpeak no longer orders its plugins by `PRIORITY`, which "open software" needs to reach Bazaar.
- The build fails if Fedora's default-service files are missing, if Tailscale, the updater or the Homebrew setup would not be switched on, if tuned is not Bluefin's version, if the RPM Fusion signing key is missing, or if RPM Fusion's codecs would not install on the image (a test run of the Everything choice, nothing is installed).
- The build fails if an EasySpeakOS voice command is missing from the "help" list, or if EasySpeak would not load the plugins the way it loads its own (the dialogs plugin is also tried against a pretend open window and a numbered list).
- The build fails if the README's table of contents does not list every section, in order, with working links, if a link inside the README goes to a section that does not exist, or if a button in the software windows or System Tools is missing from the help's Software section. So a change that adds a section or a button cannot merge until the README and the help match.
- The build fails if .rpm and .deb files would not open in Install Package File, if a tool it needs is missing, or if it misreads four real Fedora packages (an app, a background service, a hardware rule and a download source).

The release packages from Fedora also hold Fedora's lists of which services
start by themselves (systemd presets). The rebrand step copies those lists out
before removing the packages and puts them back unchanged, so a fresh install
switches on the same services Fedora does. `uupd` and Homebrew (`ublue-brew`)
come from Universal Blue's package repository, which is used only during the
build and is not left enabled on the system.

EasySpeak installs into `/opt`, which is a symlink to `/var/opt` on Fedora Atomic systems and
is not part of the image. The build makes `/opt` a real directory, moves the
files to `/usr/lib/opt/easyspeak`, and adds a tmpfiles rule that links
`/opt/easyspeak` back at boot.

## Media codecs

Some audio and video formats (H.264 and H.265, for example) are covered by
patents in some countries. Fedora leaves them out, and so does this image.
Adding them is optional, it is your choice, and it is your responsibility to
check what is legal where you live. EasySpeak does not need them.

The first time you log in after this image first boots, the
[setup checklist](install.md#first-login) asks whether you want them, with three large buttons: **Web video only**, **Everything** and
**Not now**. You can open the same window again at any time from **Install
Media Codecs** in Show Apps, or type the commands (`codecs` is the short
name; `easyspeak-os-codecs` and `install-codecs` also work):

    codecs          # explains the options, changes nothing
    codecs web      # web video in Firefox only
    codecs full     # the full ffmpeg set
    codecs remove   # takes them out again

- **Web video only** replaces Fedora's empty OpenH264 stand-in (`noopenh264`)
  with Cisco's OpenH264 from the Cisco repository that Fedora provides, so Firefox
  can play most H.264 web video. Cisco provides it under its own H.264 patent
  license. `codecs remove` puts the stand-in back.
- **Everything** replaces the free ffmpeg libraries from Fedora with the full ffmpeg,
  x264 and x265 from [RPM Fusion](https://rpmfusion.org/), the source standard
  Fedora uses. The repository definitions ship inside the image, and the signing
  key (fingerprint `E9A4 91A3 DE24 7814 E7E0 67EA E06F 8ECD D651 FF2E`) comes
  from Fedora's own `distribution-gpg-keys` package. These packages are added
  on top of the system, so on a machine that has them, system updates take a
  little longer.

### Passwords

Adding the codecs needs no password. It works through one narrow exception in
the system's permission check (polkit). It works only for the administrator
account, only for someone sitting at the machine, and only with the words
`web`, `full` or `skip` (`skip` only closes the first-login question), and it
installs a fixed package list from the pinned repository. It cannot run
anything else. Every action is written to the system log with the user who
asked.

Taking them out (`codecs remove`) asks for your administrator password in the
standard system box. If you would rather always be asked, override the rule
with an empty file of the same name in `/etc/polkit-1/rules.d/`.

Restart afterwards. `rpm-ostree rollback` returns to the previous state.

## Boot menu name

New installs from the live USB are named EasySpeakOS in the computer's boot
menu. The live USB carries no Fedora boot files (it needs Secure Boot off, see
[From the live USB](install.md#from-the-live-usb)). A computer that was installed before
keeps the name it got then (for example "Fedora", "Generic" or "bluefin"). That
name is stored on your machine, so an image update cannot change it. To rename
it:

    sudo easyspeak-os-boot-label          # shows what would change
    sudo easyspeak-os-boot-label --apply  # makes the change
