"""EasySpeak-OS: open System Tools by voice.

Shipped by the EasySpeak-OS image, not by EasySpeak. "System tools" opens the System Tools window: update
firmware, unlock the disk automatically, free up disk space, restart into the BIOS settings, turn automatic
updates on or off, undo the last update, and save problem details for your helper. In the window, say "number two" to pick a tool and say its buttons. English phrases only.
"""

import os
import re

NAME = "easyspeak-os tools"
DESCRIPTION = "Open System Tools (EasySpeak-OS)"
COMMANDS = ["system tools - update firmware, unlock the disk automatically, free up disk space, undo the last "
            "update, save problem details for your helper and more"]

TOOL = "/usr/bin/easyspeak-os-tools"
PHRASES = re.compile(r"\bsystem tools?\b")


def handle(cmd, core):
    """Open System Tools on its phrase; return None otherwise."""
    if not PHRASES.search(cmd.lower()):
        return None
    if not os.access(TOOL, os.X_OK):
        core.speak("System Tools is not available here.")
        return True
    core.speak("Opening System Tools.")
    core.host_run([TOOL], background=True, clean_env=True)
    return True
