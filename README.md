# xps

A custom Bluefin image for a Dell XPS 13 9310. It is stock
`ghcr.io/ublue-os/bluefin:stable` plus three additions.

## What's in it

- **Fingerprint driver.** The Goodix `27c6:533c` reader has no driver in stock
  Bluefin. This image swaps `libfprint` for `libfprint-tod`, built from source
  on the Bluefin base, plus the Goodix TOD driver.
- **Packages:** firefox, qutebrowser, v4l-utils, wtype, ydotool.
- **[EasySpeak](https://easyspeak.dev/latest/)** 0.12.0 with its speech packs:
  Parakeet 1.0.0 and English 1.1.0.

## Switching to it

The image ships its own signature policy, so switching takes two rebases. The
first one is unverified because a fresh machine has no key yet. It installs the
key and policy. The second one is verified.

    rpm-ostree rebase ostree-unverified-registry:ghcr.io/ctsdownloads/image-template:latest
    systemctl reboot
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ctsdownloads/image-template:latest
    systemctl reboot

Update with `rpm-ostree upgrade`. Roll back with `rpm-ostree rollback`.
Enroll a finger with `fprintd-enroll`.

To check a signature by hand:

    cosign verify --key cosign.pub ghcr.io/ctsdownloads/image-template:latest

## How it's built

GitHub Actions builds and signs the image on every push (except README-only
ones) and daily at 10:05 UTC from the latest Bluefin, and publishes it to
`ghcr.io/ctsdownloads/image-template`. If the build fails before the push step,
no image is published and the last good one stays. Signing runs after the push,
so a failed signing step leaves an unsigned image that a signed rebase rejects.

The `Containerfile` has two stages on the same Bluefin base:

1. `build_files/build-tod.sh` compiles libfprint-TOD 1.94.10 from the
   [3v1n0 fork](https://gitlab.freedesktop.org/3v1n0/libfprint), pinned to a
   commit hash, into an RPM using `build_files/libfprint-tod.spec`. The RPM
   provides `libfprint`, so Fedora's `fprintd` keeps working.
2. `build_files/build.sh` installs the packages, downloads the EasySpeak RPMs
   and checks them against pinned sha256 sums, then installs the libfprint-tod
   RPM and the Goodix driver in one `dnf` transaction, replacing stock
   libfprint. The build fails if stock libfprint is still present, and the
   first stage fails unless TOD loads the Goodix driver. The script also ships
   the signing key and policy for this image.

`build_files/rpms/` holds the Goodix driver RPM, the COPR signing key
(`pubkey.gpg`) used to verify it at build time, and Goodix's license text.

## Updating libfprint-TOD

The source is pinned to 1.94.10, the newest TOD tag based on a 1.94 release.
Newer 1.95.x tags exist but do not include upstream's 1.94.100, which Fedora
ships, and have not been tested here. To move to a newer tag, change `ver` and
`commit` in `build_files/build-tod.sh` and `Version` in
`build_files/libfprint-tod.spec`.

## EasySpeak

[Documentation](https://easyspeak.dev/latest/) ·
[Source](https://github.com/ctsdownloads/easyspeak)

- It installs into `/opt`, which is a symlink to `/var/opt` on Bluefin and is
  not part of the image. The build makes `/opt` a real directory, moves the
  files to `/usr/lib/opt/easyspeak`, and adds a tmpfiles rule that links
  `/opt/easyspeak` back at boot.
- Two one-time steps per user: log out and back in so GNOME loads the shell
  extension, and run `sudo usermod -aG input "$USER"` for hold-to-dictate.
- To update it, change the three versions and sha256 sums in
  `build_files/build.sh` and push.
- If `easyspeak` fails with a bad interpreter error, remove an old
  `~/.local/bin/easyspeak` left over from a source install.

## Caveats

- Unofficial. The Goodix driver is a closed-source binary distributed through
  the Dell/Canonical OEM archive and packaged by a third party (the COPR
  `manciukic/libfprint-tod-goodix`). It is a frozen 2020 vendor file
  (version 0.0.6), redistributed unmodified under its license. See
  `build_files/rpms/GOODIX-LICENSE.txt` for the copyright notice and
  disclaimer.
- The build smoke test loads the driver but cannot touch hardware, so a failure
  that only shows up while scanning would not be caught.
- EasySpeak is early development software. Its RPMs are checked by pinned
  sha256 only, not by signature.
- Tested on Bluefin stable.
