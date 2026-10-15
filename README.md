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
[![Signed](https://img.shields.io/badge/images-signed%20with%20cosign-lightgrey.svg)](#checking-that-updates-are-real)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

## Contents

<!-- contents -->
- [Status](#status)
- [Who it's for](#who-its-for)
- [How this system works](#how-this-system-works)
- [What's in it](#whats-in-it)
- [System requirements](#system-requirements)
- [Install](#install)
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

EasySpeak-OS is for people who can see the screen and speak clearly in English,
but find a keyboard and mouse hard to use, for example because of RSI,
arthritis, a tremor or limited hand movement.

Most everyday things work by voice. Some still need typing, mainly passwords.
[What works by voice](#what-works-by-voice) lists both.

Someone comfortable with a terminal has to set it up: the [install](#install)
and the [first login](#first-login) steps are typed.

## How this system works

EasySpeak-OS is an **image-based** system. The system itself, meaning
everything except your own files and settings, arrives as one finished, tested
piece called an image, and apps can't change it. That keeps it from breaking.

- **Updates** download a whole new image in the background. It's used from your
  next restart.
- **The previous version stays on disk.** If an update causes a problem, you can
  go back to it (see [Updating and rolling back](#updating-and-rolling-back)).
- **Apps** come from the Software app, or go into a box. Only when they have to
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
| Codecs | Not included. Fedora leaves out patent-encumbered video codecs and so does this image. A window at first login offers them, with no password, and **Install Media Codecs** in Show Apps offers them later. See [Media codecs](#media-codecs) |
| Apps from .rpm and .deb files | **Install Package File** puts them in a box (Distrobox) and adds them to Show Apps; **Remove Apps** takes them out. See [Apps from .rpm and .deb files](#apps-from-rpm-and-deb-files) |
| Flathub | Added as a Flatpak remote on first boot, so Flatpak apps and runtimes such as `ffmpeg-full` can be installed straight away. The Flathub entry that comes with Fedora, which stays off until you opt in, is removed |
| [EasySpeak](https://github.com/ctsdownloads/easyspeak) | The newest release and its Parakeet and English speech packs, installed when the image is built |
| Ready Dot | A GNOME Shell extension: a status dot, "did you mean" suggestions, and an on-screen command list ([details](#using-it)) |
| Command cheat sheet | An offline page of EasySpeak's commands, opened from Show Apps |
| System Tools | Update firmware, unlock the disk automatically, free up disk space, restart into the BIOS settings, and turn automatic updates on or off, in plain windows. See [System Tools](#system-tools) |

## System requirements

- **Minimum:** 8 GB RAM. EasySpeak's speech model (Parakeet) alone uses about
  1.3 GB while it runs, on top of the desktop.
- **Recommended:** 16 GB RAM, especially if you use apps from .rpm or .deb files,
  since each app box adds to memory use.

## Install

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
each step. If the automatic update is already running
when you open it, it says so and follows that update to the end instead of
failing (only one update can run at a time). Or run:

```
sudo uupd
```

`uupd` updates the system with `bootc`, and falls back to `rpm-ostree` when
needed, for example when packages such as the full codecs are added on top of
the system. `rpm-ostree upgrade` also still works.

To go back to the version you had before the last update (it's kept on disk),
run `rpm-ostree rollback` and restart. You can also pick it in the boot menu
when the computer starts.

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
the dock, or press the Super key twice. The EasySpeak-OS tools are there.

**The Software app** is GNOME's app store. Its apps come from **Flathub** as
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
  **System Update**, the same window as in Show Apps. This command comes from EasySpeak-OS,
  as a plugin added to EasySpeak's plugin folder, and works in English only.
- **Install and remove apps by voice.** Say "install a package" to open
  **Install Package File**, "remove an app" to open **Remove Apps**, "repair
  app boxes" to open **Repair App Boxes**, or "start apps at login" to open
  **Start Apps at Login**. These also come from EasySpeak-OS as a plugin, in
  English only.
- **Answer EasySpeak-OS windows by voice.** While an EasySpeak-OS window is open
  (Install Package File, Remove Apps, Repair App Boxes, System Update, Install
  Media Codecs), say a button's name to press it: "set up and install", "open
  it", "restart now", "cancel". In a list, say "number two" (each line shows its
  number) or the name on the line. Say "read it" to hear the window and the buttons you can say. The window
  is never read out by itself: the open microphone would hear it and could press
  one of its buttons. When no such window is open, these words do nothing, so
  they never get in the way of other commands. English only.
- **The EasySpeak-OS commands are in the help.** "help", the cheat sheet and the
  "did you mean" card include them, in two sections of their own: **EasySpeak-OS**
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
| Open an app | Yes, from a fixed list | "open firefox", "open files", "open settings", "open software", "open calculator", "open editor" and the others in EasySpeak's list. Apps you install yourself are not on it |
| Browse the web | Yes, in qutebrowser | "browser", then link numbers, "search …", "go to …" and tabs. In Firefox, only with grid mode |
| Click anything on screen | Yes, but slowly | "grid", numbers to zoom in, then "click" |
| Type text | Yes | "dictation", into the field that has focus. Click the field first with grid mode or a link number |
| Volume, brightness, music, folders | Yes | "volume up", "pause", "open downloads" and so on |
| Install from an .rpm or .deb file in Downloads | Yes | "install a package", "number one" for the file, then say the buttons. If the Software app has the same app, it offers that instead |
| Install from the Software app (Flathub) | Yes, but slowly | "open software", then grid mode to click the search box, dictation for the name, and grid mode to click Install |
| Add an app to the system | Partly | The same windows, but the administrator password is typed |
| Remove an app | Yes, if Install Package File installed it | "remove an app". Apps from the Software app are removed there, with grid mode |
| Repair app boxes, or choose apps that start at login | Yes | "repair app boxes", "start apps at login" |
| Update everything (system, Flatpaks, app boxes) | Yes | Automatic, or "update system" |
| System Tools: firmware, disk unlock, free space, BIOS settings, automatic updates | Yes | "system tools", "number one" and so on for the tool, then say the buttons. Some jobs ask for a password, which is typed |
| Media codecs | Partly | Answer the window by voice. Outside first-time setup, the administrator password is typed |

**Still typed:**

- the password to log in and to unlock the screen
- the administrator password, when adding an app to the system, installing
  codecs later, or changing a System Tools setting
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
4. If the Software app (Flathub) has the same app, the window says "{app} is in
   the Software app (Flathub)":
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
     window says so, suggests looking for an .rpm file or the app in the Software
     app, and offers **Set up and install** without those parts.
   - The first time, the window also says how much the box downloads and how
     much disk space it uses.
6. The last window says where to find it ("Find it in Show Apps.") and how it
   gets updates (see [Updates](#updates)). Its own icon shows in Show Apps
   straight away.

.rpm files go in the Fedora box and .deb files in the Ubuntu 24.04 box. Each box
is a Distrobox container, kept separate from any boxes of your own. System
Update keeps the boxes up to date, along with everything else.

The Software app is matched by the app ID the package itself carries (Brave's
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
| Updates: automatic. | It came from the Software app (Flathub) |
| Updates: none, because it came from a file. To update, install a newer file. (Some apps, like Discord, update themselves.) | An app in a box, installed from a plain file |
| Updates: none, because it came from a file. To update, install a newer file. | An app added to the system from a file, which the system keeps at that file's version |

### Already installed

Before anything else, it checks whether the app is already there, and asks
instead of installing again:

| Already there | The window says | Buttons |
|---------------|-----------------|---------|
| Part of EasySpeak-OS | "{app} is already part of EasySpeak-OS. Nothing to install." | OK |
| On the system, from Fedora | "{app} is already installed from Fedora and stays up to date. You don't need this file." | OK |
| On the system, same or older file | "{app} is already installed. This file is the same version." (or "older than the one installed") | OK |
| On the system, newer file | "Update {app} to the newer version in this file? Needs your password and a restart." | **Update**, Cancel |
| In its box, same version | "{app} is already installed." Recommended: **Open it**. **Reinstall** is only needed if it isn't working | **Open it**, **Reinstall**, Cancel |
| In its box, newer file | "Update {app} to the newer version in this file?" | **Update**, Cancel |
| In its box, older file | "This file is an older version of {app} than the one you have." Only for when the newer one has a problem | **Install the older version**, Cancel |
| From the Software app (Flathub) | "{app} is already installed from the Software app." Recommended: **Open it**. A second copy never updates | **Open it**, **Install the file too**, Cancel |
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
is started. Apps from the Software app have this setting inside the app.

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
- **Two Quit items.** Right-click a box app in the dock or Show Apps and you see
  two of them:
  - **Quit <app name>**, for example **Quit Discord**, is EasySpeak-OS's. It
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
terminal. Say a line's number to pick a tool, then say its buttons.

| Tool | What it does |
|------|--------------|
| Update firmware | Checks for updates to the software built into the computer's own parts, like the BIOS, and installs them. Keep the computer plugged in. Some updates finish during the next restart |
| Unlock disk automatically | If the disk was encrypted at install, the computer's security chip (TPM) can unlock it at startup, so the disk password isn't typed every time. See below |
| Free up disk space | Removes unused app parts, old system update files and unused container images, and says how much space it freed. Your files and apps aren't touched |
| Restart into BIOS settings | Restarts the computer straight into its BIOS settings screen. The BIOS settings are used with the keyboard |
| Automatic updates | Turns the daily automatic updates on or off. Keeping them on is recommended, because updates fix security problems |

**Unlock disk automatically.** When the disk is encrypted, the computer asks for
the disk password at every start, before the login password. Turning this on
lets the computer's security chip unlock the disk instead:

- It needs the disk to have been encrypted when the system was installed, and a
  security chip (TPM 2.0). Intel computers from 11th generation on, and Framework
  laptops with an up-to-date BIOS, have one. Secure Boot should be on; if it's
  off, the window says so and recommends turning it on first.
- Turning it on asks for the disk password one last time, and the administrator
  password, then a restart.
- If the disk is taken out of the computer, or the computer's startup settings
  change (a BIOS or firmware update, Secure Boot switched off), the chip refuses
  and the disk password is asked for as before. Nobody is locked out. After such
  a change, turn it on again in System Tools.
- Turning it off is in the same place, and the disk password is asked for at
  every start again.

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
| `build_files/easyspeak-os-update`, `easyspeak-os-update.desktop` | **System Update** in Show Apps, which runs `uupd` and shows each step |
| `build_files/easyspeak_os_update.py`, `easyspeak_os_apps.py`, `check-easyspeak-plugin.py` | The "update system", "install a package", "remove an app", "repair app boxes" and "start apps at login" voice commands, added to EasySpeak's plugin folder, and the build test that they load |
| `build_files/easyspeak-os-packages`, `easyspeak-os-install-package.desktop`, `easyspeak-os-remove-apps.desktop`, `easyspeak-os-repair-boxes.desktop`, `easyspeak-os-login-apps.desktop`, `gnome-mimeapps.list` | **Install Package File**, **Remove Apps**, **Repair App Boxes** and **Start Apps at Login**, and the setting that opens .rpm and .deb files in them |
| `build_files/easyspeak-os-packages-after-restart.desktop` | Runs once at login after something was added to the system, to say whether it is ready (and, for a printer driver, to add the printer) |
| `build_files/easyspeak-os-dialog`, `easyspeak_os_dialogs.py` | zenity plus voice: the EasySpeak-OS windows go through it, and the plugin lets EasySpeak press their buttons, pick list lines and read them out |
| `build_files/os-commands.py` | Reads the EasySpeak-OS voice commands from the plugins for the help overlay, the cheat sheet and "did you mean" |
| `build_files/easyspeak-os-box-run` | Starts box apps for their Show Apps entries with their messages in a log file, and stops them (the Quit action) |
| `build_files/easyspeak-os-hwrules`, `dev.easyspeak.os.hwrules.policy` | The helper that adds or removes an app's hardware rules on the system, and its polkit policy (password every time) |
| `build_files/check-packages.py` | The build test that Install Package File reads real packages correctly |
| `build_files/check-docs.py` | The build test that the README's table of contents and the help keep up with the software |
| `build_files/easyspeak-os-tools`, `easyspeak-os-tools.desktop`, `easyspeak_os_tools.py` | **System Tools** in Show Apps, and the "system tools" voice command |
| `build_files/easyspeak-os-tools-admin`, `dev.easyspeak.os.tools.policy` | The helper that turns automatic updates and automatic disk unlock on or off, and its polkit policy (administrator password) |
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
- The rebrand and boot-image steps fail the build if anything unexpected would be removed, if the logo or release packages from Fedora are still installed, or if the new boot image lacks what is needed to unlock a disk, including with the security chip (TPM).
- GNOME Software handles Flatpak apps and firmware only. The build removes its rpm-ostree and dnf plugins, so `uupd` is the only OS updater, and fails if either is still there.
- The build fails if Fedora's default-service files are missing, if Tailscale, the updater or the Homebrew setup would not be switched on, if GNOME Software's OS-update plugin is still installed (so there is only one updater), if tuned is not Bluefin's version, if the RPM Fusion signing key is missing, or if RPM Fusion's codecs would not install on the image (a test run of the Everything choice, nothing is installed).
- The build fails if an EasySpeak-OS voice command is missing from the "help" list, or if EasySpeak would not load the plugins the way it loads its own (the dialogs plugin is also tried against a pretend open window and a numbered list).
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

The first time you log in after this image first boots, a window asks whether
you want them, with three large buttons: **Web video only**, **Everything** and
**Not now**. You can open the same window again at any time from **Install
Media Codecs** in Show Apps, or type the commands (`codecs` is the short
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
  from Fedora's own `distribution-gpg-keys` package. These packages are added
  on top of the system, so on a machine that has them, system updates take a
  little longer.

### Passwords

During the first-time setup window, installing needs no password. The window
lasts at most 24 hours after the image first boots and closes as soon as you
answer. It works through one narrow exception in the system's permission check
(polkit). It works only for the administrator account, only for someone sitting
at the machine, and only with the words `web`, `full` or `skip`, and it installs
a fixed package list from the pinned repository. It cannot run anything else. Every action is written to the system
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
