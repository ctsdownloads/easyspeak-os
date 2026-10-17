"""EasySpeakOS: answer EasySpeakOS windows by voice.

Shipped by the EasySpeakOS image, not by EasySpeak. The EasySpeakOS windows (Install Package File, Remove Apps,
Repair App Boxes, System Update, Install Media Codecs) are opened through easyspeak-os-dialog, which describes the
open window in $XDG_RUNTIME_DIR/easyspeak-os/dialogs/. While one is open:
  - say a button's name ("set up and install", "open it", "cancel") to press it;
  - say "number two" (or the name on a line) to pick a line in a list;
  - say "letter g" to scroll a long list to its first line starting with G (windows that say they can: "letters");
  - say "read it" to hear the window and the buttons you can say.
  - say "next" or "continue" to go on, in a window whose main button only moves forward (Start, Next, Test, OK).
Apostrophes don't matter, and "do not" counts as "don't", since speech recognition writes them either way.
When EasySpeak has loaded its plugins, setup() leaves a note (easyspeak-ready, holding EasySpeak's process
number) next to the windows' descriptions, so the setup checklist can wait to open until voice works.
When no such window is open this plugin takes no commands at all, so it never gets in the way of anything else.
It reads a window only when asked: a window read aloud by itself would be heard by the open microphone, and could
press one of its own buttons. Two exceptions, for the EasySpeakOS installer: a screen reached by voice can carry
"announce", said as the reply in place of the button's name (so it is drained like any reply before EasySpeak
listens again); and PID.announce, said whenever it appears, which by design names no button. English phrases only.
"""

import glob
import json
import os
import re
import threading
import time

NAME = "easyspeak-os dialogs"
DESCRIPTION = "Answer EasySpeakOS windows by voice (EasySpeakOS)"
PRIORITY = 5        # before the everyday plugins, so "cancel" or "open it" reach the open window first
COMMANDS = [
    "[a button's name] - press that button in an EasySpeakOS window, for example: set up and install, "
    "open it, cancel",
    "read it - hear what an open EasySpeakOS window says, and the buttons you can say",
    "number one / number two - pick that line in an EasySpeakOS list window",
    "letter a / letter b - scroll a long list in the EasySpeakOS installer to the lines starting with that letter",
    "next / continue - go on, when the window's main button is Start, Next, Test or OK",
]

# The buttons of the software windows (Install Package File, Remove Apps, Repair App Boxes, Start Apps at Login,
# System Tools and its setup checklist, System Update),
# listed by name in the help's Software section. Pressing them works through the button names above; this list is
# only for the help.
HELP_SOFTWARE = [
    "ok / cancel / yes / no / close - press that button in a software window",
    "install / remove / reinstall / update - install, remove or update the app the window shows",
    "set up and install - set up the app box the first time, then install",
    "use flathub / install from fedora / use the file - choose where to install the app from",
    "add to the system - put the app on the system instead of in a box",
    "open it / install the file too / install it here too / install the older version - when the app is already "
    "installed",
    "add it / set up and add it - add a device rule or a download source",
    "open printers / install the driver / about this driver - when the file is a printer driver",
    "try anyway / repair / repair the box - when disk space is low or an app box is broken",
    "delete the box / keep it / restart now / later - answer the questions after removing or installing",
    "turn on / turn off / turn on anyway / free up space / keep it on / keep them on / keep them off - the System "
    "Tools buttons (turning updates on, disk unlock and freeing up space need no administrator password)",
    "undo the update / use the newer version / don't use it / keep it / save details / show the file - undo the "
    "last update or go back to the newer one, or save "
    "problem details for your helper, in System Tools",
    "update anyway / not now / check the boxes - System Update's questions: a low battery, or app boxes that "
    "didn't update",
    "start / later / don't show again / next / skip / restart now - the setup checklist: go through it, skip a "
    "step, and restart at the end if the codecs were installed",
    "test / test again / open sound settings / set it up - the setup checklist's microphone and disk unlock steps",
    "open bazaar / open install package file - the setup checklist's getting apps step: see where apps come from",
    "install EasySpeakOS / try it first - the live USB's welcome window",
]

DIALOGS = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}", "easyspeak-os", "dialogs")
NUMBERS = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",
           "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
TENS = {"twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70, "eighty": 80,
        "ninety": 90}
LETTER = re.compile(r"^letter ([a-z])$")
READ = re.compile(r"^(read (it|this|that|the window|the question|it out|it again)|what does it say)$")
LEAD = re.compile(r"^(please |click |press |choose |select |pick |say |the )+")
TRAIL = re.compile(r"( button| please)+$")


def norm(text):
    """Words only: lower case, no punctuation, no apostrophes ("don't" and "dont" alike), "do not" as "dont"."""
    text = re.sub(r"[^a-z0-9 ]+", " ", (text or "").lower().replace("'", "").replace("\u2019", ""))
    text = " ".join(text.split())
    return re.sub(r"\bdo not\b", "dont", text)


# The main buttons that only move forward: "next" or "continue" presses them. Never a button that changes or removes
# something (Turn off, Remove, Restart now), so a "next" said out of habit can't do that.
FORWARD = {"start", "next", "test", "test again", "ok", "continue"}
READY = os.path.join(os.path.dirname(DIALOGS), "easyspeak-ready")


def setup(core):
    """EasySpeak calls this once its speech model and plugins are loaded: leave the note that voice works now."""
    try:
        os.makedirs(os.path.dirname(READY), exist_ok=True)
        with open(READY, "w") as f:
            f.write(str(os.getpid()))
    except OSError:
        pass
    threading.Thread(target=say_announcements, args=(core,), daemon=True).start()


def say_announcements(core):
    """Say each PID.announce a window leaves (the installer: finished, or stopped), once."""
    while True:
        for path in glob.glob(os.path.join(DIALOGS, "*.announce")):
            try:
                with open(path) as f:
                    text = f.read().strip()
                os.remove(path)
            except OSError:
                continue
            if text:
                core.speak(text)
        time.sleep(1)


def announcement(info, wait=1.0):
    """After a press: what the window's next screen announces (the installer's Review), or "". Only the installer
    announces; a window that closes or doesn't change in time announces nothing."""
    if info.get("mode") != "installer":
        return ""
    path = os.path.join(DIALOGS, f"{info['pid']}.json")
    end = time.monotonic() + wait
    while time.monotonic() < end:
        try:
            with open(path) as f:
                now = json.load(f)
        except (OSError, ValueError):
            return ""
        if now.get("time", 0) > info.get("time", 0):
            return now.get("announce", "")
        time.sleep(0.05)
    return ""


def open_window():
    """The most recent EasySpeakOS window that is still open, or None."""
    best = None
    for path in glob.glob(os.path.join(DIALOGS, "*.json")):
        try:
            with open(path) as f:
                info = json.load(f)
            os.kill(int(info["pid"]), 0)
        except (OSError, ValueError, KeyError, TypeError):
            continue
        if best is None or info.get("time", 0) > best.get("time", 0):
            best = info
    return best


def answer(info, what):
    path = os.path.join(DIALOGS, f"{info['pid']}.answer")
    with open(path + ".tmp", "w") as f:
        f.write(what)
    os.replace(path + ".tmp", path)


def number(words):
    """'number two', 'two', '2', 'line 2' -> 2; up to 999 in words, as long lists need: 'one hundred and five'
    -> 105, 'twenty one' -> 21. None when the words are not a number."""
    words = re.sub(r"^(number|line|item|row) ", "", words)
    if words.isdigit():
        return int(words)
    left = [w for w in words.replace("-", " ").split() if w != "and"]
    value = 0
    if len(left) >= 2 and left[1] == "hundred" and (left[0] == "a" or left[0] in NUMBERS[1:10]):
        value = 100 * (1 if left[0] == "a" else NUMBERS.index(left[0]))
        left = left[2:]
    if left and left[0] in TENS:
        value += TENS[left.pop(0)]
        if left and left[0] in NUMBERS[1:10]:
            value += NUMBERS.index(left.pop(0))
    elif left and left[0] in NUMBERS:
        value += NUMBERS.index(left.pop(0))
    elif not value:
        return None
    return None if left else value


def spoken_buttons(info):
    names = [b["say"] for b in info["buttons"]]
    if not names:
        return ""
    return names[0] if len(names) == 1 else ", ".join(names[:-1]) + " or " + names[-1]


def handle(cmd, core):
    """Press a button, pick a list line or read the open window; return None when no window is open or the words
    are not one of its choices."""
    info = open_window()
    if not info:
        return None
    said = TRAIL.sub("", LEAD.sub("", norm(cmd)))
    if not said:
        return None

    if READ.match(said):
        text = info.get("text", "")
        if len(text) > 700:
            text = text[:700].rsplit(" ", 1)[0] + "..."
        parts = [text] if text else []
        if info.get("rows"):
            first = info.get("first_shown", 0)      # a scrolled list: read the lines on screen
            names = [r["say"] for r in info["rows"][first:first + 9]]
            parts.append("The list has: " + ", ".join(f"number {i}, {n}" for i, n in enumerate(names, first + 1))
                         + ".")
        if info["buttons"]:
            parts.append(f"You can say: {spoken_buttons(info)}.")
        core.speak(" ".join(parts) or "This window has nothing to read.")
        return True

    by_name = {norm(b["say"]): b for b in info["buttons"]}
    button = by_name.get(said)
    if button is None:
        # Spacing doesn't matter: "install easy speak os" presses "Install EasySpeakOS".
        button = next((b for b in info["buttons"] if norm(b["say"]).replace(" ", "") == said.replace(" ", "")), None)
    if button is None and said in ("ok", "okay", "done", "close") and len(info["buttons"]) == 1:
        button = info["buttons"][0]
    if button is None and said in ("ok", "okay") and "ok" in by_name:
        button = by_name["ok"]
    if button is None and said == "cancel":
        button = next((b for b in info["buttons"] if b["does"] == "cancel"), None)
    if button is None and said in ("next", "continue", "go on"):
        button = next((b for b in info["buttons"] if b["does"] == "ok" and norm(b["say"]) in FORWARD), None)
    if button is not None:
        answer(info, button["does"])
        core.speak(announcement(info) or button["say"] + ".")
        return True

    rows = info.get("rows") or []
    letter = LETTER.match(said)
    if rows and letter and info.get("letters"):
        answer(info, f"letter:{letter.group(1)}")
        core.speak(f"Letter {letter.group(1).upper()}.")
        return True
    if rows:
        n = number(said)
        pick = n - 1 if n and 1 <= n <= len(rows) else next(
            (i for i, r in enumerate(rows) if norm(r["say"]).replace(" ", "") == said.replace(" ", "")), None)
        if pick is not None:
            answer(info, f"row:{pick}")
            core.speak(rows[pick]["say"] + ".")
            return True
    return None
