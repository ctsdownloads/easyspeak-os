# Using it by voice

[Back to the EasySpeakOS README](../README.md)

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
  something, like Turn off. A short button name can also be pressed by a longer
  phrase, which short names need because speech recognition mishears them:
  "restart the computer", "reboot now" and "restart now" all press **Restart**,
  along with the words it comes back as instead ("we start"). The installer goes
  further and names its buttons with the phrase itself, so that is what its
  screens show. Starting with the
  word "number" is the surest way to pick a line, and after it a misheard small
  number still counts ("number to" picks line 2); said on its own, "to" is left
  alone as an ordinary word. A longer phrase is only taken when
  the open window has that button, so it can never press anything else. The wake
  word can also come last ("restart, Jarvis"). The window
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
| System Tools: firmware, disk unlock, free space, BIOS settings, automatic updates, undo the last update, problem details, EasySpeak on or off | Yes | "system tools", "number one" and so on for the tool, then say the buttons. Some jobs ask for a password, which is typed |
| Media codecs | Yes | Answer the window by voice. Adding them needs no password; taking them out asks for the administrator password |

**Still typed:**

- the password to log in and to unlock the screen
- the administrator password, when adding an app to the system, taking the
  codecs out, or for the System Tools jobs that keep it (see
  [System Tools](system-tools.md#system-tools))
- the disk password, once, when turning Unlock disk automatically on or off
- the install and first-login setup
- Homebrew, and anything else in a terminal
