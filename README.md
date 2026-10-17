# EasySpeakOS

An image for a workstation, with [EasySpeak](https://easyspeak.dev/latest/)
voice control installed for accessibility. It is a derivative of **Fedora®**,
built upon Fedora Silverblue 44, with a set of packages carried over from
[Bluefin](https://projectbluefin.io/), Bluefin's updater and Homebrew setup,
EasySpeak, and a small GNOME extension that shows what EasySpeak is doing.

> **EasySpeakOS is not Fedora.** It contains modified Fedora software and is
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
[![Signed](https://img.shields.io/badge/images-signed%20with%20cosign-lightgrey.svg)](#checking-that-updates-are-real)
[![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue.svg)](LICENSE)

## Contents

<!-- contents -->
- [Status](#status)
- [Who it's for](#who-its-for)
- [How this system works](#how-this-system-works)
- [What's in it](#whats-in-it)
- [System requirements](#system-requirements)
- [Install](#install)
  - [From the live USB](#from-the-live-usb)
  - [From Silverblue or Bluefin](#from-silverblue-or-bluefin)
  - [Updating and rolling back](#updating-and-rolling-back)
  - [Checking that updates are real](#checking-that-updates-are-real)
  - [First login](#first-login)
- [Using it](#using-it)
  - [What works by voice](#what-works-by-voice)
- [Apps from .rpm and .deb files](#apps-from-rpm-and-deb-files)
  - [Installing an app](#installing-an-app)
  - [Apps that go on the system](#apps-that-go-on-the-system)
  - [Install from Fedora](#install-from-fedora)
  - [Restarting after adding to the system](#restarting-after-adding-to-the-system)
  - [Updates](#updates)
  - [Already installed](#already-installed)
  - [Files that cannot be installed](#files-that-cannot-be-installed)
  - [Download sources](#download-sources)
  - [Printer drivers](#printer-drivers)
  - [Start Apps at Login](#start-apps-at-login)
  - [Removing apps](#removing-apps)
  - [Repairing a box](#repairing-a-box)
  - [Disk space](#disk-space)
  - [One at a time](#one-at-a-time)
  - [Progress and notifications](#progress-and-notifications)
  - [Starting and stopping box apps](#starting-and-stopping-box-apps)
  - [When something goes wrong](#when-something-goes-wrong)
- [System Tools](#system-tools)
- [How it's built](#how-its-built)
- [Media codecs](#media-codecs)
  - [Passwords](#passwords)
- [Boot menu name](#boot-menu-name)
- [Known limitations](#known-limitations)
- [Source code](#source-code)
- [Credits](#credits)
- [License](#license)
- [Trademarks](#trademarks)
<!-- /contents -->

## Status

> ⚠️ **Pre-alpha.** This is a personal workstation image shared as-is.
> EasySpeak itself is alpha software, and this image installs new EasySpeak
> releases automatically, so something can break on any given day. There is no
> warranty and no support commitment. Roll back with `rpm-ostree rollback`.

It has been used on the author's own machine only. It is not an official
Universal Blue, Bluefin or EasySpeak product, and none of them endorse it.

## Who it's for

EasySpeakOS is for people who can see the screen and speak clearly in English,
but find a keyboard and mouse hard to use, for example because of RSI,
arthritis, a tremor or limited hand movement.

Most everyday things work by voice. Some still need typing, mainly passwords.
[What works by voice](#what-works-by-voice) lists both.

Someone comfortable with a terminal has to set it up: the [install](#install)
and the [first login](#first-login) steps are typed.

## How this system works

EasySpeakOS is an **image-based** system. The system itself, meaning
everything except your own files and settings, arrives as one finished, tested
piece called an image, and apps can't change it. That keeps it from breaking.

- **Updates** download a whole new image in the background. It's used from your
  next restart.
- **The previous version stays on disk.** If an update causes a problem, you can
  go back to it (see [Updating and rolling back](#updating-and-rolling-back)).
- **Apps** come from Bazaar, the app store, or go into a box. Only when they have to
  are they added to the system.

## What's in it

| Part | Details |
|------|---------|
| Base | [Fedora Silverblue 44](https://fedoraproject.org/atomic-desktops/silverblue/) (`quay.io/fedora-ostree-desktops/silverblue:44`), with the logos and release packages from Fedora replaced by the generic ones |
| Packages | firefox, qutebrowser, v4l-utils, wtype, ydotool, xdg-terminal-exec, and the Fedora packages Bluefin adds that are listed in [`build_files/bluefin-packages.txt`](build_files/bluefin-packages.txt) |
| Updates | Automatic, with Bluefin's updater `uupd`: the system, Flatpaks, app boxes and Homebrew. See [Updating and rolling back](#updating-and-rolling-back) |
| Homebrew | Set up on first boot, as on Bluefin, for command-line tools (`brew`). Terminal only, for people who use one |
| ujust | Bluefin's command runner, for example `ujust update`. Terminal only, for people who use one |
| Services on by default | Fedora's own defaults (power management, DNS, SSD trim and others), plus Tailscale (a private network between your own devices; it does nothing until you sign in to it) and Podman's automatic container updates (only for containers you set up to update that way), as on Bluefin |
| Power management | tuned 2.27.0, the version Bluefin ships. See [Known limitations](#known-limitations) |
| Codecs | Not included. Fedora leaves out patent-encumbered video codecs and so does this image. The [setup checklist](#first-login) at first login offers them, and **Install Media Codecs** in Show Apps offers them any time, with no password on an administrator account. See [Media codecs](#media-codecs) |
| Apps from .rpm and .deb files | **Install Package File** puts them in a box (Distrobox) and adds them to Show Apps; **Remove Apps** takes them out. See [Apps from .rpm and .deb files](#apps-from-rpm-and-deb-files) |
| Flathub | Added as a Flatpak remote on first boot, so Flatpak apps and runtimes such as `ffmpeg-full` can be installed straight away. The Flathub entry that comes with Fedora, which stays off until you opt in, is removed |
| [EasySpeak](https://github.com/ctsdownloads/easyspeak) | The newest release and its Parakeet and English speech packs, installed when the image is built |
| Ready Dot | A GNOME Shell extension: a status dot, "did you mean" suggestions, and an on-screen command list ([details](#using-it)) |
| Command cheat sheet | An offline page of EasySpeak's commands, opened from Show Apps |
| System Tools | Update firmware, unlock the disk automatically, free up disk space, restart into the BIOS settings, turn automatic updates on or off, undo the last update, save problem details for your helper, and the setup checklist, in plain windows. See [System Tools](#system-tools) |
| Window buttons | Every window has minimize, maximize and close buttons (GNOME's own default shows only close) |
| Desktop defaults | EasySpeak's on/off toggle is in the Quick Settings menu (top right) from the start. No hot corner (the pointer in the top-left corner doesn't open the Activities overview). The battery percentage shows in the top bar. Each can be changed back: the toggle in EasySpeak's Settings, the other two in Settings |
| Firefox | Opens Firefox's own home page, not Fedora's start page, with no Fedora tile |
| Default apps | Web: qutebrowser, Firefox. Writing: Text Editor, LibreOffice (Writer, Calc, Impress), Errands. Media: Lollypop, Shortwave, Podcasts, Celluloid. Viewing: Papers, Loupe. Files and system: Files, Ptyxis, Settings, Bazaar (the app store), Pika Backup. Accessibility: Orca, plus GNOME's Hover Click, Zoom and on-screen keyboard. Utilities: Calculator, Clocks, Calendar, Contacts, Weather, Characters. Fedora's own packages, in the image ([`build_files/default-apps.txt`](build_files/default-apps.txt)); Errands, Shortwave, Podcasts and Pika Backup aren't packaged by Fedora, so they come from Flathub on the first start with internet ([`build_files/flathub-apps.txt`](build_files/flathub-apps.txt)). No email app: use your own |
| App store | [Bazaar](https://github.com/kolunmi/bazaar), for Flathub apps, instead of GNOME Software (which is removed). Its apps show up in the Super-key search, and Flatpak files and links open in it. It comes from Universal Blue's package repository |
| Utilities folder | All EasySpeakOS tools (System Tools, System Update, Install Package File, Remove Apps, Repair App Boxes, Start Apps at Login, Install Media Codecs, EasySpeak Commands) are in the **Utilities** folder of Show Apps, with GNOME's own utilities |
| Default file apps | Text files open in Text Editor, .rpm and .deb files in Install Package File, Flatpak files in Bazaar. Everything else keeps Fedora's defaults |
| Login screen and boot menu | The login screen shows the EasySpeakOS logo at the bottom. The computer's boot menu lists EasySpeakOS for the installed system. The live USB carries no Fedora boot files and needs Secure Boot off; the installed system works with it on |
| fastfetch | Shows the EasySpeakOS logo instead of Fedora's |

## System requirements

- **Minimum:** 8 GB RAM. EasySpeak's speech model (Parakeet) alone uses about
  1.3 GB while it runs, on top of the desktop.
- **Recommended:** 16 GB RAM, especially if you use apps from .rpm or .deb files,
  since each app box adds to memory use.

## Install

There are two ways: from the live USB on any computer, or by switching a
computer that already runs Fedora Silverblue or Bluefin.

### From the live USB

The live USB starts EasySpeakOS straight from the stick, with EasySpeak
working, so you can try it before installing. Nothing is saved and the
computer's disk isn't touched until you install.

1. Make the USB stick: on GitHub, open **Actions**, then **Build live ISO
   (test)**, and **Run workflow**. When it finishes, download
   `easyspeak-os-live-iso` from that run, unzip it, and write
   `easyspeak-os-live.iso` to a USB stick at least as big as the file (with
   Fedora Media Writer, or GNOME Disks' **Restore Disk Image**). To try
   changes before they go to GitHub, build it on your own computer instead:
   run `iso/build-local-iso.sh` from the top of the repository, in a normal
   terminal (not a toolbox or distrobox). It needs about 70 GB free, asks for
   your password once, and puts the ISO in `~/Downloads/easyspeak-os-iso/`.
2. Turn Secure Boot off in the computer's BIOS settings: the live USB starts
   without Fedora's Secure Boot loader (shim), which made the boot menu list it
   as "Fedora". Then start the computer from the USB stick and pick
   **EasySpeakOS Live**.
3. A welcome window opens once EasySpeak has loaded: **Install EasySpeakOS**,
   or **Try it first**. Both can be said. The installer is also first in the
   dock.
4. The installer is EasySpeakOS's own. Every choice can be said; only
   passwords are typed. One screen at a time, it asks for: the language, the
   keyboard layouts, the keyboard used for the disk password at start-up, a
   network (only needed for automatic time), the time zone, the date and time,
   the clock (12 or 24 hour), the disk, encryption (recommended, with a disk
   password typed twice), the root account (locked unless you choose
   otherwise), your account (full name by dictation, user name, administrator
   or not, password), and the computer's name. Everything on the chosen disk
   is erased: the installer says so and goes on only when you say **Erase and
   install**. The **Review** at the end is read aloud; say a number to change
   that step, or **Install**. It installs EasySpeakOS from the copy on the USB
   stick, with no download, and says when it's finished; then say
   **Restart**. A Wi-Fi network joined during the install is saved on the new
   system, so it is online from its first start. The orange **Beta**
   badge at the top says EasySpeakOS is in beta.

   On every screen: say a line's number (up to "nine hundred ninety nine") or
   its name, a button's name, or **Read it** to hear the screen. Long lists
   have **Page down** and **Page up**, and **letter G** scrolls to the entries
   starting with G.

   If the install stops, nothing more is changed, and the installer offers,
   least typing first: **Save the log** (onto another USB stick, for your
   helper; no account needed), **Show a QR code** (a pre-filled problem report
   on this project's GitHub page, opened on a phone), or **Report on GitHub**
   (the same report in Firefox, which needs a free GitHub account and its
   password typed). The log leaves out the passwords and the names you typed.
5. Turn Secure Boot back on in the BIOS settings: the installed system starts
   with it on. Then log in. The [setup checklist](#first-login) opens.

The installed system gets its updates from GitHub and checks them against the
project's signature, like any other EasySpeakOS install (see
[Checking that updates are real](#checking-that-updates-are-real)). In the
live session nothing updates and no first-login questions are asked; the
installed system gets those on its first start.

### From Silverblue or Bluefin

You need a computer already running a **Fedora Atomic** system: an image-based
Fedora, such as Silverblue or Bluefin. Do this **once per machine**. It takes two rebases because the image ships its own signature
policy: the first is unverified because a fresh machine has no key yet and this
step installs it, and the second is verified.

```
rpm-ostree rebase ostree-unverified-registry:ghcr.io/ctsdownloads/easyspeak-os:latest
systemctl reboot
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ctsdownloads/easyspeak-os:latest
systemctl reboot
```

### Updating and rolling back

Updates are automatic. Bluefin's updater, `uupd`, runs every day at 4 am (or
when the computer next starts, if it was off or asleep then) and updates the
system, Flatpaks, app boxes and Homebrew. A new system
image takes effect at the next reboot. To update by hand, open **System Update**
from Show Apps, which shows progress and offers a restart when a new system
image is ready and needs no password. While the system itself updates, the
window says how big the download is and in how many parts, which part it is on
and about how much has come in so far. Then it installs in two or three steps
(unpacking the new version, adding the apps you put on the system if you have
any, and saving it for your next restart): the window says which step it is on
and how long that step has been going, and the bar moves with each part and
each step. When the new system is ready, the restart window also lists what's
new in it, from the titles of this project's changes since the version you're
using (changes to only the README or the build are left out). If the computer is on battery and the battery is low (under 20%,
the same limit the automatic update uses), it first says so and recommends
**Not now**: plug in, then start it again. **Update anyway** goes ahead. If the
automatic update is already running
when you open it, it says so and follows that update to the end instead of
failing (only one update can run at a time). Or run:

```
sudo uupd
```

`uupd` updates the system with `bootc`, and falls back to `rpm-ostree` when
needed, for example when packages such as the full codecs are added on top of
the system. `rpm-ostree upgrade` also still works.

To go back to the version you had before the last update (it's kept on disk),
use **Undo the last update** in [System Tools](#system-tools), or run
`rpm-ostree rollback` and restart. You can also pick it in the boot menu when
the computer starts.

To see when the next automatic update runs: `systemctl list-timers uupd.timer`.

### Checking that updates are real

Every update from this project carries a digital seal that only this project can
make. Before installing an update, your computer checks the seal and refuses any
update that's missing it or was changed along the way. So a fake or tampered
update can't get in. You don't need to do anything for this.

To check it yourself (terminal):

```
cosign verify --key cosign.pub ghcr.io/ctsdownloads/easyspeak-os:latest
```

### First login

- **The setup checklist** opens by itself at a new user's first login, as soon
  as EasySpeak has finished loading (GNOME's own welcome tour is turned off, so
  nothing opens on top of it), so its buttons can be said from the first
  window (if EasySpeak isn't running, it opens after 3 minutes anyway). It goes
  through four steps, one window each, and any can be skipped:
  1. **Check the microphone:** say "testing, testing" and it says whether the
     computer heard you. If not, it offers **Open sound settings** to choose the
     microphone, then **Test again**. It records with PipeWire, alongside
     EasySpeak, and keeps nothing.
  2. **Media codecs:** the [Media codecs](#media-codecs) window, with no
     password during the first day. Skipped if they're already added. Here it
     doesn't ask to restart; the checklist does that at the end.
  3. **Skip the disk password at startup:** **Unlock disk automatically** from
     System Tools. Only shown if the disk is encrypted, the computer has a
     security chip and it isn't on already. It needs the disk password, so it's
     a step for the helper.
  4. **How to get apps:** where apps come from, with **Open Bazaar** and
     **Open Install Package File** to see each one for real. The window comes
     back after each, until **Next**.

  Nothing in the middle of the checklist restarts the computer, so no step is
  lost. If the codecs were installed, the last window says they work after a
  restart and offers **Restart now** or **Later**. If disk unlock was turned
  on, it says the disk unlocks by itself from the next restart.

  **Later** opens it again at the next login. **Don't show again** stops that.
  Say "setup checklist", or pick it in System Tools, to open it any time. It
  doesn't open by itself for users who were set up before it existed.
- Log out and back in once so GNOME loads EasySpeak's shell extension.
- **Optional: hold-to-dictate.** Holding **Ctrl+Shift** lets you speak without
  saying "Hey Jarvis". You don't need it if pressing keys is hard for you,
  because the wake word does the same. To turn it on, run
  `sudo usermod -aG input "$USER"` and log in again. This lets your account read
  the keyboard and mouse directly, which EasySpeak needs to see the keys held
  down.
- The Ready Dot extension switches itself on at your first login after the
  update. If you turn it off later it stays off:
  `gnome-extensions disable ready-dot@easyspeak-os`.
- If `easyspeak` fails with a bad interpreter error, remove an old
  `~/.local/bin/easyspeak` left over from a source install.

## Using it

Say "Hey Jarvis", wait for the chime, then say a command.

Some commands switch EasySpeak into a **mode**, for example "grid" (point and
click), "browser" (the web, by link numbers) and "dictation" (typing by voice).
In a mode, you say commands without "Hey Jarvis". EasySpeak announces each mode,
and a mode ends by itself when you stop using it: after 30 seconds for grid, a
minute for dictation and 3 minutes for browser. EasySpeak's
[full command list](https://easyspeak.dev/latest/commands/) has every command.

**Show Apps** is GNOME's list of all apps: the button with nine dots at the end of
the dock, or press the Super key twice. The EasySpeakOS tools are in its
**Utilities** folder. (An account made before EasySpeakOS put them there keeps its own folders. To
get the new ones, run `dconf reset -f /org/gnome/desktop/app-folders/` in a
terminal as that user; folders you made yourself are removed too.)

**Bazaar** is the app store. Its apps come from **Flathub** as
**Flatpaks**: apps packed with everything they need and kept apart from the
system. That's why they're the recommended way to get apps here. They can't
break the system, and they update by themselves.

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
  **System Update**, the same window as in Show Apps. This command comes from EasySpeakOS,
  as a plugin added to EasySpeak's plugin folder, and works in English only.
- **Install and remove apps by voice.** Say "install a package" to open
  **Install Package File**, "remove an app" to open **Remove Apps**, "repair
  app boxes" to open **Repair App Boxes**, or "start apps at login" to open
  **Start Apps at Login**. These also come from EasySpeakOS as a plugin, in
  English only.
- **Answer EasySpeakOS windows by voice.** While an EasySpeakOS window is open
  (Install Package File, Remove Apps, Repair App Boxes, System Update, Install
  Media Codecs), say a button's name to press it: "set up and install", "open
  it", "restart now", "cancel". In a list, say "number two" (each line shows its
  number) or the name on the line. Say "read it" to hear the window and the buttons you can say.
  Apostrophes don't matter ("dont show again" and "do not show again" both press
  **Don't show again**). "Next" or "continue" presses the main button when it
  only moves forward (Start, Next, Test, OK), never one that changes or removes
  something, like Turn off. The window
  is never read out by itself: the open microphone would hear it and could press
  one of its buttons. When no such window is open, these words do nothing, so
  they never get in the way of other commands. English only.
- **The EasySpeakOS commands are in the help.** "help", the cheat sheet and the
  "did you mean" card include them, in two sections of their own: **EasySpeakOS**
  (update system, reading and answering windows) and **Software** (installing,
  removing and repairing apps, starting apps at login, and the buttons of those
  windows by name: ok, cancel, install, remove, use Flathub, delete the box and
  the rest). The list is
  read from the plugins when the image is built, so a new command shows up there
  without anyone remembering to add it.
- **Command cheat sheet.** Open **EasySpeak Commands** from Show Apps. The
  everyday commands are open and the long mode sections are folded.

### What works by voice

| To | By voice? | How |
|----|-----------|-----|
| Open an app | Yes, from a fixed list | "open firefox", "open files", "open settings", "open software" (Bazaar), "open calculator", "open editor" and the others in EasySpeak's list. Apps you install yourself are not on it |
| Browse the web | Yes, in qutebrowser | "browser", then link numbers, "search …", "go to …" and tabs. In Firefox, only with grid mode |
| Click anything on screen | Yes, but slowly | "grid", numbers to zoom in, then "click" |
| Type text | Yes | "dictation", into the field that has focus. Click the field first with grid mode or a link number |
| Volume, brightness, music, folders | Yes | "volume up", "pause", "open downloads" and so on |
| Install from an .rpm or .deb file in Downloads | Yes | "install a package", "number one" for the file, then say the buttons. If Bazaar (Flathub) has the same app, it offers that instead |
| Install from Bazaar (Flathub) | Yes, but slowly | "open software" (or "open app store", "open bazaar"), then grid mode to click the search box, dictation for the name, and grid mode to click Install |
| Add an app to the system | Partly | The same windows, but the administrator password is typed |
| Remove an app | Yes, if Install Package File installed it | "remove an app". Apps from Bazaar are removed there, with grid mode |
| Repair app boxes, or choose apps that start at login | Yes | "repair app boxes", "start apps at login" |
| Update everything (system, Flatpaks, app boxes) | Yes | Automatic, or "update system" |
| System Tools: firmware, disk unlock, free space, BIOS settings, automatic updates, undo the last update, problem details | Yes | "system tools", "number one" and so on for the tool, then say the buttons. Some jobs ask for a password, which is typed |
| Media codecs | Yes | Answer the window by voice. Adding them needs no password; taking them out asks for the administrator password |

**Still typed:**

- the password to log in and to unlock the screen
- the administrator password, when adding an app to the system, taking the
  codecs out, or for the System Tools jobs that keep it (see
  [System Tools](#system-tools))
- the disk password, once, when turning Unlock disk automatically on or off
- the install and first-login setup
- Homebrew, and anything else in a terminal

## Apps from .rpm and .deb files

The system is an image, so apps from .rpm and .deb files are not installed into
it directly. **Install Package File** puts them in a box, or on the system when
they need it. Every window that offers a choice says which button is recommended
and why, then what the other choice gives up.

**What's a box?** Apps from .rpm and .deb files don't go into the system itself.
They go into a "box": a small, separate Linux system just for those apps. That
keeps your system clean and makes apps easy to remove.

**Why repair one?** Rarely, a box stops working, for example after an update
inside it fails. Then its apps won't open, and nothing new can be installed into
it. **Repair** rebuilds the box and puts its apps back. Your files aren't
touched. See [Repairing a box](#repairing-a-box).

### Installing an app

1. Open the file: double-click it, open **Install Package File** from Show Apps
   and pick it from the list, or say "install a package".
2. It checks what the file contains, without installing anything. A file it
   cannot use stops here, with the reason (see
   [Files that cannot be installed](#files-that-cannot-be-installed)).
3. If the app is already installed, it says so and asks what to do (see
   [Already installed](#already-installed)).
4. If Bazaar (Flathub) has the same app, the window says "{app} is in
   Bazaar, the app store (Flathub)":
   - Recommended: **Use Flathub**. It updates by itself and is made for this
     kind of system.
   - Or **Use the file**: installs your download. It never updates.
5. The window says where it goes, and recommends one:
   - When the whole app works in a box: **Set up and install** (or **Install**
     once the box is set up) puts it in a separate box. Your system is not
     changed, and Remove Apps takes it out cleanly.
   - When parts of an .rpm app would not work in a box (a background service,
     for example), the window lists them and recommends **Add to the system**:
     everything works, with your password and a restart. **Set up and install**
     is still offered: easier to remove, but those parts will not work.
   - A .deb cannot go on the system, so if parts would not work in a box, the
     window says so, suggests looking for an .rpm file or the app in Bazaar,
     and offers **Set up and install** without those parts.
   - The first time, the window also says how much the box downloads and how
     much disk space it uses.
6. The last window says where to find it ("Find it in Show Apps.") and how it
   gets updates (see [Updates](#updates)). Its own icon shows in Show Apps
   straight away, and in the dock while it runs. Apps installed before the dock
   icon was fixed get it at your next login.

.rpm files go in the Fedora box and .deb files in the Ubuntu 24.04 box. Each box
is a Distrobox container, kept separate from any boxes of your own. System
Update keeps the boxes up to date, along with everything else.

Bazaar's app is matched by the app ID the package itself carries (Brave's
file names `com.brave.Browser`), or by name. A looser name match ("Brave Web
Browser" and "Brave") is only used for apps Flathub has verified as coming from
their maker, so a look-alike is never offered.

### Apps that go on the system

**Adding to the system** puts the app on top of the image. Because the image
only changes at a restart, the app is there after your next restart. Each
update then rebuilds the system with your added apps on top, so updates take a
little longer. Remove Apps takes them off again.

Some apps cannot work in a box at all. Then the window says "{app} has to go on
the system. It has: … These can't work in a box.", with **Add to the system**
(everything works; needs your password and a restart; remove it any time with
Remove Apps). A .deb cannot go on the system,
so it is refused, with the reason.

| The package has | What happens |
|-----------------|--------------|
| An app, command-line tools, a browser, most closed-source apps | Installed in the box |
| A device rule (udev) that only sets device permissions | The app goes in the box and the rule goes on the system, with your password. A package that is only a rule (Fedora's `solaar-udev`, for example) shows "{app} only lets your account use a device", with **Add it** |
| A device rule that runs a program | Not added. The app still goes in the box, and the window says the rule will not work |
| An optional background service, alongside an app | For an .rpm, **Add to the system** is recommended, so the service works; the box is still offered without it. A .deb goes in the box without it |
| A background service the app needs: one its install switches on itself (Docker Desktop's, for example) | Has to go on the system, like a driver (next line) |
| An app that runs as administrator (root), such as Timeshift: its own polkit rule or Show Apps entry starts it as root | Not installed. One window, with only an OK button, says "{app} can't be installed. It needs full control of the system to run" |
| A driver, including driver source it builds when installed (VirtualBox), firmware, printer or scanner driver, login or network plugin, or a background service with no app | Has to go on the system. An .rpm can be added to the system. A .deb is refused, with the reason |

Device rules and other packages the install pulls in are checked too: if
Fedora's `solaar` brings in `solaar-udev`, its rule is offered for the system as
well.

### Install from Fedora

Before an .rpm goes on the system, it checks whether Fedora's own repositories
have it, by the package's name. If they do, the window says "Fedora has {app}":

- Recommended: **Install from Fedora**. System Update keeps it up to date.
- Or **Use the file**: installs your download. It never updates.

If your file is newer than Fedora's, the window also says "Your file is newer
than Fedora's. Use the file only if you need that newer version now." Only Fedora's own repositories are checked, not
third-party ones.

### Restarting after adding to the system

Anything added to the system takes effect after a restart. The window says
"{app} is installed. Restart to start using it." It recommends **Restart now**,
or **Later** if you are in the middle of something. At the next login a message says "{app} is ready. Find it in Show
Apps.", or that it did not get installed (for example when the computer started
an older version of the system). A printer driver opens Printers instead (see
[Printer drivers](#printer-drivers)).

### Updates

The last window of every install ends with an Updates line:

| Updates line | Means |
|--------------|-------|
| Updates: automatic, with System Update. | It came from Fedora, or the package added its maker's download source to the box (Google Chrome and VS Code do) |
| Updates: automatic. | It came from Bazaar (Flathub) |
| Updates: none, because it came from a file. To update, install a newer file. (Some apps, like Discord, update themselves.) | An app in a box, installed from a plain file |
| Updates: none, because it came from a file. To update, install a newer file. | An app added to the system from a file, which the system keeps at that file's version |

### Already installed

Before anything else, it checks whether the app is already there, and asks
instead of installing again:

| Already there | The window says | Buttons |
|---------------|-----------------|---------|
| Part of EasySpeakOS | "{app} is already part of EasySpeakOS. Nothing to install." | OK |
| On the system, from Fedora | "{app} is already installed from Fedora and stays up to date. You don't need this file." | OK |
| On the system, same or older file | "{app} is already installed. This file is the same version." (or "older than the one installed") | OK |
| On the system, newer file | "Update {app} to the newer version in this file? Needs your password and a restart." | **Update**, Cancel |
| In its box, same version | "{app} is already installed." Recommended: **Open it**. **Reinstall** is only needed if it isn't working | **Open it**, **Reinstall**, Cancel |
| In its box, newer file | "Update {app} to the newer version in this file?" | **Update**, Cancel |
| In its box, older file | "This file is an older version of {app} than the one you have." Only for when the newer one has a problem | **Install the older version**, Cancel |
| From Bazaar (Flathub) | "{app} is already installed from Bazaar, the app store." Recommended: **Open it**. A second copy never updates | **Open it**, **Install the file too**, Cancel |
| In the other box | "{app} is already installed from a .deb file." (or ".rpm") Recommended: **Open it**. A second copy never updates | **Open it**, **Install it here too**, Cancel |

### Files that cannot be installed

Each of these windows has one OK button, and nothing is installed:

- A damaged or unfinished download: "This file can't be installed. It may be
  damaged or not fully downloaded."
- A 32-bit file: "This is the 32-bit version of {app}, for older computers.
  Download the 64-bit version instead."
- A file for a different kind of computer (ARM, for example): "This {app} file
  is for a different kind of computer."
- An app that runs as administrator (root), such as Timeshift: "{app} can't be
  installed. It needs full control of the system to run."
- A .deb that has to go on the system: "{app} can't be installed from this
  file", with what it has and where to look instead.

### Download sources

Some files contain no app, only a place to download apps from (Fedora's RPM
Fusion setup file, Microsoft's `packages-microsoft-prod.deb`). The window says
"{file} has no app in it. It adds a place to download apps from", names it, and
offers **Add it** (**Set up and add it** the first time). Then "Which app do you
want? Start typing its name." lists the apps it offers, numbered. The app you
pick is installed like any file, and updates automatically from that source.
The source shows in Remove Apps as "… (download source)".

### Printer drivers

Most printers need no driver: they show up by themselves in Settings, under
Printers. So a printer driver first says "{app} is a printer driver. Most
printers work without one.":

- Recommended: **Open Printers**, and add your printer there first.
- Or **Install the driver** (.rpm) or **About this driver** (.deb): only if your
  printer does not work without it.

If the printer still needs the driver:

- **.rpm:** it is added to the system (your password, then a restart), from
  Fedora when Fedora has the same driver, so it gets updates. At the next login
  a window says the driver is ready, with **Open Printers** to add the printer,
  or says plainly if the driver did not get installed.
- **.deb:** the system cannot take it. The window names the maker when the
  package says who it is (HP, Brother, Canon, Epson and others), and explains how
  to get the .rpm version from the maker's support site.

### Start Apps at Login

**Start Apps at Login** (in Show Apps, or "start apps at login") asks "Which app
should start, or stop starting, when you log in?" and lists the apps from .rpm
and .deb files, with whether each starts at login. Choose one to switch it. Some
apps have their own "open at login" setting (Discord does). In a box, that
setting would point at a path that only exists inside the box, so at login
nothing would happen. At login, such an entry is pointed at the box and the app
is started. Apps from Bazaar have this setting inside the app.

### Removing apps

**Remove Apps** (in Show Apps, or "remove an app") lists everything installed
with Install Package File, numbered, with how much space each box uses. Pick one
and press **Remove**. It removes the app from its box, its Show Apps entry, any
device rule it added, or the package added to the system (then it offers a
restart). Remove Apps quits a running app before removing it. If an app is
already gone from its box (for example after the box was set up again), Remove
Apps just takes it off the list.

When you remove the last app from a box, the window says "{app} is removed, and
the Fedora box is now empty":

- Recommended: **Delete the box**. It frees its disk space (the window says how
  much), and comes back by itself the next time you install an app of that kind.
  Anything added to the box another way is deleted too. Your files are not
  touched.
- Or **Keep it**: saves setup time if you will install another app of that kind
  soon.

What was installed is recorded in `~/.local/share/easyspeak-os/apps.json`.

### Repairing a box

If a box stops working, installing into it says "The Fedora box isn't working."
and recommends **Repair the box**: it rebuilds the box, puts back the apps that were
installed into it with Install Package File (from the saved copies of their
files), then installs the new app. **Repair App Boxes** in Show Apps (or "repair
app boxes") does the same at any time, with **Repair**. When System Update
cannot update the boxes, it offers to check them and repairs only a box that is
broken; if the broken one is a box made outside Install Package File, it says
Repair cannot fix it. Repair does not touch your files, and anything added to a
box another way is not put back.

### Disk space

The first-time window says how much disk space the box uses. Before a box is set
up or an app installed, it checks the free space. If it is too low, the window
says "Not enough free space", how much is needed and how much is free. It
recommends **Cancel**, freeing space (empty the Trash or remove apps you do not
use) and trying again; **Try anyway** is still there, and if space runs out, it
stops safely and nothing is lost. Remove Apps shows how much space each box uses.

### One at a time

If another install or removal is running, the window names it ("Installing
Discord in the Ubuntu box"), waits for it to finish, then goes on. It has a
Cancel button.

### Progress and notifications

The progress window shows plain steps (downloading, creating, getting it ready,
installing) rather than the tools' own output, says how long a long step has
been going once a minute, and has a **Cancel** button while a box is being set
up. Cancelling, or a failed setup, leaves no half-made box. Setting up a box and
adding to the system also send a notification when they start, so you know it
is working even if the progress window opens behind another window.

Each box also gets two small desktop parts that apps from these files expect and
a fresh box lacks: zenity, for progress windows (Discord's first start downloads
the rest of Discord and shows its progress with it; without zenity there is no
window at all), and notify-send, for notifications. They are added while the box
is set up. A box made before this was added gets them once, quietly, at the next
login. Opening links is left to Distrobox, which already sends it to your desktop.

### Starting and stopping box apps

An app's Show Apps entry starts it through `easyspeak-os-box-run`, not straight
through Distrobox:

- The app's messages go to `~/.cache/easyspeak-os/logs/<app>.log`, not back
  through its link to the desktop. If that link goes away (for example when a
  task manager's Force Stop ends it), the app keeps working instead of crashing
  with "write EPIPE" error windows, as Discord did.
- **The dock shows the app's own icon while it runs**, not a generic one. A box
  app's Show Apps entry has the box's name in front of the app's own
  (`easyspeak-fedora-vivaldi-stable`), so GNOME can't tell from the name that
  the open window belongs to it. The entry says which window is the app's
  (`StartupWMClass`, set to the app's own name, `vivaldi-stable`).
- **Two Quit items.** Right-click a box app in the dock or Show Apps and you see
  two of them:
  - **Quit <app name>**, for example **Quit Discord**, is EasySpeakOS's. It
    stops the app inside the box. Use this one to really close a box app.
  - **Quit** on its own (the last item) is GNOME's. It only closes the app's
    windows. Many apps keep running in the background after it.
- **Quit <app name> takes a few seconds, and that is expected.** The app is asked
  to quit, and is forced to after 10 seconds if it has not. A notification says
  "Quitting <app name>". Meanwhile GNOME may show its "not responding" window
  with **Force Quit** and **Wait**. Nothing is wrong: the app closes on its own
  and the window goes away with it. You do not need to press anything.

Show Apps entries made before this are switched over once, at the next login.

### When something goes wrong

The window says "{task} did not work." and why, in plain words, for the usual
reasons: no internet connection, a full disk, a package made for a different
Fedora or Ubuntu version (naming what it needs), a file that would replace part
of the system, or the password not given. Otherwise it shows the last lines of
the log. The full log is in `~/.cache/easyspeak-os/packages/last.log`. To see
what a package needs without installing it, run
`easyspeak-os-packages check FILE`.

## System Tools

**System Tools** (in Show Apps, or say "system tools") is a short list of system
jobs, each in plain windows that say what will happen and what's recommended.
They're the useful ones from Universal Blue's `ujust` commands, without a
terminal. Say a line's number to pick a tool, then say its buttons. The list is
wide enough to read every line in full, without scrolling.

| Tool | What it does |
|------|--------------|
| Update firmware | Checks for updates to the software built into the computer's own parts, like the BIOS, and installs them. Keep the computer plugged in. Some updates finish during the next restart |
| Unlock disk automatically | If the disk was encrypted at install, the computer's security chip (TPM) can unlock it at startup, so the disk password isn't typed every time. See below |
| Free up disk space | Removes unused app parts, old system update files and unused container images, and says how much space it freed. Your files and apps aren't touched |
| Restart into BIOS settings | Restarts the computer straight into its BIOS settings screen. The BIOS settings are used with the keyboard |
| Automatic updates | Turns the daily automatic updates on or off. Keeping them on is recommended, because updates fix security problems |
| Undo the last update | If something stopped working after an update, goes back to the version from before it. See below |
| Save problem details | Saves the computer's recent error messages to one file, for you to email to your helper. See below |
| Setup checklist | The microphone, media codecs, disk unlock and getting apps, one at a time. It opens by itself at a new user's first login. See [First login](#first-login) |

**Which jobs ask for the administrator password.** None of these do, for an
administrator sitting at the computer, because no program could do harm with
them: turning automatic updates on, Unlock disk automatically (it checks the
disk password instead), and Free up disk space. They go through one small
helper that can only do those, and one narrow polkit rule, the same way
GNOME lets you connect to Wi-Fi or open a USB stick without a password.
These keep the password, because a bad program could use them to weaken the
computer: turning automatic updates off, Undo the last update (it puts an older
version back), Update firmware, and adding apps to the system.

**Unlock disk automatically.** When the disk is encrypted, the computer asks for
the disk password at every start, before the login password. Turning this on
lets the computer's security chip unlock the disk instead:

- It needs the disk to have been encrypted when the system was installed, and a
  security chip (TPM 2.0). Intel computers from 11th generation on, and Framework
  laptops with an up-to-date BIOS, have one. Secure Boot should be on; if it's
  off, the window says so and recommends turning it on first.
- Turning it on asks for the disk password one last time, then a restart. No
  administrator password: the disk password already proves it's the owner.
  After 5 wrong disk passwords within an hour it stops trying until the hour is
  up, so it can't be used to guess the disk password.
- If the disk is taken out of the computer, or the computer's startup settings
  change (a BIOS or firmware update, Secure Boot switched off), the chip refuses
  and the disk password is asked for as before. Nobody is locked out. After such
  a change, turn it on again in System Tools.
- Turning it off is in the same place, and the disk password is asked for at
  every start again.
- Whether it's on is checked on the disk itself: at every start, and right
  after turning it on or off. So System Tools and the setup checklist never
  think it's on when the disk says otherwise.

**Undo the last update.** The version from before the last update is kept on
the computer. This tool says the dates of both and, on **Undo the update**, sets
the earlier one to start at the next restart. It's what `rpm-ostree rollback`
does. Your files and apps aren't touched.

- If an update is downloaded but waiting for a restart, the version in use isn't
  the new one yet. The tool offers **Don't use it**, which removes the waiting
  update (`rpm-ostree cleanup -p`), or **Keep it**.
- After an undo, the tool offers **Use the newer version** instead, to go
  forward again (also `rpm-ostree rollback`).
- The next automatic update puts the newest version back. If the problem comes
  back, turn off Automatic updates and tell your helper.
- It may ask for the administrator password.

**Save problem details.** When something goes wrong, the reason is usually in
the computer's own record of errors (the system journal), which is normally
read with terminal commands. This tool collects the useful part into one text
file, `problem-details-<date>.txt`, in your Documents folder. You email it to
your helper, who can see what went wrong without being at the computer. Nothing
is sent anywhere by itself. The file holds the same things as `ujust
logs-this-boot`, `ujust logs-last-boot` and `ujust device-info`, kept to the
warnings and errors so it stays small:

- the system version, and the computer's hardware and setup
- warnings and errors since the computer started, and errors from the start
  before that
- the last 3 days of the automatic updates
- the Flatpak apps and the app boxes
- the logs of Install Package File and System Tools

Box apps' own logs are left out, since they hold whatever the app printed, such
as web addresses and file names. The window says so.

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
| `build_files/zz-easyspeak-os-desktop.gschema.override` | No hot corner, and the battery percentage in the top bar |
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
[setup checklist](#first-login) asks whether you want them, with three large buttons: **Web video only**, **Everything** and
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
[From the live USB](#from-the-live-usb)). A computer that was installed before
keeps the name it got then (for example "Fedora", "Generic" or "bluefin"). That
name is stored on your machine, so an image update cannot change it. To rename
it:

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

**The files in this repository** are under the
[GNU General Public License, version 3 or later](LICENSE) (GPL-3.0-or-later),
with two exceptions:

- **Files that started from Universal Blue's
  [image template](https://github.com/ublue-os/image-template)** stay under its
  [Apache License 2.0](LICENSES/Apache-2.0.txt): the `Justfile`, the
  `Containerfile`, the build workflows, `disk_config/` and a few small settings
  files. The live-ISO build in `iso/`, based on the Bazzite example in
  Universal Blue's [titanoboa](https://github.com/ublue-os/titanoboa), is also
  Apache 2.0, except the EasySpeakOS installer in it (`iso/src/easyspeak-os-installer/`,
  `iso/src/easyspeak-os-install-engine` and their launcher and polkit action),
  which is this project's own and GPL-3.0-or-later.
  Apache 2.0 files can be part of a GPL-3.0 project.
- **The Ready Dot extension** runs inside GNOME Shell, which is
  GPL-2.0-or-later, so it is
  [GPL-2.0-or-later](LICENSES/GPL-2.0-or-later.txt) too.

[`REUSE.toml`](REUSE.toml) lists which license covers each file, in the
[REUSE](https://reuse.software/) format, and the license texts are in
[`LICENSES/`](LICENSES).

**The image itself is not under those licenses.** EasySpeakOS is built on
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

Fedora® is a registered trademark of Red Hat, Inc., or its subsidiaries in the United States and other countries. EasySpeakOS is not provided or supported by the Fedora Project, and is not affiliated with or endorsed by the Fedora Project or Red Hat.
