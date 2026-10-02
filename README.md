# speakfin

A custom Bluefin image for a workstation, with EasySpeak voice control for
accessibility. It is stock `ghcr.io/ublue-os/bluefin:stable` plus two additions.

## What's in it

- **Packages:** firefox, qutebrowser, v4l-utils, wtype, ydotool.
- **[EasySpeak](https://easyspeak.dev/latest/)** with its Parakeet and English
  speech packs. The newest release is installed when the image is built.

## Switching to it

The image ships its own signature policy, so switching takes two rebases. The
first one is unverified because a fresh machine has no key yet. It installs the
key and policy. The second one is verified.

    rpm-ostree rebase ostree-unverified-registry:ghcr.io/ctsdownloads/speakfin:latest
    systemctl reboot
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ctsdownloads/speakfin:latest
    systemctl reboot

Update with `rpm-ostree upgrade`. Roll back with `rpm-ostree rollback`.

To check a signature by hand:

    cosign verify --key cosign.pub ghcr.io/ctsdownloads/speakfin:latest

## How it's built

GitHub Actions builds and signs the image on every push (except README-only
ones) and daily at 10:05 UTC from the latest Bluefin, and publishes it to
`ghcr.io/ctsdownloads/speakfin`. If the build fails before the push step,
no image is published and the last good one stays. Signing runs after the push,
so a failed signing step leaves an unsigned image that a signed rebase rejects.

`build_files/build.sh` installs the packages, downloads the newest EasySpeak
RPMs and checks each against the sha256 digest GitHub publishes for it, and
ships the signing key and policy for this image.

## EasySpeak

[Documentation](https://easyspeak.dev/latest/) ·
[Source](https://github.com/ctsdownloads/easyspeak)

- It installs into `/opt`, which is a symlink to `/var/opt` on Bluefin and is
  not part of the image. The build makes `/opt` a real directory, moves the
  files to `/usr/lib/opt/easyspeak`, and adds a tmpfiles rule that links
  `/opt/easyspeak` back at boot.
- Two one-time steps per user: log out and back in so GNOME loads the shell
  extension, and run `sudo usermod -aG input "$USER"` for hold-to-dictate.
- Updates are automatic: the daily build installs the newest EasySpeak
  release. If a build fails, the last good image stays.
- If `easyspeak` fails with a bad interpreter error, remove an old
  `~/.local/bin/easyspeak` left over from a source install.

## Ready dot

EasySpeak has no window of its own. The image adds a small GNOME extension that
shows a dot in the top bar while EasySpeak is listening for commands without the
wake word. Yellow means go ahead and speak. Orange means it is busy hearing,
thinking or replying. No dot means it is waiting for the wake word. The
extension reads EasySpeak's log lines from the session journal and watches its
CPU use. After an update and a reboot, turn it on once:

    gnome-extensions enable ready-dot@speakfin

The build fails if a new EasySpeak release changes the log lines it reads.

## Caveats

- Unofficial.
- EasySpeak is early development software. Its RPMs are checked by the sha256
  digest GitHub publishes, not by signature, and a new release is installed
  automatically.
