"""Lets EasySpeak answer the installer, the same way it answers every EasySpeakOS window.

The installer describes the screen it shows in $XDG_RUNTIME_DIR/easyspeak-os/dialogs/PID.json, in the format
build_files/easyspeak-os-dialog writes for zenity windows: the text, the buttons ("say" is the button's name,
"does" is "ok" for Next, "extra:NAME" for the others) and the numbered lines of a list. EasySpeak's EasySpeakOS
dialogs plugin reads it and writes PID.answer: "ok", "cancel", "extra:NAME", "row:N" or "letter:X". The installer reads the
answer and does what pressing that button or picking that line does.

Speaking on its own: a screen reached by voice can carry "announce", which the plugin says in place of repeating the
button's name (the Review). PID.announce is said whenever it appears (the install finished, or stopped): its text
names no button, as EasySpeak may still be listening when it is said.
"""
import json
import os
import time
import traceback

from gi.repository import GLib

DIALOGS = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}", "easyspeak-os", "dialogs")


class Voice:
    def __init__(self, on_answer):
        self.on_answer = on_answer
        self.state = os.path.join(DIALOGS, f"{os.getpid()}.json")
        self.answer = os.path.join(DIALOGS, f"{os.getpid()}.answer")
        os.makedirs(DIALOGS, exist_ok=True)
        GLib.timeout_add(150, self._poll)

    def describe(self, title, text, buttons, rows, first_shown=0, letters=False, announce=""):
        """buttons: [(name, does)]; rows: [(what to say, the line's full text)]; first_shown: the first line on
        screen, so "read it" reads what is shown; letters: "letter g" scrolls the list (answered "letter:g");
        announce: said when the screen is reached by voice."""
        info = {"pid": os.getpid(), "mode": "installer", "title": title, "text": " ".join(text.split()),
                "buttons": [{"say": name, "does": does} for name, does in buttons],
                "rows": [{"say": say, "value": str(i), "text": full} for i, (say, full) in enumerate(rows)],
                "first_shown": first_shown, "letters": letters, "announce": announce, "time": time.time()}
        with open(self.state + ".tmp", "w") as f:
            json.dump(info, f)
        os.replace(self.state + ".tmp", self.state)

    def announce(self, text):
        path = os.path.join(DIALOGS, f"{os.getpid()}.announce")
        with open(path + ".tmp", "w") as f:
            f.write(text)
        os.replace(path + ".tmp", path)

    def _poll(self):
        try:
            with open(self.answer) as f:
                said = f.read().strip()
            os.remove(self.answer)
        except OSError:
            return True
        try:
            self.on_answer(said)
        except Exception:                  # GLib stops calling a timer that raises: voice would go deaf for good
            traceback.print_exc()
        return True

    def close(self):
        for path in (self.state, self.answer, os.path.join(DIALOGS, f"{os.getpid()}.announce")):
            try:
                os.remove(path)
            except OSError:
                pass
