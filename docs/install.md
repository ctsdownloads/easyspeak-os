# Install

[Back to the EasySpeakOS README](../README.md)

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
   the disk and install**. The **Review** at the end is read aloud; say a number
   to change that step, or **start the install**. It installs EasySpeakOS from the
   copy on the USB
   stick, with no download, and says when it's finished; then say
   **restart the computer**, which restarts the computer whether you say it
   or press the button, with nothing else open and the screen untouched. If the
   restart doesn't start, a pop-up shows the exact error, to photograph for a
   report. The finished screen also offers
   **save the log to a stick**: it puts the details of the install, and what EasySpeak
   itself did, on a second USB stick. Use it if anything went wrong, including
   voice not answering, since the live USB has no terminal to read a log with.
   A Wi-Fi network joined during
   the install is saved on the new system, so it is online from its first start. The orange
   **Alpha** badge at the top says EasySpeakOS is in alpha.

   On every screen, a line above the buttons names every phrase that screen
   takes, so nothing has to be guessed at: the numbers it has (`"number 1" to
   "number 9"`), the letters when the list is long, each button, and
   `"read it"`. Each button is said as a whole phrase rather than its one or two
   word name, because a short word is what speech recognition gets wrong and a
   phrase is heard reliably: **restart the computer**, **go back a step**, **go
   to the next step**, **start the install**, **erase the disk and install**,
   **save the log to a stick**, **look for it again**, **connect to this
   network**, **add it to the list**, **scroll up the list**, **scroll down the
   list**, **open the time servers**, **report it on GitHub**. The short name
   still works if you say it ("restart", "back", "next"), it just isn't what the
   screen shows. Say a line's number (up to "nine hundred ninety nine") or its
   name, a button's phrase, or **read it** to hear the screen. Starting with the
   word "number" is the surest way to pick a line, and after it a misheard small
   number still counts, so "number to" picks line 2. Long lists have **scroll
   down the list** and **scroll up the list**, and **letter G** scrolls to the entries starting
   with G. The live USB never dims, blanks, locks or suspends, so an
   install can run untouched to the end; the installed system keeps GNOME's
   normal power settings.

   If the install stops, nothing more is changed, and the installer offers,
   least typing first: **save the log to a stick** (onto another USB stick, for
   your helper; no account needed), **show a QR code** (a pre-filled problem
   report on this project's GitHub page, opened on a phone), or **report it on
   GitHub** (the same report in Firefox, which needs a free GitHub account and
   its password typed). The saved log carries EasySpeak's own lines as well as the
   install's, and leaves out the passwords and the names you typed.
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
use **Undo the last update** in [System Tools](system-tools.md#system-tools), or run
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
  2. **Media codecs:** the [Media codecs](building.md#media-codecs) window, with no
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
