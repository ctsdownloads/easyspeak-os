"""EasySpeakOS: open or close Bazaar, the app store, by voice.

Shipped by the EasySpeakOS image, not by EasySpeak. EasySpeakOS has Bazaar instead of GNOME Software, so "open
software" (or "open app store", "open bazaar") opens Bazaar and "close software" closes it. This plugin goes before
EasySpeak's own apps plugin (PRIORITY below its 50), which would look for GNOME Software. Bazaar runs its window and
its Super-search provider in one process, bazaar-daemon; closing it ends both, and the next Super search starts the
search provider again by itself. English phrases only.
"""

import os
import re

NAME = "easyspeak-os software"
DESCRIPTION = "Open or close Bazaar, the app store (EasySpeakOS)"
PRIORITY = 40       # before EasySpeak's apps plugin (default 50), and after the window plugin (5)
COMMANDS = ["open software / open app store / open bazaar - Bazaar, the app store: find and install apps",
            "close software - close Bazaar"]

DAEMON = "/usr/bin/bazaar-daemon"
APP = "io.github.kolunmi.Bazaar"
WHAT = r"\b(software|app ?store|bazaar)\b(?! rendering)"
OPEN = re.compile(r"\b(open|start|launch|show)\b.*" + WHAT)
CLOSE = re.compile(r"\b(close|quit|exit)\b.*" + WHAT)


def handle(cmd, core):
    """Open or close Bazaar on its phrases; return None otherwise."""
    text = cmd.lower()
    if CLOSE.search(text):
        core.speak("Closing Bazaar.")
        core.host_run(["pkill", "-x", "bazaar-daemon"])
        return True
    if not OPEN.search(text):
        return None
    if not os.access(DAEMON, os.X_OK):
        core.speak("Bazaar is not available here.")
        return True
    core.speak("Opening Bazaar.")
    core.host_run(["gtk-launch", APP], background=True, clean_env=True)
    return True
