# EasySpeak-OS

An image for a workstation, with [EasySpeak](https://easyspeak.dev/latest/)
voice control installed for accessibility. It is a derivative of **Fedora®**,
built upon Fedora Silverblue 44, with a set of packages carried over from
[Bluefin](https://projectbluefin.io/), Bluefin's updater and Homebrew setup,
EasySpeak, and a small GNOME extension that shows what EasySpeak is doing.

> **EasySpeak-OS is not Fedora.** It contains modified Fedora software and is
> not provided or supported by the Fedora Project. The logos and release
> packages from Fedora have been removed. Official, unmodified Fedora is available from the
> Fedora Project at <https://fedoraproject.org/>.
>
> Fedora is a registered trademark of Red Hat, Inc., or its subsidiaries in the
> United States and other countries. This project is not affiliated with or
> endorsed by the Fedora Project or Red Hat.

[![Build](https://github.com/ctsdownloads/easyspeak-os/actions/workflows/build.yml/badge.svg)](https://github.com/ctsdownloads/easyspeak-os/actions/workflows/build.yml)
[![Status](https://img.shields.io/badge/status-pre--alpha-red.svg)](#status)
[![Base](https://img.shields.io/badge/base-Fedora%20Silverblue%2044-1f6feb.svg)](https://fedoraproject.org/atomic-desktops/silverblue/)
[![Desktop](https://img.shields.io/badge/desktop-GNOME%20%7C%20Wayland-green.svg)](https://www.gnome.org/)
[![Signed](https://img.shields.io/badge/images-signed%20with%20cosign-lightgrey.svg)](#verifying-the-signature)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

## Status

> ⚠️ **Pre-alpha.** This is a personal workstation image shared as-is.
> EasySpeak itself is alpha software, and this image installs new EasySpeak
> releases automatically, so something can break on any given day. There is no
> warranty and no support commitment. Roll back with `rpm-ostree rollback`.

It has been used on the author's own machine only. It is not an official
Universal Blue, Bluefin or EasySpeak product, and none of them endorse it.

## What's in it

| Part | Details |
|------|---------|
| Base | [Fedora Silverblue 44](https://fedoraproject.org/atomic-desktops/silverblue/) (`quay.io/fedora-ostree-desktops/silverblue:44`), with the logos and release packages from Fedora replaced by the generic ones |
| Packages | firefox, qutebrowser, v4l-utils, wtype, ydotool, xdg-terminal-exec, and the Fedora packages Bluefin adds that are listed in [`build_files/bluefin-packages.txt`](build_files/bluefin-packages.txt) |
| Updates | Automatic, with Bluefin's updater `uupd`: the system, Flatpaks, Distrobox containers and Homebrew. See [Updating and rolling back](#updating-and-rolling-back) |
| Homebrew | Set up on first boot, as on Bluefin, for command-line tools (`brew`) |
| ujust | Bluefin's command runner, for example `ujust update` |
| Services on by default | Fedora's own defaults (power management, DNS, SSD trim and others), plus Tailscale and Podman's automatic container updates, as on Bluefin |
| Power management | tuned 2.27.0, the version Bluefin ships. See [Known limitations](#known-limitations) |
| Codecs | Not included. Fedora leaves out patent-encumbered video codecs and so does this image. A window at first login offers them, with no password, and **Install Media Codecs** in the app grid offers them later. See [Media codecs](#media-codecs) |
| Apps from .rpm and .deb files | **Install Package File** puts them in a box (Distrobox) and adds them to the app grid; **Remove Apps** takes them out. See [Apps from .rpm and .deb files](#apps-from-rpm-and-deb-files) |
| Flathub | Added as a Flatpak remote on first boot, so Flatpak apps and runtimes such as `ffmpeg-full` can be installed straight away. The Flathub entry that comes with Fedora, which stays off until you opt in, is removed |
| [EasySpeak](https://github.com/ctsdownloads/easyspeak) | The newest release and its Parakeet and English speech packs, installed when the image is built |
| Ready Dot | A GNOME Shell extension: a status dot, "did you mean" suggestions, and an on-screen command list ([details](#using-it)) |
| Command cheat sheet | An offline page of EasySpeak's commands, opened from the app grid |

## Install

You need an existing Fedora Atomic system (Silverblue, Bluefin or similar) and
[rpm-ostree](https://coreos.github.io/rpm-ostree/). Do this **once per
machine**. It takes two rebases because the image ships its own signature
policy: the first is unverified because a fresh machine has no key yet and this
step installs it, and the second is verified.

```
rpm-ostree rebase ostree-unverified-registry:ghcr.io/ctsdownloads/easyspeak-os:latest
systemctl reboot
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ctsdownloads/easyspeak-os:latest
systemctl reboot
```

### Updating and rolling back

Updates are automatic. Bluefin's updater, `uupd`, runs on its own timer and
updates the system, Flatpaks, Distrobox containers and Homebrew. A new system
image takes effect at the next reboot. To update by hand, open **System Update**
from the app grid, which shows progress and offers a restart when a new system
image is ready and needs no password. If the automatic update is already running
when you open it, it says so and follows that update to the end instead of
failing (only one update can run at a time). Or run:

```
sudo uupd
```

`uupd` updates the system with `bootc`, and falls back to `rpm-ostree` when
needed, for example when packages such as the full codecs are layered on top of
the image. `rpm-ostree upgrade` also still works. To go back to the previous
image:

```
rpm-ostree rollback
```

To see when the next automatic update runs: `systemctl list-timers uupd.timer`.

### Verifying the signature

```
cosign verify --key cosign.pub ghcr.io/ctsdownloads/easyspeak-os:latest
```

### First login

- Log out and back in once so GNOME loads EasySpeak's shell extension.
- Run `sudo usermod -aG input "$USER"` for hold-to-dictate, then log in again.
- The Ready Dot extension switches itself on at your first login after the
  update. If you turn it off later it stays off:
  `gnome-extensions disable ready-dot@easyspeak-os`.
- If `easyspeak` fails with a bad interpreter error, remove an old
  `~/.local/bin/easyspeak` left over from a source install.

## Using it

Say "Hey Jarvis", wait for the chime, then say a command.

- **Ready Dot.** A dot in the top bar. Yellow: go ahead and speak, no wake word
  needed. Orange: EasySpeak is busy hearing, thinking or replying. No dot: it is
  waiting for the wake word.
- **Did you mean.** When EasySpeak says it did not understand, a small card
  under the top bar offers the closest real commands for about 7 seconds. It
  only suggests from EasySpeak's own command list, and shows nothing when
  nothing is close.
- **Help.** Say "help" after the wake word and the full command list appears on
  screen. It stays until you speak again, or for 90 seconds. EasySpeak will
  still say "Check the terminal"; ignore that.
- **Update by voice.** Say "update system" (or "install updates") after the wake word to open
  **System Update**, the same window as in the app grid. This command comes from EasySpeak-OS,
  as a plugin added to EasySpeak's plugin folder, and works in English only.
- **Install and remove apps by voice.** Say "install a package" to open
  **Install Package File**, "remove an app" to open **Remove Apps**, or "repair
  app boxes" to open **Repair App Boxes**. These also come from EasySpeak-OS as
  a plugin, in English only.
- **Answer EasySpeak-OS windows by voice.** While an EasySpeak-OS window is open
  (Install Package File, Remove Apps, Repair App Boxes, System Update, Install
  Media Codecs), say a button's name to press it: "set up and install", "open
  it", "restart now", "cancel". In a list, say "number two" (each line shows its
  number) or the name on the line. Say "read it" to hear the window and the buttons you can say. The window
  is never read out by itself: the open microphone would hear it and could press
  one of its buttons. When no such window is open, these words do nothing, so
  they never get in the way of other commands. English only.
- **The EasySpeak-OS commands are in the help.** "help", the cheat sheet and the
  "did you mean" card include them, in their own EasySpeak-OS section. The list is
  read from the plugins when the image is built, so a new command shows up there
  without anyone remembering to add it.
- **Command cheat sheet.** Open **EasySpeak Commands** from the app grid. The
  everyday commands are open and the long mode sections are folded.

## Apps from .rpm and .deb files

The system is an image, so packages are not installed into it directly. Open an
.rpm or .deb file (double-click it, open **Install Package File** from the app
grid, or say "install a package"), and EasySpeak-OS:

1. Checks what the package contains, without installing anything. A package
   made for a different kind of processor (ARM, or 32-bit only) is stopped here,
   with the reason.
2. Offers Flathub instead when Flathub has the same app, since Flathub apps
   update on their own.
3. Puts .rpm files in a Fedora box and .deb files in an Ubuntu 24.04 box. Each
   box is a Distrobox container, kept separate from any boxes of your own.
4. Adds the app to the app grid. A package with no app gets its commands on your
   `PATH` (`~/.local/bin`) instead.

System Update keeps the boxes up to date, along with everything else.

**Updates.** After an install, the last window says how the app gets updates:

- "System Update keeps it up to date, from its maker's download source": the
  package added its maker's download source to the box (Google Chrome and VS Code
  do), so System Update updates it with the box.
- "System Update cannot update it, because it came from a file": some apps, like
  Discord, offer their own updates; otherwise, open a newer file to update it.
- From Flathub: System Update keeps it up to date.
- Added to the system: System Update does not update it, because the system keeps
  a package added from a file at that file's version.

**One at a time.** If another install or removal is running, the window names it
("Installing Discord in the Ubuntu box"), waits for it to finish, then goes on.
It has a Cancel button.

**Deleting an empty box.** When you remove the last app from a box, it offers
to delete the box and says how much space that frees; the box is set up again by
itself the next time it is needed.

Each box also gets two small desktop parts that apps from these files expect and
a fresh box lacks: zenity, for progress windows (Discord's first start downloads
the rest of Discord and shows its progress with it; without zenity there is no
window at all), and notify-send, for notifications. They are added while the box
is set up. A box made before this was added gets them once, quietly, at the next
login. Opening links is left to Distrobox, which already sends it to your desktop.

Setting up a box and adding a package to the system also send a desktop
notification when they start, so you know it is working even if the progress
window opens behind another window.

**Starting and stopping box apps.** An app's app grid entry starts it through
`easyspeak-os-box-run`, not straight through Distrobox:

- The app's messages go to `~/.cache/easyspeak-os/logs/<app>.log`, not back
  through its link to the desktop. If that link goes away (for example when a
  task manager's Force Stop ends it), the app keeps working instead of crashing
  with "write EPIPE" error windows, as Discord did.
- Right-click the app in the app grid or dash and choose **Quit <app>** to stop
  it inside the box, even when it is stuck: it is asked to quit, and forced to
  after 10 seconds. A normal Stop from the desktop is passed on to the app too.
- Remove Apps quits a running app before removing it.

App grid entries made before this are switched over once, at the next login.

**Already installed?** Before anything else, it checks whether the app is
already there, and asks instead of installing again:

| Already there | What it says |
|---------------|--------------|
| In its box, same version | "already installed (version …)": **Open it**, **Reinstall** or Cancel |
| In its box, older version | "Update … from version … to …?": **Update** or Cancel |
| In its box, newer version | "This file is an older version …": **Install the older version** or Cancel |
| From Flathub (installed any way) | "already installed from Flathub": **Open it**, **Install the file too** or Cancel |
| In the other box | "already installed in the Fedora box": **Open it**, **Install it here too** or Cancel |
| On the system (part of it) | "already part of your system" |
| On the system (added with Install Package File) | Same version: says so. Newer file: offers to update it (administrator password, restart) |

**The first time.** Before anything is downloaded, one window explains what the
box means for you: the app opens from the app grid like any other, it can use
the files in your home folder, your system itself is not changed, and Remove
Apps takes it out cleanly. It gives the real download size (looked up from the
image, about 375 MB for the Fedora box and 210 MB for the Ubuntu box at the time
of writing). One button, **Set up and install**, does both. The progress window
shows plain steps (downloading, creating, getting it ready, installing) rather
than the tools' own output, says how long a long step has been going once a
minute, and has a **Cancel** button while the box is being set up. Cancelling,
or a failed setup, leaves no half-made box.

**When something goes wrong,** the window says why in plain words for the usual
reasons: no internet connection, a full disk, a package made for a different
Fedora or Ubuntu version (naming what it needs), a file that would replace part
of the system, or the password not given. Otherwise it shows the last lines of
the log. The full log is in `~/.cache/easyspeak-os/packages/last.log`.

**Repairing a box.** If a box stops working, installing into it offers
**Repair the box**: the box is set up again from scratch, the apps that were
installed into it with Install Package File are put back from the saved copies
of their files, and then the new app is installed. **Repair App Boxes** in the
app grid (or "repair app boxes") does the same at any time. When System Update
cannot update the boxes, it offers to check them and repairs only a box that is
broken; if the broken one is a box of your own, it says so instead. Repair does
not touch your files, and things installed inside a box some other way are not
put back.

What works in a box, and what needs the system itself:

| The package has | What happens |
|-----------------|--------------|
| An app, command-line tools, a browser, most closed-source apps | Installed in the box |
| A hardware rule (udev) that only sets device permissions | The app goes in the box and the rule goes onto the system, with the administrator password. A package that is only a rule (Fedora's `solaar-udev`, for example) just adds the rule |
| A hardware rule that runs a program | Not added. The app still goes in the box, and the window says the rule will not work |
| A background service, alongside an app | The app goes in the box and the window says the service will not start with the computer. An .rpm can be added to the system instead |
| A driver, firmware, printer or scanner driver, login or network plugin, or a background service with no app | Cannot work in a box. An .rpm can be added to the system (administrator password, after a restart, slower system updates, and it does not update by itself). A .deb is refused, with the reason |

**Printer drivers.** Most printers need no driver: they show up by themselves in
Settings, under Printers. So a printer driver first offers to open Printers and
try that. If the printer still needs the driver:

- **.rpm:** it is added to the system (administrator password, then a restart).
  At the next login a window says the driver is ready and opens Printers to add
  the printer, or says plainly if the driver did not make it onto the system.
- **.deb:** the system cannot take it. The window names the maker when the
  package says who it is (HP, Brother, Canon, Epson and others), and explains how
  to get the .rpm version from the maker's support site.

Anything else added to the system gets the same one-time check at the next
login.

Hardware rules and other packages the install pulls in are checked too: if Fedora's
`solaar` brings in `solaar-udev`, its rule is offered for the system as well.

**Remove Apps** (or "remove an app") lists everything installed this way and
undoes it: it removes the app from its box, the app grid entry, any hardware
rule it added, or the layered package. What was installed is recorded in
`~/.local/share/easyspeak-os/apps.json`. To see what a package needs without
installing it, run `easyspeak-os-packages check FILE`.

## How it's built

[GitHub Actions](.github/workflows/build.yml) builds and signs the image on
every push (except README-only ones) and daily at 10:05 UTC from the latest
Fedora Silverblue 44 image, and publishes it to `ghcr.io/ctsdownloads/easyspeak-os`.

| Path | Purpose |
|------|---------|
| `Containerfile` | Starts from `silverblue:44` and runs the build script |
| `build_files/build.sh` | Installs the packages and EasySpeak, ships the signing policy, and runs the checks below |
| `build_files/bluefin-packages.txt` | The Fedora packages carried over from Bluefin |
| `build_files/easyspeak-os-codecs` | Installed as `easyspeak-os-codecs` (also `codecs` and `install-codecs`), the optional command and windows that add media codecs |
| `build_files/easyspeak-os-codecs-setup`, `-admin`, `-lib.sh` | The two privileged helpers and their shared fixed settings, run through polkit |
| `build_files/dev.easyspeak.os.codecs.policy`, `50-easyspeak-os-codecs.rules` | The polkit policy and the one narrow rule that skips the password during first-time setup |
| `build_files/rpmfusion-free.repo`, `rpmfusion-free-updates.repo` | The RPM Fusion free repositories, copied into place only when you choose Everything |
| `build_files/easyspeak-os-update`, `easyspeak-os-update.desktop` | **System Update** in the app grid, which runs `uupd` and shows each step |
| `build_files/easyspeak_os_update.py`, `easyspeak_os_apps.py`, `check-easyspeak-plugin.py` | The "update system", "install a package", "remove an app" and "repair app boxes" voice commands, added to EasySpeak's plugin folder, and the build test that they load |
| `build_files/easyspeak-os-packages`, `easyspeak-os-install-package.desktop`, `easyspeak-os-remove-apps.desktop`, `easyspeak-os-repair-boxes.desktop`, `gnome-mimeapps.list` | **Install Package File**, **Remove Apps** and **Repair App Boxes**, and the setting that opens .rpm and .deb files in them |
| `build_files/easyspeak-os-packages-after-restart.desktop` | Runs once at login after something was added to the system, to say whether it is ready (and, for a printer driver, to add the printer) |
| `build_files/easyspeak-os-dialog`, `easyspeak_os_dialogs.py` | zenity plus voice: the EasySpeak-OS windows go through it, and the plugin lets EasySpeak press their buttons, pick list lines and read them out |
| `build_files/os-commands.py` | Reads the EasySpeak-OS voice commands from the plugins for the help overlay, the cheat sheet and "did you mean" |
| `build_files/easyspeak-os-box-run` | Starts box apps for their app grid entries with their messages in a log file, and stops them (the Quit action) |
| `build_files/easyspeak-os-hwrules`, `dev.easyspeak.os.hwrules.policy` | The helper that adds or removes an app's hardware rules on the system, and its polkit policy (password every time) |
| `build_files/check-packages.py` | The build test that Install Package File reads real packages correctly |
| `build_files/easyspeak-os-flathub.service`, `flathub.flatpakrepo` | Add the Flathub remote on first boot |
| `build_files/rebrand.sh` | Replaces the logo and release packages from Fedora with the generic ones and sets the system name |
| `build_files/initramfs.sh` | Rebuilds the boot image so the boot and disk-unlock screens carry no Fedora logo |
| `build_files/easyspeak-os-boot-label` | Installed as `easyspeak-os-boot-label`, an optional command that renames the firmware boot-menu entry |
| `build_files/make-cheatsheet.py` | Turns EasySpeak's command docs, plus the EasySpeak-OS commands, into the cheat sheet and the on-screen list |
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
- The rebrand and boot-image steps fail the build if anything unexpected would be removed, if the logo or release packages from Fedora are still installed, or if the new boot image lacks what is needed to unlock a disk.
- GNOME Software handles Flatpak apps and firmware only. The build removes its rpm-ostree and dnf plugins, so `uupd` is the only OS updater, and fails if either is still there.
- The build fails if Fedora's default-service files are missing, if Tailscale, the updater or the Homebrew setup would not be switched on, if GNOME Software's OS-update plugin is still installed (so there is only one updater), if tuned is not Bluefin's version, if the RPM Fusion signing key is missing, or if RPM Fusion's codecs would not install on the image (a test run of the Everything choice, nothing is installed).
- The build fails if an EasySpeak-OS voice command is missing from the "help" list, or if EasySpeak would not load the plugins the way it loads its own (the dialogs plugin is also tried against a pretend open window and a numbered list).
- The build fails if .rpm and .deb files would not open in Install Package File, if a tool it needs is missing, or if it misreads three real Fedora packages (an app, a background service and a hardware rule).

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

The first time you log in after this image first boots, a window asks whether
you want them, with three large buttons: **Web video only**, **Everything** and
**Not now**. You can open the same window again at any time from **Install
Media Codecs** in the app grid, or type the commands (`codecs` is the short
name; `easyspeak-os-codecs` and `install-codecs` also work):

    codecs          # explains the options, changes nothing
    codecs web      # web video in Firefox only
    codecs full     # the full ffmpeg set
    codecs remove   # takes them out again

- **Web video only** adds Cisco's OpenH264 from the Cisco repository that Fedora
  provides, so Firefox can play most H.264 web video. Cisco provides it under its own H.264
  patent license.
- **Everything** replaces the free ffmpeg libraries from Fedora with the full ffmpeg,
  x264 and x265 from [RPM Fusion](https://rpmfusion.org/), the source standard
  Fedora uses. The repository definitions ship inside the image, and the signing
  key (fingerprint `E9A4 91A3 DE24 7814 E7E0 67EA E06F 8ECD D651 FF2E`) comes
  from Fedora's own `distribution-gpg-keys` package. These packages are layered
  on top of the image, so on a machine that has them, system updates go
  through `rpm-ostree`.

### Passwords

During the first-time setup window, installing needs no password. The window
lasts at most 24 hours after the image first boots and closes as soon as you
answer. It works through one narrow polkit action. That action is limited to
the administrator (wheel) account at the machine, accepts only the words `web`,
`full` or `skip`, and installs a fixed package list from the pinned
repository. It cannot run anything else. Every action is written to the system
log with the user who asked.

At every other time, including `codecs remove`, the same commands ask for your
administrator password in the standard system box. If you would rather never
skip the password, delete `/usr/share/polkit-1/rules.d/50-easyspeak-os-codecs.rules`
(or override it in `/etc/polkit-1/rules.d/`), and the setup action asks for the
password too.

Restart afterwards. `rpm-ostree rollback` returns to the previous state.

## Boot menu name

Your firmware's boot menu keeps the name it got when you installed (for example
"Fedora" or "bluefin"). That name is stored on your machine, so an image update
cannot change it. To rename it:

    sudo easyspeak-os-boot-label          # shows what would change
    sudo easyspeak-os-boot-label --apply  # makes the change

## Known limitations

- "Did you mean" only works for commands said right after the wake word.
  EasySpeak does not log what it heard inside the browser, grid and dictation
  modes at its default log level, so there is nothing to react to there.
- The cheat sheet, the on-screen list and the suggestions come from EasySpeak's
  `docs/commands.md`. A command appears in them only if it is documented there.
- EasySpeak's RPMs are checked by the sha256 digest GitHub publishes, not by a
  signature, and a new release is installed automatically.
- Requires GNOME Shell 47 or newer on Wayland, which is EasySpeak's requirement.
- tuned is held at 2.27.0, the version Bluefin ships. Fedora's 2.28.0 froze the
  power-mode switch on the author's machine. To move to a newer version, change
  the version in `build_files/build.sh` once Bluefin does.
- The updater and Homebrew come from Universal Blue's package repository. If it
  becomes unavailable, the build fails and machines stay on the last good image,
  without updates, until the build is fixed.
- If RPM Fusion falls behind Fedora, for example right after a new Fedora
  version, the build fails and no image is published, so nobody moves ahead of
  RPM Fusion. Rebuild once RPM Fusion catches up. A short gap is still possible
  between builds; then a system update fails on machines with the full codecs.
  Nothing breaks: they stay on their current version until RPM Fusion catches up.

- An app installed from a plain .rpm or .deb file does not update by itself,
  unless the package adds its own repository (Google Chrome and Visual Studio
  Code do). To update it, install the newer file.
- Apps that manage disks or other hardware as root (GParted, for example)
  install in a box but cannot do their job there.

## Source code

This repository is the source for how the image is built. The software inside
the image comes from other projects, under their own licenses (some of them the
GPL), and its source is available from them:

- **Fedora packages**, which is almost everything in the image, come from the
  Fedora Project. Their source is at <https://src.fedoraproject.org/>. On a
  Fedora system, `rpm -q --qf '%{SOURCERPM}\n' <package>` names the source
  package of anything installed, and `dnf download --source <source package>`
  downloads it.
- **Optional codecs** are not part of the image. If you choose the full ffmpeg
  set, it comes from the [RPM Fusion](https://rpmfusion.org/) free repository,
  and its source packages (`ffmpeg`, `x264` and `x265`) are at
  <https://download1.rpmfusion.org/free/fedora/updates/44/SRPMS/>. If you choose
  OpenH264, it comes from Cisco through the Cisco repository that Fedora provides.
- **The updater and Homebrew setup** come from Universal Blue: `uupd` is at
  <https://github.com/ublue-os/uupd>, and the packages are built in
  <https://copr.fedorainfracloud.org/coprs/ublue-os/packages/>.
- **EasySpeak** is at <https://github.com/ctsdownloads/easyspeak>.
- **Everything else** that was added is in this repository.

If you cannot find the source for something in the image, open an issue at
<https://github.com/ctsdownloads/easyspeak-os/issues>.

## Credits

- [Universal Blue](https://universal-blue.org/) and the
  [image-template](https://github.com/ublue-os/image-template) this repository
  started from, and the [Bluefin](https://projectbluefin.io/) project
  ([source](https://github.com/ublue-os/bluefin),
  [docs](https://docs.projectbluefin.io/)).
- The [Fedora Project](https://fedoraproject.org/), [bootc](https://bootc.dev/)
  and [rpm-ostree](https://coreos.github.io/rpm-ostree/).
- [EasySpeak](https://github.com/ctsdownloads/easyspeak) and everything it
  builds on, listed in its
  [acknowledgments](https://github.com/ctsdownloads/easyspeak#acknowledgments).
- [cosign](https://github.com/sigstore/cosign) from Sigstore, for image
  signing.
- [Homebrew](https://brew.sh/), [Tailscale](https://tailscale.com/) and
  [RPM Fusion](https://rpmfusion.org/).
- [GNOME](https://www.gnome.org/), [qutebrowser](https://qutebrowser.org/),
  [Firefox](https://www.mozilla.org/firefox/),
  [wtype](https://github.com/atx/wtype),
  [ydotool](https://github.com/ReimuNotMoe/ydotool) and
  [v4l-utils](https://linuxtv.org/wiki/index.php/V4l-utils).

## License

**The files in this repository** (the build scripts, the boot-image and
rebrand steps, the Ready Dot extension and the helper commands) are under the
[Apache License 2.0](LICENSE).

**The image itself is not under that license.** EasySpeak-OS is built on
Fedora Silverblue. It is a collection of software from many other projects,
each under its own license, and this repository cannot change them. The Fedora
base alone declares hundreds of different license expressions, from the GPL
(the Linux kernel is GPL-2.0-only with the Linux syscall note) and LGPL to MIT
and BSD. Fedora explains its licensing at
<https://docs.fedoraproject.org/en-US/legal/>. See [Source code](#source-code)
for where to get the source.

Also under their own licenses:

- [EasySpeak](https://github.com/ctsdownloads/easyspeak) is
  [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).
- The optional codecs are not part of the image. If you install the full
  ffmpeg set from RPM Fusion, those packages declare ffmpeg as GPLv3+, x264 as
  GPLv2+, and x265 as GPLv2+ and BSD.
- The cheat sheet and the on-screen command list are generated at build time
  from EasySpeak's command documentation, so they fall under EasySpeak's
  license (GPL-3.0).
- The speech models in EasySpeak's packages have their own licenses, such as
  NVIDIA's Parakeet model (CC BY 4.0). EasySpeak lists them on its
  [license page](https://easyspeak.dev/latest/license/).

---

## Trademarks

Fedora® is a registered trademark of Red Hat, Inc., or its subsidiaries in the United States and other countries. EasySpeak-OS is not provided or supported by the Fedora Project, and is not affiliated with or endorsed by the Fedora Project or Red Hat.
