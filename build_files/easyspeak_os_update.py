"""EasySpeak-OS: start a system update by voice.

Shipped by the EasySpeak-OS image, not by EasySpeak. "Update system" (or "system update", "install updates",
"check for updates") opens the same System Update window as the app grid: it updates the system, Flatpak apps,
Distrobox containers and Homebrew, shows each step, and offers a restart when a new system image is ready.
English phrases only.
"""

import os
import re

NAME = "easyspeak-os update"
DESCRIPTION = "Start a system update (EasySpeak-OS)"
COMMANDS = ["update system - update the system, apps and boxes (also: install updates, check for updates)"]

UPDATER = "/usr/bin/easyspeak-os-update"
PHRASES = re.compile(
    r"\b(update (the )?(system|computer|everything)|system update|install (the )?updates|check for updates)\b"
)


def handle(cmd, core):
    """Open the System Update window on an update phrase; return None otherwise."""
    if not PHRASES.search(cmd.lower()):
        return None
    if not os.access(UPDATER, os.X_OK):
        core.speak("System update is not available here.")
        return True
    core.speak("Starting the system update.")
    core.host_run([UPDATER], background=True, clean_env=True)
    return True
