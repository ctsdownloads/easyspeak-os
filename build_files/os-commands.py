"""Build step: list the EasySpeak-OS voice commands, read from the plugins themselves, for the help overlay,
the cheat sheet and "did you mean". Each plugin's COMMANDS lines read "what to say - what it does". They go in the
plugin's HELP_SECTION ("EasySpeak-OS" if it has none); HELP_SOFTWARE lines go in the "Software" section.

usage: os-commands.py PLUGINS_DIR OUT.json
"""
import importlib
import json
import sys
from pathlib import Path

plugins = Path(sys.argv[1])
sys.path.insert(0, str(plugins.parent))           # what EasySpeak's load_plugins() does
rows = []
ORDER = ["easyspeak_os_update", "easyspeak_os_tools", "easyspeak_os_apps", "easyspeak_os_dialogs"]   # how they are listed; others after
files = sorted(plugins.glob("easyspeak_os_*.py"), key=lambda f: (ORDER.index(f.stem) if f.stem in ORDER else 99, f.stem))
for f in files:
    module = importlib.import_module(f"plugins.{f.stem}")
    section = getattr(module, "HELP_SECTION", "EasySpeak-OS")
    lines = [(line, section) for line in getattr(module, "COMMANDS", [])]
    lines += [(line, "Software") for line in getattr(module, "HELP_SOFTWARE", [])]
    for line, sec in lines:
        say, _, does = line.partition(" - ")
        rows.append({"say": say.strip(), "does": does.strip(), "section": sec})
if not rows:
    sys.exit("no EasySpeak-OS commands found in " + str(plugins))
Path(sys.argv[2]).write_text(json.dumps(rows, ensure_ascii=False))
print(f"EasySpeak-OS commands: {len(rows)}")
