"""The installer's screens, in order. Each one is a numbered list, named buttons, or typed passwords, so every choice
except a password can be said. A screen gives the window its lines (lines()), what picking line N does (pick()),
its own buttons (actions()), whether Next can be pressed (ready()), and what "read it" adds (status())."""
import calendar
import datetime
import json
import re
import subprocess
import urllib.parse

from gi.repository import Adw, Gdk, Gio, GLib, Gtk

import data
from widgets import NumberedList, PasswordPair

MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
          "November", "December"]


class Choices:
    """Everything the person chose, filled in screen by screen. Passwords stay only in memory."""

    def __init__(self):
        self.locale = "en_US.UTF-8"
        self.layouts = ["us"]
        self.layouts_chosen_by_hand = False
        self.boot_layout = None                    # None: the first layout above
        self.timezone = None                       # None: automatic, from the computer's location
        self.time_automatic = True
        self.manual_time = datetime.datetime.now().replace(second=0, microsecond=0)
        self.time_servers = []                     # empty: Fedora's own pool
        self.clock_24 = None                       # None: as the language writes times
        self.disk = None
        self.encrypt = True
        self.disk_password = ""
        self.root_enabled = False
        self.root_password = ""
        self.full_name = ""
        self.username = ""
        self.username_by_hand = False
        self.admin = True
        self.user_password = ""
        self.hostname = ""
        self.hostname_by_hand = False


class Screen:
    title = ""
    step = ""                      # the name in the step line ("Step 3 of 14: Keyboard"); empty: not a step
    intro = ""
    back = True
    next_label = "Next"            # None: no Next button
    main = None                    # the action button shown as the main one
    danger = None                  # the action button shown in red

    def __init__(self, win):
        self.win = win
        self.c = win.choices
        self.body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12, vexpand=True)
        self.build()

    def build(self):
        pass

    def enter(self):
        """Called each time the screen is shown."""
        self.refresh()

    def refresh(self):
        pass

    def lines(self):
        """[(what to say, the line's full text)] for voice, in the order and numbering shown."""
        return []

    def pick(self, i):
        pass

    def actions(self):
        """[(button name, what it does)], shown before Next."""
        return []

    def ready(self):
        return True

    def status(self):
        return ""

    def go_back(self):
        """Back inside the screen (a sub-list); False when Back should leave the screen."""
        return False

    def announce(self):
        """What EasySpeak says on its own when this screen is reached by voice; empty for most screens."""
        return ""

    def changed(self):
        self.win.update()


class ListScreen(Screen):
    """A screen that is one numbered list; lines are (what to say, title, subtitle, chosen). A list longer than a
    screenful gets Page down and Page up, and "letter g" scrolls it to G."""
    LONG = 9

    def build(self):
        self.list = NumberedList(self.pick, self.win.describe)
        self.body.append(self.list)

    def long(self):
        return len(self.items()) > self.LONG

    def alphabetical_from(self):
        """Where the alphabetical part of the list starts, after the lines pinned to the top."""
        return 0

    def items(self):
        return []

    def refresh(self, to_chosen=True):
        self.list.show_lines([(t, s, chosen) for _say, t, s, chosen in self.items()], to_chosen)

    def lines(self):
        return [(say, f"{t}, {s}" if s else t) for say, t, s, _c in self.items()]

    def choose(self, to_chosen=False):
        """After a pick the list stays where it is; to_chosen when it shows a different list (a sub-list)."""
        self.refresh(to_chosen)
        self.changed()


# ---------------------------------------------------------------------------------------------------- 1 Language

class LanguageScreen(ListScreen):
    title = "Language"
    step = "Language"

    @property
    def back(self):
        return self.stage == "locale"

    def build(self):
        super().build()
        self.langs = data.languages()
        self.lang = "en"
        self.stage = "language"

    @property
    def intro(self):
        if self.stage == "language":
            return "Which language should EasySpeakOS use? Say its number or its name."
        return "Which one? Say its number or its name. Say Go back a step for the list of languages."

    def items(self):
        if self.stage == "language":
            return [(eng, eng, native if native != eng else "", lang == self.lang)
                    for lang, eng, native in self.langs]
        return [(eng, eng, native if native != eng else "", loc == self.c.locale)
                for loc, eng, native in data.locales(self.lang)]

    def alphabetical_from(self):
        return len(data.EASYSPEAK_LANGUAGES) if self.stage == "language" else 0

    def pick(self, i):
        if self.stage == "language":
            self.lang = self.langs[i][0]
            options = data.locales(self.lang)
            if len(options) == 1:
                self.c.locale = options[0][0]
            else:
                self.stage = "locale"
                if not self.c.locale.startswith(self.lang + "_"):
                    self.c.locale = options[0][0]
                self.choose(to_chosen=True)
                return
        else:
            self.c.locale = data.locales(self.lang)[i][0]
        self.choose()

    def go_back(self):
        if self.stage == "locale":
            self.stage = "language"
            self.choose(to_chosen=True)
            return True
        return False

    def status(self):
        return f"Chosen: {language_name(self.c.locale)}."


def language_name(loc):
    return next((eng for code, eng, _n in data.locales(loc.split("_")[0].split(".")[0]) if code == loc), loc)


# ---------------------------------------------------------------------------------------------------- 2 Keyboard

class KeyboardScreen(ListScreen):
    title = "Keyboard layout"
    step = "Keyboard"
    intro = ("Which keyboard layouts do you use? Say a number to add it, or say it again to take it off. "
             "The first one is used unless you switch.")

    def build(self):
        super().build()
        self.all = data.keyboards()

    def enter(self):
        self.suggested = [k for k in data.suggested_keyboards(self.c.locale) if k in self.all]
        if not self.c.layouts_chosen_by_hand:
            self.c.layouts = self.suggested[:1]
        rest = sorted((k for k in self.all if k not in self.suggested), key=lambda k: self.all[k].lower())
        self.order = self.suggested + rest
        super().enter()

    def items(self):
        return [(self.all[k], self.all[k], "Suggested" if k in self.suggested else "", k in self.c.layouts)
                for k in self.order]

    def alphabetical_from(self):
        return len(self.suggested)

    def pick(self, i):
        k = self.order[i]
        if k in self.c.layouts:
            if len(self.c.layouts) > 1:
                self.c.layouts.remove(k)
        else:
            self.c.layouts.append(k)
        self.c.layouts_chosen_by_hand = True
        self.choose()

    def status(self):
        return "Chosen: " + ", ".join(self.all[k] for k in self.c.layouts) + "."


# ---------------------------------------------------------------------------------------------------- 3 Keyboard at start

class BootKeyboardScreen(ListScreen):
    """Only the layouts the text console has (kbd's keymaps made from XKB), as the disk password is typed there.
    "Same as above" is offered when the first layout above is one of them; otherwise US English is chosen."""
    title = "Keyboard for the disk password"
    step = "Keyboard at start"
    intro = ("If the disk is encrypted, its password is typed when the computer starts, before EasySpeakOS loads. "
             "Which keyboard layout is used then?")

    def build(self):
        super().build()
        self.all = data.keyboards()
        self.order = sorted((k for k in self.all if data.has_console_keymap(k)), key=lambda k: self.all[k].lower())

    def same_offered(self):
        return self.c.layouts[0] in self.order

    def enter(self):
        if self.c.boot_layout is None and not self.same_offered():
            self.c.boot_layout = "us"
        super().enter()

    def items(self):
        first = self.all[self.c.layouts[0]]
        same = [("Same as above", "Same as above", first, self.c.boot_layout is None)] if self.same_offered() else []
        return same + [(self.all[k], self.all[k], "", self.c.boot_layout == k) for k in self.order]

    def alphabetical_from(self):
        return 1 if self.same_offered() else 0

    def pick(self, i):
        if self.same_offered():
            self.c.boot_layout = None if i == 0 else self.order[i - 1]
        else:
            self.c.boot_layout = self.order[i]
        self.choose()

    def status(self):
        k = self.c.boot_layout or self.c.layouts[0]
        missing = "" if self.same_offered() else f"{self.all[self.c.layouts[0]]} can't be used before EasySpeakOS loads. "
        return f"{missing}Chosen: {self.all[k]}."


# ---------------------------------------------------------------------------------------------------- 4 Network

class NetworkScreen(ListScreen):
    title = "Network"
    step = "Network"

    def build(self):
        super().build()
        self.password = Adw.PasswordEntryRow(title="Wi-Fi password")
        self.password.connect("entry-activated", lambda *_: self.connect_wifi())
        self.password_box = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE, css_classes=["boxed-list"],
                                        visible=False)
        self.password_box.append(self.password)
        self.body.append(self.password_box)
        self.wired, self.wifi, self.chosen, self.busy = False, [], None, ""

    @property
    def intro(self):
        if self.chosen and self.chosen["secured"]:
            return (f"Type the password for {self.chosen['ssid']}, then say Connect to this network. "
                    "Say Go back a step for the list.")
        return ("A network is only needed for automatic time and time zone. To use Wi-Fi, say its number. "
                "Say Go to the next step to go on without it.")

    def enter(self):
        self.wired, self.wifi = data.network()
        super().enter()

    def items(self):
        if self.chosen and self.chosen["secured"]:
            return []
        return [(w["ssid"], w["ssid"], f"Signal {w['signal']}%" + (", password needed" if w["secured"] else ""),
                 False) for w in self.wifi]

    def refresh(self, to_chosen=True):
        super().refresh(to_chosen)
        asking = bool(self.chosen and self.chosen["secured"])
        self.list.set_visible(not asking)
        self.password_box.set_visible(asking)

    def pick(self, i):
        self.chosen = self.wifi[i]
        if self.chosen["secured"]:
            self.password.set_text("")
            self.choose()
            self.password.grab_focus()
        else:
            self.connect_wifi()

    def actions(self):
        if self.chosen and self.chosen["secured"]:
            return [("Connect", self.connect_wifi)]
        return [("Refresh", self.enter)]

    def connect_wifi(self):
        ssid = self.chosen["ssid"]
        args = ["nmcli", "device", "wifi", "connect", ssid]
        if self.chosen["secured"]:
            args += ["password", self.password.get_text()]
        self.busy = f"Connecting to {ssid}..."
        self.choose()
        proc = Gio.Subprocess.new(args, Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_SILENCE)
        proc.wait_check_async(None, self._connected, ssid)

    def _connected(self, proc, result, ssid):
        try:
            ok = proc.wait_check_finish(result)
        except GLib.Error:
            ok = False
        self.busy = f"Connected to {ssid}." if ok else f"Could not connect to {ssid}. Check the password."
        if ok:
            self.chosen = None
        self.wired, self.wifi = data.network()
        self.choose()

    def go_back(self):
        if self.chosen:
            self.chosen, self.busy = None, ""
            self.choose()
            return True
        return False

    def status(self):
        return self.busy or ("Wired network: connected." if self.wired else
                             "Wired network: not connected." + ("" if self.wifi else " No Wi-Fi networks found."))


# ---------------------------------------------------------------------------------------------------- 5 Time zone

class TimeZoneScreen(ListScreen):
    title = "Time zone"
    step = "Time zone"

    def build(self):
        super().build()
        self.zones = data.timezones()
        self.regions = list(self.zones)
        self.region = None

    @property
    def intro(self):
        if self.region:
            return f"Which city in {self.region} has your time? Say Go back a step for the regions."
        return "Set the time zone automatically, or say a region, then a city."

    def items(self):
        if self.region:
            return [(city, city, "", tz == self.c.timezone) for tz, city in self.zones[self.region]]
        return ([("Automatic", "Automatic", "From the computer's location (recommended)", self.c.timezone is None)] +
                [(r, r, "", bool(self.c.timezone) and self.c.timezone.startswith(r + "/")) for r in self.regions])

    def alphabetical_from(self):
        return 0 if self.region else 1

    def pick(self, i):
        if self.region:
            self.c.timezone = self.zones[self.region][i][0]
        elif i == 0:
            self.c.timezone = None
        else:
            self.region = self.regions[i - 1]
            self.choose(to_chosen=True)
            return
        self.choose()

    def go_back(self):
        if self.region:
            self.region = None
            self.choose(to_chosen=True)
            return True
        return False

    def status(self):
        return f"Chosen: {self.c.timezone.replace('_', ' ') if self.c.timezone else 'Automatic'}."


# ---------------------------------------------------------------------------------------------------- 6 Date and time

class DateTimeScreen(ListScreen):
    title = "Date and time"
    step = "Date and time"
    FIELDS = ["Year", "Month", "Day", "Hour", "Minute"]

    def build(self):
        self.server = Adw.EntryRow(title="Time server name (type it or say dictation)")
        self.server.connect("entry-activated", lambda *_: self.add_server())
        self.server_box = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE, css_classes=["boxed-list"],
                                      visible=False)
        self.server_box.append(self.server)
        self.body.append(self.server_box)
        super().build()
        self.stage = "main"                 # main, a field name, or servers

    @property
    def intro(self):
        if self.stage == "servers":
            return ("Time servers to use instead of Fedora's. Add one with its name and say Add it to the list. "
                    "Say a server's number to take it off. Say Go back a step when done.")
        if self.stage in self.FIELDS:
            return f"Say the {self.stage.lower()}. Say Go back a step to keep it as it is."
        return "Keep the clock right automatically, or set the date and time yourself."

    def values(self):
        t = self.c.manual_time
        if self.stage == "Year":
            return [str(y) for y in range(t.year - 1, t.year + 5)]
        if self.stage == "Month":
            return MONTHS
        if self.stage == "Day":
            return [str(d) for d in range(1, calendar.monthrange(t.year, t.month)[1] + 1)]
        if self.stage == "Hour":
            return [f"{h:02d}" for h in range(24)]
        return [f"{m:02d}" for m in range(60)]

    def items(self):
        t = self.c.manual_time
        if self.stage == "servers":
            return [(s, s, "", False) for s in self.c.time_servers]
        if self.stage in self.FIELDS:
            now = {"Year": str(t.year), "Month": MONTHS[t.month - 1], "Day": str(t.day), "Hour": f"{t.hour:02d}",
                   "Minute": f"{t.minute:02d}"}[self.stage]
            return [(v, v, "", v == now) for v in self.values()]
        out = [("Automatic", "Automatic", "From time servers on the internet (recommended)", self.c.time_automatic),
               ("Set it myself", "Set it myself", "", not self.c.time_automatic)]
        if not self.c.time_automatic:
            out += [("Year", "Year", str(t.year), False), ("Month", "Month", MONTHS[t.month - 1], False),
                    ("Day", "Day", str(t.day), False), ("Hour", "Hour", f"{t.hour:02d}", False),
                    ("Minute", "Minute", f"{t.minute:02d}", False)]
        return out

    def refresh(self, to_chosen=True):
        super().refresh(to_chosen)
        self.server_box.set_visible(self.stage == "servers")

    def pick(self, i):
        t = self.c.manual_time
        if self.stage == "servers":
            del self.c.time_servers[i]
        elif self.stage in self.FIELDS:
            v = self.values()[i]
            if self.stage in ("Year", "Month"):         # the day is kept, or made the month's last day
                year, month = (int(v), t.month) if self.stage == "Year" else (t.year, i + 1)
                t = t.replace(year=year, month=month, day=min(t.day, calendar.monthrange(year, month)[1]))
            elif self.stage == "Day":
                t = t.replace(day=int(v))
            elif self.stage == "Hour":
                t = t.replace(hour=int(v))
            else:
                t = t.replace(minute=int(v))
            self.c.manual_time = t
            self.stage = "main"
        elif i < 2:
            self.c.time_automatic = i == 0
        else:
            self.stage = self.FIELDS[i - 2]
        self.choose(to_chosen=self.stage != "main")

    def actions(self):
        if self.stage == "servers":
            return [("Add", self.add_server)]
        if self.stage == "main" and self.c.time_automatic:
            return [("Time servers", self.open_servers)]
        return []

    def open_servers(self):
        self.stage = "servers"
        self.choose(to_chosen=True)
        self.server.grab_focus()

    def add_server(self):
        name = self.server.get_text().strip().lower().replace(" ", "")
        if re.fullmatch(r"[a-z0-9.-]+", name) and name not in self.c.time_servers:
            self.c.time_servers.append(name)
            self.server.set_text("")
        self.choose()

    def ready(self):
        return self.stage == "main"

    def go_back(self):
        if self.stage != "main":
            self.stage = "main"
            self.choose(to_chosen=True)
            return True
        return False

    def status(self):
        if self.c.time_automatic:
            servers = ", ".join(self.c.time_servers) or "Fedora's time servers"
            return f"Chosen: automatic, from {servers}."
        return f"Chosen: {self.c.manual_time.strftime('%-d %B %Y, %H:%M')}."


# ---------------------------------------------------------------------------------------------------- 7 Clock

class ClockScreen(ListScreen):
    title = "Clock"
    step = "Clock"
    intro = "How should the clock show the time?"

    def items(self):
        h24 = self.c.clock_24 if self.c.clock_24 is not None else not data.uses_12_hour(self.c.locale)
        return [("12 hour", "12 hour", "3:30 PM", not h24), ("24 hour", "24 hour", "15:30", h24)]

    def pick(self, i):
        self.c.clock_24 = i == 1
        self.choose()

    def status(self):
        return "Chosen: " + next(t for _s, t, _x, chosen in self.items() if chosen) + "."


# ---------------------------------------------------------------------------------------------------- 8 Disk

class DiskScreen(ListScreen):
    title = "Disk"
    step = "Disk"
    intro = ("Which disk should EasySpeakOS go on? Everything on it will be erased. "
             "The USB stick this runs from is not listed.")

    def enter(self):
        self.disks = data.disks()
        if self.c.disk not in self.disks:            # gone, or another disk now has its name
            self.c.disk = None
        super().enter()

    def items(self):
        return [(d["model"], f"{d['model']}, {d['size']}",
                 d["path"] + (", has encrypted data" if d["encrypted"] else ""),
                 bool(self.c.disk) and self.c.disk["path"] == d["path"]) for d in self.disks]

    def pick(self, i):
        self.c.disk = self.disks[i]
        self.choose()

    def actions(self):
        return [("Refresh", self.enter)]

    def ready(self):
        return self.c.disk is not None

    def status(self):
        if not self.disks:
            return "No disk was found. Connect one and say Look for it again."
        return f"Chosen: {self.c.disk['model']}, {self.c.disk['size']}." if self.c.disk else "No disk chosen yet."


# ---------------------------------------------------------------------------------------------------- 9 Erase warning

class EraseScreen(Screen):
    title = "Erase the disk?"
    step = "Erase"
    next_label = None
    danger = "Erase and install"
    intro = "To go on, say Erase the disk and install. To pick another disk, say Go back a step."

    def build(self):
        self.warning = Gtk.Label(wrap=True, xalign=0, css_classes=["title-2", "erase-warning"])
        self.body.append(self.warning)

    def refresh(self):
        self.warning.set_text(self.status())

    def actions(self):
        return [("Erase and install", self.win.go_next)]

    def status(self):
        d = self.c.disk
        return (f"Everything on {d['model']}, {d['size']} will be erased" +
                (", including encrypted data." if d["encrypted"] else "."))


# ---------------------------------------------------------------------------------------------------- 10 Encryption

class PasswordChoiceScreen(ListScreen):
    """Two choices, the second (or first) asking for a password typed twice."""
    what = ""

    def build(self):
        super().build()
        self.list.set_vexpand(False)
        self.list.set_propagate_natural_height(True)
        self.pair = PasswordPair(self.what, self._typed)
        self.body.append(self.pair)

    def _typed(self):
        self.keep(self.pair.text() if self.pair.ready() else "")
        self.changed()

    def keep(self, password):
        """Store the typed password in the choices ("" until both match)."""

    def wants_password(self):
        return False

    def refresh(self, to_chosen=True):
        super().refresh(to_chosen)
        self.pair.set_visible(self.wants_password())

    def choose(self, to_chosen=False):
        super().choose(to_chosen)
        if self.wants_password():
            self.pair.focus()

    def ready(self):
        return not self.wants_password() or self.pair.ready()


class EncryptionScreen(PasswordChoiceScreen):
    title = "Encryption"
    step = "Encryption"
    what = "Disk password"

    @property
    def intro(self):
        return ("Encrypting keeps the files on this disk private if the computer is lost or stolen. "
                "The disk password is typed at every start, until automatic unlock is turned on in System Tools.")

    def items(self):
        return [("Encrypt", "Encrypt the disk", "Recommended", self.c.encrypt),
                ("Don't encrypt", "Don't encrypt", "", not self.c.encrypt)]

    def pick(self, i):
        self.c.encrypt = i == 0
        self.choose()

    def keep(self, password):
        self.c.disk_password = password

    def wants_password(self):
        return self.c.encrypt

    def status(self):
        if not self.c.encrypt:
            return "Chosen: don't encrypt."
        return "Chosen: encrypt. " + ("The password is typed and matches." if self.pair.ready() else
                                      "Type the disk password twice.")


# ---------------------------------------------------------------------------------------------------- 11 Root

class RootScreen(PasswordChoiceScreen):
    title = "Administrator account (root)"
    step = "Root"
    what = "Root password"
    intro = ("The root account is the system's own administrator. Most people never need it: "
             "your own account can be an administrator instead.")

    def items(self):
        return [("Locked", "Locked", "Recommended", not self.c.root_enabled),
                ("Enabled", "Enabled, with a password", "", self.c.root_enabled)]

    def pick(self, i):
        self.c.root_enabled = i == 1
        self.choose()

    def keep(self, password):
        self.c.root_password = password

    def wants_password(self):
        return self.c.root_enabled

    def status(self):
        return "Chosen: " + ("enabled." if self.c.root_enabled else "locked.")


# ---------------------------------------------------------------------------------------------------- 12 User

def system_names():
    """The user and group names the system already has: the installed system is the one this USB stick runs."""
    names = set()
    for path in ("/etc/passwd", "/usr/lib/passwd", "/etc/group", "/usr/lib/group"):
        try:
            with open(path) as f:
                names |= {line.split(":")[0] for line in f if ":" in line}
        except FileNotFoundError:
            pass
    return names


class UserScreen(ListScreen):
    title = "Your account"
    step = "Account"
    intro = ("Say dictation, then your full name, or type it. Say Read it to hear it back. "
             "Your user name is made from it; type over it to change it.")

    def build(self):
        names = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE, css_classes=["boxed-list"])
        self.full = Adw.EntryRow(title="Full name")
        self.user = Adw.EntryRow(title="User name")
        self.full.connect("changed", self._full_changed)
        self.user.connect("changed", self._user_changed)
        names.append(self.full)
        names.append(self.user)
        self.body.append(names)
        super().build()
        self.list.set_vexpand(False)
        self.list.set_propagate_natural_height(True)
        self.pair = PasswordPair("Password", self._typed)
        self.body.append(self.pair)
        self.setting = False
        self.taken = system_names()

    def _typed(self):
        self.c.user_password = self.pair.text() if self.pair.ready() else ""
        self.changed()

    def enter(self):
        super().enter()
        self.full.grab_focus()

    def _full_changed(self, *_):
        self.c.full_name = " ".join(self.full.get_text().split())
        if not self.c.username_by_hand:
            first = re.sub(r"[^a-z0-9]", "", (self.c.full_name.split() or [""])[0].lower())
            self.setting = True
            self.user.set_text(first if first and first[0].isalpha() else "")
            self.setting = False
        self.changed()

    def _user_changed(self, *_):
        self.c.username = self.user.get_text().strip()
        if not self.setting:
            self.c.username_by_hand = True
        self.changed()

    def username_problem(self):
        u = self.c.username
        if not u:
            return "The user name is empty."
        if not re.fullmatch(r"[a-z_][a-z0-9_-]{0,31}", u):
            return "A user name uses small letters, digits, - and _, and starts with a letter."
        if u in self.taken:
            return f"{u} is used by the system. Choose another user name."
        return ""

    def full_name_problem(self):
        if not self.c.full_name:
            return "The full name is empty."
        if ":" in self.c.full_name or "," in self.c.full_name:
            return "A full name can't have : or , in it."
        return ""

    def items(self):
        return [("Administrator", "Administrator", "Can install software and change system settings. "
                 "Say it again to switch it " + ("off" if self.c.admin else "on") + ".", self.c.admin)]

    def pick(self, i):
        self.c.admin = not self.c.admin
        self.choose()

    def ready(self):
        return not self.full_name_problem() and not self.username_problem() and self.pair.ready()

    def status(self):
        name = self.c.full_name or "not set yet"
        problems = [p for p in (self.full_name_problem() if self.c.full_name else "",
                                self.username_problem() if self.c.username else "") if p]
        return (f"Full name: {name}. User name: {self.c.username or 'not set yet'}. " + "".join(p + " " for p in problems)
                + f"Administrator: {'yes' if self.c.admin else 'no'}. "
                + ("The password is typed and matches." if self.pair.ready() else "Type the password twice."))


# ---------------------------------------------------------------------------------------------------- 13 Computer name

class ComputerNameScreen(Screen):
    title = "Computer name"
    step = "Computer name"
    intro = "This is how the computer shows up on your network. Keep the suggestion, or type a new one."

    def build(self):
        box = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE, css_classes=["boxed-list"])
        self.entry = Adw.EntryRow(title="Computer name")
        self.entry.connect("changed", self._changed)
        box.append(self.entry)
        self.body.append(box)
        self.setting = False

    def enter(self):
        if not self.c.hostname_by_hand:
            self.setting = True
            self.entry.set_text(f"{self.c.username or 'easyspeakos'}-computer")
            self.setting = False
        self.entry.grab_focus()

    def _changed(self, *_):
        self.c.hostname = self.entry.get_text().strip().lower()
        if not self.setting:
            self.c.hostname_by_hand = True
        self.changed()

    def ready(self):
        return bool(re.fullmatch(r"[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?", self.c.hostname))

    def status(self):
        return f"Computer name: {self.c.hostname}." + ("" if self.ready() else
                                                      " Use letters, digits and -, not at the start or end.")


# ---------------------------------------------------------------------------------------------------- 14 Review

class ReviewScreen(ListScreen):
    title = "Review"
    step = "Review"
    next_label = None
    main = "Install"
    intro = "Check everything. Say a number to change it, or say Start the install to put EasySpeakOS on the disk."

    def summary(self):
        c, kb = self.c, data.keyboards()
        clock = "24 hour" if (c.clock_24 if c.clock_24 is not None else not data.uses_12_hour(c.locale)) else "12 hour"
        user = f"{c.full_name} ({c.username})" + (", administrator" if c.admin else "")
        return [
            ("Language", language_name(c.locale), LanguageScreen),
            ("Keyboard", ", ".join(kb[k] for k in c.layouts), KeyboardScreen),
            ("Keyboard at start", kb[c.boot_layout or c.layouts[0]], BootKeyboardScreen),
            ("Time zone", c.timezone.replace("_", " ") if c.timezone else "Automatic", TimeZoneScreen),
            ("Date and time", "Automatic" if c.time_automatic else c.manual_time.strftime("%-d %B %Y, %H:%M"),
             DateTimeScreen),
            ("Clock", clock, ClockScreen),
            ("Disk", f"{c.disk['model']}, {c.disk['size']}, erased" if c.disk else "Not chosen", DiskScreen),
            ("Encryption", "Encrypted" if c.encrypt else "Not encrypted", EncryptionScreen),
            ("Root", "Enabled" if c.root_enabled else "Locked", RootScreen),
            ("Account", user, UserScreen),
            ("Computer name", c.hostname, ComputerNameScreen),
        ]

    def items(self):
        return [(name, name, value, False) for name, value, _s in self.summary()]

    def pick(self, i):
        self.win.change(self.summary()[i][2])

    def actions(self):
        return [("Install", self.win.install)]

    def status(self):
        return " ".join(f"{name}: {value}." for name, value, _s in self.summary())

    def announce(self):
        return f"Review. {self.status()} Say a number to change it, or say Start the install."


# ---------------------------------------------------------------------------------------------------- 15-17

ENGINE = "/usr/libexec/easyspeak-os-install-engine"


class InstallingScreen(Screen):
    """Runs the install engine as root (pkexec) and follows the progress it reports, one JSON object a line."""
    title = "Installing EasySpeakOS"
    intro = "This takes a while. Say Read it to hear how far it is."
    back = False
    next_label = None

    def build(self):
        self.bar = Gtk.ProgressBar()
        self.body.append(self.bar)
        self.pulsing = None
        self.progress(0, "Getting ready")

    def progress(self, fraction, what):
        self.stop_pulse()
        self.bar.set_fraction(fraction)
        self.done = f"{fraction * 100:.0f}% done. {what}..."
        if getattr(self.win, "current", None) is self:      # so the screen and "read it" show the latest step
            self.changed()

    def pulse(self, what):
        """A step whose length can't be measured: the bar moves, and "read it" says what it is doing."""
        self.done = f"{what}. This is the longest step..."
        if self.pulsing is None:
            self.pulsing = GLib.timeout_add(120, lambda: self.bar.pulse() or True)
        self.changed()

    def stop_pulse(self):
        if self.pulsing is not None:
            GLib.source_remove(self.pulsing)
            self.pulsing = None

    def start(self):
        c = self.c
        h24 = c.clock_24 if c.clock_24 is not None else not data.uses_12_hour(c.locale)
        choices = {"disk": c.disk["path"], "disk_identity": c.disk["identity"], "encrypt": c.encrypt, "disk_password": c.disk_password,
                   "locale": c.locale, "layouts": c.layouts, "boot_layout": c.boot_layout or c.layouts[0],
                   "timezone": c.timezone, "time_automatic": c.time_automatic,
                   "manual_time": c.manual_time.isoformat(), "time_servers": c.time_servers, "clock_24": h24,
                   "hostname": c.hostname, "root_password": c.root_password if c.root_enabled else None,
                   "full_name": c.full_name, "username": c.username, "admin": c.admin,
                   "user_password": c.user_password}
        try:
            self.engine = Gio.Subprocess.new(["pkexec", ENGINE],
                                             Gio.SubprocessFlags.STDIN_PIPE | Gio.SubprocessFlags.STDOUT_PIPE)
        except GLib.Error as e:
            self.win.install_failed(f"The installer could not start: {e.message}", data.LOG)
            return
        stdin = self.engine.get_stdin_pipe()
        stdin.write_all(json.dumps(choices).encode(), None)
        stdin.close(None)
        self.reader = Gio.DataInputStream.new(self.engine.get_stdout_pipe())
        self.reader.read_line_async(GLib.PRIORITY_DEFAULT, None, self._line)

    def _line(self, stream, result):
        line, _length = stream.read_line_finish_utf8(result)
        if line is None:                    # the engine ended without saying how: treat it as an error
            self.stop_pulse()
            self.win.install_failed("The installer stopped unexpectedly.", data.LOG)
            return
        try:
            said = json.loads(line)
        except ValueError:
            said = {}
        if "progress" in said:
            self.progress(said["progress"], said["step"])
        elif "pulse" in said:
            self.pulse(said["step"])
        elif "error" in said:
            self.stop_pulse()
            self.win.install_failed(said["error"], said["log"])
            return
        elif said.get("done"):
            self.stop_pulse()
            self.win.install_done()
            return
        stream.read_line_async(GLib.PRIORITY_DEFAULT, None, self._line)

    def status(self):
        return self.done


class LogScreen(ListScreen):
    """A screen the install ends on, which can put the log on a USB stick: the list is the sticks found, and saying
    one's number saves the log on it. The saved log carries EasySpeak's own lines too, so a voice problem can be
    read afterwards; the live USB has no terminal to read them with."""
    next_label = None

    def build(self):
        super().build()
        self.stage, self.saved, self.found = "main", "", []

    @property
    def back(self):
        return self.stage != "main"

    def enter(self):
        self.stage, self.saved = "main", ""
        super().enter()

    def refresh(self, to_chosen=True):
        super().refresh(to_chosen)
        self.list.set_visible(self.stage == "sticks")

    def items(self):
        if self.stage != "sticks":
            return []
        return [(s["name"], f"{s['name']}, {s['size']}", s["path"], False) for s in self.found]

    def find_sticks(self):
        self.stage, self.found = "sticks", data.sticks()
        self.saved = "" if self.found else "No USB stick found. Plug one in and say Look for it again."
        self.choose(to_chosen=True)

    def pick(self, i):
        stick = self.found[i]
        name = f"easyspeak-os-install-log-{datetime.datetime.now():%Y%m%d-%H%M}.txt"
        problem = data.save_to_stick(stick["path"], data.log_with_voice(), name)
        self.saved = (f"Saved on {stick['name']} as {name}. You can take the stick out now." if not problem else
                      f"Not saved: {problem}")
        self.stage = "main" if not problem else "sticks"
        self.choose(to_chosen=True)

    def go_back(self):
        if self.stage != "main":
            self.stage = "main"
            self.choose(to_chosen=True)
            return True
        return False

    def status(self):
        return self.saved


class DoneScreen(LogScreen):
    title = "EasySpeakOS is installed"
    back = False
    main = "Restart"

    @property
    def intro(self):
        if self.stage == "sticks":
            return ("Plug in a second USB stick, then say its number to save the log on it. Say Look for it "
                    "again if it isn't listed, or Go back a step.")
        return ("Say Restart the computer to start EasySpeakOS. Say Save the log to a stick to put the details of this "
                "install, and what EasySpeak did, on a second USB stick.")

    def actions(self):
        return [("Restart", self.win.restart), ("Save the log", self.find_sticks)]


class ErrorScreen(LogScreen):
    """The install stopped. Three ways to get help, the least typing first: save the log to a USB stick for a
    helper (no account), a QR code that opens the report on a phone, or the report in Firefox (signing in to GitHub
    there means typing a password). A link can carry an issue's text but not a file, so the reports carry the end
    of the log; the whole log goes on the stick."""
    title = "The install stopped"
    next_label = None
    ISSUES = "https://github.com/ctsdownloads/easyspeak-os/issues/new"
    BODY_MAX = 7000              # the body length Anaconda's GitHub report links were limited to
    QR_URL_MAX = 1800            # a denser code is harder for a phone to read off a screen

    def build(self):
        self.what = Gtk.Label(xalign=0, wrap=True, selectable=True, css_classes=["heading"])
        self.body.append(self.what)
        self.code = Gtk.Picture(can_shrink=True, halign=Gtk.Align.CENTER, visible=False)
        self.code.set_size_request(360, 360)
        self.body.append(self.code)
        super().build()
        self.problem, self.log = "", ""

    def failed(self, problem, log):
        self.problem, self.log = problem, log
        self.what.set_text(problem)

    @property
    def intro(self):
        if self.stage == "sticks":
            return ("Plug in a USB stick, then say its number to save the log on it. Say Look for it again if it isn't "
                    "listed, or Go back a step.")
        if self.stage == "code":
            return ("Point your phone's camera at the code. It opens the report on GitHub with the details filled in, "
                    "ready to send. It carries the end of the log; the whole log can go on a USB stick. Say Go "
                    "back a step.")
        return ("Nothing more was changed on the disk. Say Save the log to a stick to put the details on a USB "
                "stick for your helper; no account is needed. Say Show a QR code to send a report from your "
                "phone. Or say Report it on GitHub to send it from Firefox: that needs a free GitHub account, "
                "and signing in needs your "
                "password typed. Or say Restart the computer.")

    def refresh(self, to_chosen=True):
        super().refresh(to_chosen)
        self.code.set_visible(self.stage == "code")

    def actions(self):
        if self.stage == "sticks":
            return [("Refresh", self.find_sticks)]
        if self.stage == "code":
            return []
        return [("Save the log", self.find_sticks), ("Show a QR code", self.show_code),
                ("Report on GitHub", self.report), ("Restart", self.win.restart)]

    def show_code(self):
        made = subprocess.run(["qrencode", "-t", "PNG", "-l", "L", "-s", "8", "-m", "4", "-o", "-",
                               self.issue_url(self.QR_URL_MAX)], capture_output=True)
        if made.returncode != 0:
            self.saved = "The QR code could not be made. Say Save the log to a stick instead."
        else:
            self.code.set_paintable(Gdk.Texture.new_from_bytes(GLib.Bytes.new(made.stdout)))
            self.stage, self.saved = "code", ""
        self.choose(to_chosen=True)

    def issue_url(self, url_max=None):
        """The new-issue link with the title and text filled in: the error, then as much of the end of the log, in
        whole lines, as fits in BODY_MAX characters of text, and in url_max characters of link when given."""
        try:
            with open(self.log, errors="replace") as f:
                lines = f.read().splitlines(keepends=True)
        except OSError:
            lines = []
        kept, size = [], 0                  # start from the lines that can fit at all
        for line in reversed(lines):
            size += len(line)
            if size > self.BODY_MAX:
                break
            kept.insert(0, line)
        lines = kept or [line[-self.BODY_MAX // 2:] for line in lines[-1:]]     # one line longer than all of it
        head = f"The installer stopped with:\n\n    {self.problem}\n\nThe end of the installer's log:\n\n```\n"
        title = f"Install stopped: {self.problem}"[:256]
        while True:
            body = head + "".join(lines) + "```"
            url = f"{self.ISSUES}?{urllib.parse.urlencode({'title': title, 'body': body})}"
            if not lines or (len(body) <= self.BODY_MAX and (url_max is None or len(url) <= url_max)):
                return url
            if len(lines) > 1:
                lines.pop(0)
            else:                           # the last line alone is too long: keep its end
                lines[0] = lines[0][len(lines[0]) // 4:] if len(lines[0]) > 80 else ""
                lines = [x for x in lines if x]

    def report(self):
        Gtk.UriLauncher.new(self.issue_url()).launch(self.win, None, None, None)


STEPS =[LanguageScreen, KeyboardScreen, BootKeyboardScreen, NetworkScreen, TimeZoneScreen, DateTimeScreen,
         ClockScreen, DiskScreen, EraseScreen, EncryptionScreen, RootScreen, UserScreen, ComputerNameScreen,
         ReviewScreen]
