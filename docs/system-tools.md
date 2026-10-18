# System Tools

[Back to the EasySpeakOS README](../README.md)

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
| EasySpeak on or off | Turns voice control off or on, and it stays that way after a restart. The switch in the power menu only stops listening until the next login. Turning it off stops EasySpeak right away, so turn it back on from System Tools in Show Apps, with the mouse or keyboard |
| Setup checklist | The microphone, media codecs, disk unlock and getting apps, one at a time. It opens by itself at a new user's first login. See [First login](install.md#first-login) |

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
