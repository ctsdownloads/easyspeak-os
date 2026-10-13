"""EasySpeak-OS: install an app from an .rpm or .deb file, remove one, or repair the app boxes, by voice.

Shipped by the EasySpeak-OS image, not by EasySpeak. "Install a package" opens Install Package File, which lists
the .rpm and .deb files in Downloads. "Remove an app" opens Remove Apps. "Repair app boxes" opens Repair App
Boxes. Apps go into, and come out of, a box (Distrobox); the window says first if a file needs the system itself.
English phrases only.
"""

import os
import re

NAME = "easyspeak-os apps"
DESCRIPTION = "Install apps from .rpm and .deb files, or remove them (EasySpeak-OS)"
COMMANDS = [
    "install a package - install an app from an .rpm or .deb file",
    "remove an app - remove an app installed from a file",
    "repair app boxes - set a broken app box up again",
]

TOOL = "/usr/bin/easyspeak-os-packages"
THING = r"(package|program|app|application|rpm|deb)( file)?s?"
INSTALL = re.compile(rf"\binstall (an? |the )?{THING}\b|\binstall (it )?from (an? |the )?file\b")
REMOVE = re.compile(rf"\b(remove|uninstall) (an? |the )?{THING}\b")
REPAIR = re.compile(r"\b(repair|fix) (the |my )?(app )?box(es)?\b")


def handle(cmd, core):
    """Open Install Package File, Remove Apps or Repair App Boxes on their phrases; return None otherwise."""
    text = cmd.lower()
    if INSTALL.search(text):
        action, words = "install", "Opening Install Package File."
    elif REMOVE.search(text):
        action, words = "remove", "Opening Remove Apps."
    elif REPAIR.search(text):
        action, words = "repair", "Opening Repair App Boxes."
    else:
        return None
    if not os.access(TOOL, os.X_OK):
        core.speak("Installing from files is not available here.")
        return True
    core.speak(words)
    core.host_run([TOOL, action], background=True, clean_env=True)
    return True
