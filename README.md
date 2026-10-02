# EasySpeak-OS

[![Build](https://github.com/ctsdownloads/easyspeak-os/actions/workflows/build.yml/badge.svg)](https://github.com/ctsdownloads/easyspeak-os/actions/workflows/build.yml)
[![Status](https://img.shields.io/badge/status-pre--alpha-red.svg)](#status)
[![Base](https://img.shields.io/badge/base-Fedora%20Silverblue%2044-1f6feb.svg)](https://fedoraproject.org/atomic-desktops/silverblue/)
[![Desktop](https://img.shields.io/badge/desktop-GNOME%20%7C%20Wayland-green.svg)](https://www.gnome.org/)
[![Signed](https://img.shields.io/badge/images-signed%20with%20cosign-lightgrey.svg)](#verifying-the-signature)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

An image for a workstation, with [EasySpeak](https://easyspeak.dev/latest/)
voice control installed for accessibility. It is built on the official Fedora
Silverblue 44 image, with a set of packages carried over from
[Bluefin](https://projectbluefin.io/), the full ffmpeg codecs, EasySpeak, and a
small GNOME extension that shows what EasySpeak is doing. Fedora's logos and
release branding are replaced.

## Status

> ⚠️ **Pre-alpha.** This is a personal workstation image shared as-is.
> EasySpeak itself is alpha software, and this image installs new EasySpeak
> releases automatically, so something can break on any given day. There is no
> warranty and no support commitment. Roll back with `rpm-ostree rollback`.

It has been used on the author's own machine only. It is not an official
Universal Blue, Bluefin, Fedora or EasySpeak product, and none of them endorse
it. It is derived from Fedora's software with Fedora's logos and release
branding replaced. Fedora and Silverblue are trademarks of Red Hat, Inc.

## What's in it

| Part | Details |
|------|---------|
| Base | [Fedora Silverblue 44](https://fedoraproject.org/atomic-desktops/silverblue/) (`quay.io/fedora-ostree-desktops/silverblue:44`), with Fedora's logos and release packages replaced by the generic ones |
| Packages | firefox, qutebrowser, v4l-utils, wtype, ydotool, xdg-terminal-exec, and the Fedora packages Bluefin adds that are listed in [`build_files/bluefin-packages.txt`](build_files/bluefin-packages.txt) |
| Codecs | The full ffmpeg set (ffmpeg, libav\*, x264, x265) from the negativo17 multimedia repository, the source Universal Blue uses. The build skips the swap if it would remove anything else |
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

After that, updating is the normal command. Reboot to finish.

```
rpm-ostree upgrade
rpm-ostree rollback    # go back to the previous image
```

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
- **Command cheat sheet.** Open **EasySpeak Commands** from the app grid. The
  everyday commands are open and the long mode sections are folded.

## How it's built

[GitHub Actions](.github/workflows/build.yml) builds and signs the image on
every push (except README-only ones) and daily at 10:05 UTC from the latest
Fedora Silverblue 44 image, and publishes it to `ghcr.io/ctsdownloads/easyspeak-os`.

| Path | Purpose |
|------|---------|
| `Containerfile` | Starts from `silverblue:44` and runs the build script |
| `build_files/build.sh` | Installs the packages and EasySpeak, ships the signing policy, and runs the checks below |
| `build_files/bluefin-packages.txt` | The Fedora packages carried over from Bluefin |
| `build_files/codecs.sh` | Swaps in the full ffmpeg codecs, and skips itself if the swap looks unsafe |
| `build_files/rebrand.sh` | Replaces Fedora's logo and release packages with the generic ones and sets the system name |
| `build_files/initramfs.sh` | Rebuilds the boot image so the boot and disk-unlock screens carry no Fedora logo |
| `build_files/easyspeak-os-boot-label` | Installed as `easyspeak-os-boot-label`, an optional command that renames the firmware boot-menu entry |
| `build_files/make-cheatsheet.py` | Turns EasySpeak's command docs into the cheat sheet and the on-screen list |
| `system_files/` | Files copied into the image, including the Ready Dot extension |
| `cosign.pub` | Public key for verifying the image |

What the build checks:

- Each EasySpeak RPM is verified against the sha256 digest GitHub publishes for
  it before it is installed.
- The build fails if a new EasySpeak release changes the log lines Ready Dot
  reads, so the image does not ship a dot that shows the wrong thing.
- If the build fails before the push step, no image is published and the last
  good one stays. Signing runs after the push, so a failed signing step leaves
  an unsigned image that a signed rebase rejects.
- If the cheat sheet cannot be generated, the image still builds without it.
- The rebrand and boot-image steps fail the build if anything unexpected would be removed, if Fedora's logo or release packages are still installed, or if the new boot image lacks what is needed to unlock a disk.

EasySpeak installs into `/opt`, which is a symlink to `/var/opt` on Fedora Atomic systems and
is not part of the image. The build makes `/opt` a real directory, moves the
files to `/usr/lib/opt/easyspeak`, and adds a tmpfiles rule that links
`/opt/easyspeak` back at boot.

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
- [GNOME](https://www.gnome.org/), [qutebrowser](https://qutebrowser.org/),
  [Firefox](https://www.mozilla.org/firefox/),
  [wtype](https://github.com/atx/wtype),
  [ydotool](https://github.com/ReimuNotMoe/ydotool) and
  [v4l-utils](https://linuxtv.org/wiki/index.php/V4l-utils).

## License

The files in this repository (the build scripts and the Ready Dot extension)
are under the [Apache License 2.0](LICENSE), the same license as the Universal
Blue template and Bluefin. The license text came with the template.

The image itself also contains other software under its own licenses, for
example EasySpeak ([GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.en.html)) and
the Fedora and Bluefin packages. This repository's license does not change
those.

Two more things are not covered by the Apache license:

- The cheat sheet and the on-screen command list are generated at build time
  from EasySpeak's command documentation, so they fall under EasySpeak's
  license (GPL-3.0).
- The speech models in EasySpeak's packages have their own licenses, such as
  NVIDIA's Parakeet model (CC BY 4.0). EasySpeak lists them on its
  [license page](https://easyspeak.dev/latest/license/).
