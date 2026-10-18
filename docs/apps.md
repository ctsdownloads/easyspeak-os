# Apps from .rpm and .deb files

[Back to the EasySpeakOS README](../README.md)

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
