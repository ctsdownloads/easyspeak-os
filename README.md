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
[![Status](https://img.shields.io/badge/status-alpha-orange.svg)](#status)
[![Base](https://img.shields.io/badge/base-Fedora%20Silverblue%2044-1f6feb.svg)](https://fedoraproject.org/atomic-desktops/silverblue/)
[![Desktop](https://img.shields.io/badge/desktop-GNOME%20%7C%20Wayland-green.svg)](https://www.gnome.org/)
[![Signed](https://img.shields.io/badge/images-signed%20with%20cosign-lightgrey.svg)](docs/install.md#checking-that-updates-are-real)
[![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue.svg)](LICENSE)


## Contents

<!-- contents -->
- [Status](#status)
- [Who it's for](#who-its-for)
- [How this system works](#how-this-system-works)
- [What's in it](#whats-in-it)
- [System requirements](#system-requirements)
- [Documentation](#documentation)
- [Known limitations](#known-limitations)
- [Source code](#source-code)
- [Credits](#credits)
- [License](#license)
- [Trademarks](#trademarks)
<!-- /contents -->

## Status

> ⚠️ **Alpha.** This is a personal workstation image shared as-is.
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
[What works by voice](docs/voice.md#what-works-by-voice) lists both.

Someone comfortable with a terminal has to set it up: the [install](docs/install.md#install)
and the [first login](docs/install.md#first-login) steps are typed.

## How this system works

EasySpeakOS is an **image-based** system. The system itself, meaning
everything except your own files and settings, arrives as one finished, tested
piece called an image, and apps can't change it. That keeps it from breaking.

- **Updates** download a whole new image in the background. It's used from your
  next restart.
- **The previous version stays on disk.** If an update causes a problem, you can
  go back to it (see [Updating and rolling back](docs/install.md#updating-and-rolling-back)).
- **Apps** come from Bazaar, the app store, or go into a box. Only when they have to
  are they added to the system.

## What's in it

| Part | Details |
|------|---------|
| Base | [Fedora Silverblue 44](https://fedoraproject.org/atomic-desktops/silverblue/) (`quay.io/fedora-ostree-desktops/silverblue:44`), with the logos and release packages from Fedora replaced by the generic ones |
| Packages | firefox, qutebrowser, v4l-utils, wtype, ydotool, xdg-terminal-exec, and the Fedora packages Bluefin adds that are listed in [`build_files/bluefin-packages.txt`](build_files/bluefin-packages.txt) |
| Updates | Automatic, with Bluefin's updater `uupd`: the system, Flatpaks, app boxes and Homebrew. See [Updating and rolling back](docs/install.md#updating-and-rolling-back) |
| Homebrew | Set up on first boot, as on Bluefin, for command-line tools (`brew`). Terminal only, for people who use one |
| ujust | Bluefin's command runner, for example `ujust update`. Terminal only, for people who use one |
| Services on by default | Fedora's own defaults (power management, DNS, SSD trim and others), plus Tailscale (a private network between your own devices; it does nothing until you sign in to it) and Podman's automatic container updates (only for containers you set up to update that way), as on Bluefin |
| Power management | tuned 2.27.0, the version Bluefin ships. See [Known limitations](#known-limitations) |
| Codecs | Not included. Fedora leaves out patent-encumbered video codecs and so does this image. The [setup checklist](docs/install.md#first-login) at first login offers them, and **Install Media Codecs** in Show Apps offers them any time, with no password on an administrator account. See [Media codecs](docs/building.md#media-codecs) |
| Apps from .rpm and .deb files | **Install Package File** puts them in a box (Distrobox) and adds them to Show Apps; **Remove Apps** takes them out. See [Apps from .rpm and .deb files](docs/apps.md#apps-from-rpm-and-deb-files) |
| Flathub | Added as a Flatpak remote on first boot, so Flatpak apps and runtimes such as `ffmpeg-full` can be installed straight away. The Flathub entry that comes with Fedora, which stays off until you opt in, is removed |
| [EasySpeak](https://github.com/ctsdownloads/easyspeak) | The newest release and its Parakeet and English speech packs, installed when the image is built |
| Ready Dot | A GNOME Shell extension: a status dot, "did you mean" suggestions, and an on-screen command list ([details](docs/voice.md#using-it)) |
| Command cheat sheet | An offline page of EasySpeak's commands, opened from Show Apps |
| System Tools | Update firmware, unlock the disk automatically, free up disk space, restart into the BIOS settings, turn automatic updates on or off, undo the last update, save problem details for your helper, turn EasySpeak off or on, and the setup checklist, in plain windows. See [System Tools](docs/system-tools.md#system-tools) |
| Window buttons | Every window has minimize, maximize and close buttons (GNOME's own default shows only close) |
| Desktop defaults | EasySpeak's on/off toggle is in the Quick Settings menu (top right) from the start. No hot corner (the pointer in the top-left corner doesn't open the Activities overview). The battery percentage shows in the top bar. Each can be changed back: the toggle in EasySpeak's Settings, the other two in Settings |
| Dock | Firefox, Calendar, Files, Bazaar (the app store) and Text Editor. GNOME's own list, with Bazaar in place of GNOME Software and without the Calculator, which is in Show Apps. Change it by dragging apps on or off |
| Logo Menu | The EasySpeakOS logo at the top left opens a menu: About My System, Activities, App Grid, Software Center (Bazaar), System Monitor (Resources), Terminal (Ghostty) and Extensions. A middle click on the logo opens Activities. The [Logo Menu](https://github.com/Aryan20/Logomenu) extension, on for every user; change it in Extensions |
| Terminal | [Ghostty](https://ghostty.org/), in place of Fedora's Ptyxis, which is removed. It is the terminal everywhere: EasySpeak's "open terminal", Logo Menu, Files' **Open in Ghostty**, and anything that opens the default terminal |
| System monitor | [Resources](https://apps.gnome.org/Resources/), installed from Flathub on the first start, is what the Logo Menu's System Monitor opens. gnome-system-monitor is kept too, in the app grid. The live USB, which has no Flatpaks yet, points the Logo Menu at gnome-system-monitor |
| Fingerprint | Turned on where the laptop has a supported reader: Fedora's atomic base ships the fingerprint software but leaves it off, so EasySpeakOS enables it (authselect with-fingerprint and the fprintd service). Enrol in Settings, Users; it then logs you in and authorises prompts without typing. A password is still set at install as the fallback |
| Microphone | A microphone starts at 50% volume, not 100%, which is often too loud for speech recognition. A volume you set is kept. Change it in Settings, Sound |
| Firefox | Opens Firefox's own home page, not Fedora's start page, with no Fedora tile |
| Default apps | Web: qutebrowser, Firefox. Writing: Text Editor, LibreOffice (Writer, Calc, Impress), Errands. Media: Lollypop, Shortwave, Podcasts, Celluloid. Viewing: Papers, Loupe. Files and system: Files, Ghostty, Settings, Bazaar (the app store), Pika Backup. Accessibility: Orca, plus GNOME's Hover Click, Zoom and on-screen keyboard. Utilities: Calculator, Clocks, Calendar, Contacts, Weather, Characters. Fedora's own packages, in the image ([`build_files/default-apps.txt`](build_files/default-apps.txt)); Errands, Shortwave, Podcasts and Pika Backup aren't packaged by Fedora, so they come from Flathub on the first start with internet ([`build_files/flathub-apps.txt`](build_files/flathub-apps.txt)). No email app: use your own |
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

## Documentation

The guides, split out of this page so each one stays readable:

- **[Install](docs/install.md)** - the live USB, installing from Silverblue or
  Bluefin, updating and rolling back, checking that updates are real, and the
  first login.
- **[Using it by voice](docs/voice.md)** - what EasySpeak does here and what
  works by voice.
- **[Apps from .rpm and .deb files](docs/apps.md)** - installing, removing,
  updating and repairing apps, printer drivers, disk space and what to do when
  something goes wrong.
- **[System Tools](docs/system-tools.md)** - firmware, disk unlock, freeing up
  space, BIOS settings, automatic updates and problem details.
- **[How it's built](docs/building.md)** - the build, media codecs, passwords
  and the boot menu name.

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
- **Ghostty** comes from the community package for Fedora that Ghostty's install
  page lists, built in <https://copr.fedorainfracloud.org/coprs/scottames/ghostty/>;
  Ghostty's source is at <https://github.com/ghostty-org/ghostty>.
- **Logo Menu** is at <https://github.com/Aryan20/Logomenu> (GPL-2.0), installed
  from <https://extensions.gnome.org/extension/4451/logo-menu/>.
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
