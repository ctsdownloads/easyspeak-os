"""EasySpeakOS: open System Tools, or its setup checklist, by voice.

Shipped by the EasySpeakOS image, not by EasySpeak. "System tools" opens the System Tools window: update
firmware, unlock the disk automatically, free up disk space, restart into the BIOS settings, turn automatic
updates on or off, undo the last update, save problem details for your helper, and the setup checklist.
"Setup checklist" opens the checklist straight away: microphone, media codecs, disk unlock and getting apps.
In the window, say "number two" to pick a tool and say its buttons. English phrases only.
"""

import os
import re

NAME = "easyspeak-os tools"
DESCRIPTION = "Open System Tools (EasySpeakOS)"
COMMANDS = ["system tools - update firmware, unlock the disk automatically, free up disk space, undo the last "
            "update, save problem details for your helper and more",
            "setup checklist - set up the microphone, media codecs, disk unlock, and see how to get apps"]

TOOL = "/usr/bin/easyspeak-os-tools"
PHRASES = re.compile(r"\bsystem tools?\b")
SETUP = re.compile(r"\bset ?up (the )?(checklist|computer)\b|\bwelcome (window|checklist)\b")


def handle(cmd, core):
    """Open System Tools, or its setup checklist, on their phrases; return None otherwise."""
    text = cmd.lower()
    if SETUP.search(text):
        args, words = [TOOL, "setup"], "Opening the setup checklist."
    elif PHRASES.search(text):
        args, words = [TOOL], "Opening System Tools."
    else:
        return None
    if not os.access(TOOL, os.X_OK):
        core.speak("System Tools is not available here.")
        return True
    core.speak(words)
    core.host_run(args, background=True, clean_env=True)
    return True
