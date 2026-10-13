"""EasySpeak-OS: answer EasySpeak-OS windows by voice.

Shipped by the EasySpeak-OS image, not by EasySpeak. The EasySpeak-OS windows (Install Package File, Remove Apps,
Repair App Boxes, System Update, Install Media Codecs) are opened through easyspeak-os-dialog, which describes the
open window in $XDG_RUNTIME_DIR/easyspeak-os/dialogs/. While one is open:
  - say a button's name ("set up and install", "open it", "cancel") to press it;
  - say "number two" (or the name on a line) to pick a line in a list;
  - say "read it" to hear the window and the buttons you can say.
When no such window is open this plugin takes no commands at all, so it never gets in the way of anything else.
It never speaks on its own: a window read aloud by itself would be heard by the open microphone, and could press
one of its own buttons. English phrases only.
"""

import glob
import json
import os
import re

NAME = "easyspeak-os dialogs"
DESCRIPTION = "Answer EasySpeak-OS windows by voice (EasySpeak-OS)"
PRIORITY = 5        # before the everyday plugins, so "cancel" or "open it" reach the open window first
COMMANDS = [
    "[a button's name] - press that button in an EasySpeak-OS window, for example: set up and install, "
    "open it, cancel",
    "read it - hear what an open EasySpeak-OS window says, and the buttons you can say",
    "number one / number two - pick that line in an EasySpeak-OS list window",
]

DIALOGS = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}", "easyspeak-os", "dialogs")
NUMBERS = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",
           "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"]
READ = re.compile(r"^(read (it|this|that|the window|the question|it out|it again)|what does it say)$")
LEAD = re.compile(r"^(please |click |press |choose |select |pick |say |the )+")
TRAIL = re.compile(r"( button| please)+$")


def norm(text):
    text = re.sub(r"[^a-z0-9' ]+", " ", (text or "").lower())
    return " ".join(text.split())


def open_window():
    """The most recent EasySpeak-OS window that is still open, or None."""
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
    """'number two', 'two', '2', 'line 2' -> 2; or None."""
    words = re.sub(r"^(number|line|item|row) ", "", words)
    if words.isdigit():
        return int(words)
    return NUMBERS.index(words) if words in NUMBERS else None


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
            names = [r["say"] for r in info["rows"][:9]]
            parts.append(f"The list has: " + ", ".join(f"number {i}, {n}" for i, n in enumerate(names, 1)) + ".")
        if info["buttons"]:
            parts.append(f"You can say: {spoken_buttons(info)}.")
        core.speak(" ".join(parts) or "This window has nothing to read.")
        return True

    by_name = {norm(b["say"]): b for b in info["buttons"]}
    button = by_name.get(said)
    if button is None and said in ("ok", "okay", "done", "close") and len(info["buttons"]) == 1:
        button = info["buttons"][0]
    if button is None and said in ("ok", "okay") and "ok" in by_name:
        button = by_name["ok"]
    if button is None and said == "cancel":
        button = next((b for b in info["buttons"] if b["does"] == "cancel"), None)
    if button is not None:
        answer(info, button["does"])
        core.speak(button["say"] + ".")
        return True

    rows = info.get("rows") or []
    if rows:
        n = number(said)
        pick = n - 1 if n and 1 <= n <= len(rows) else next(
            (i for i, r in enumerate(rows) if norm(r["say"]) == said), None)
        if pick is not None:
            answer(info, f"row:{pick}")
            core.speak(rows[pick]["say"] + ".")
            return True
    return None
