"""Build test: load the EasySpeak-OS plugins exactly the way EasySpeak loads its plugins, and try them."""
import importlib, sys
from pathlib import Path

plugins_dir = Path(sys.argv[1])
sys.path.insert(0, str(plugins_dir.parent))           # what EasySpeak's load_plugins() does


class Core:
    def __init__(self):
        self.calls = []

    def speak(self, text):
        self.calls.append("speak")

    def host_run(self, cmd, background=False, clean_env=False):
        self.calls.append(cmd)


# plugin: (phrases it must take, with the command each starts; phrases it must leave alone)
TESTS = {
    "easyspeak_os_update": ({"update system": "/usr/bin/easyspeak-os-update",
                             "install updates": "/usr/bin/easyspeak-os-update"},
                            ["open browser", "install a package"]),
    "easyspeak_os_apps": ({"install a package": "install", "install an app from a file": "install",
                           "uninstall an app": "remove", "remove a program": "remove",
                           "repair app boxes": "repair", "fix the box": "repair"},
                          ["install updates", "open browser", "update system", "remove word"]),
}
for name, (takes, leaves) in TESTS.items():
    module = importlib.import_module(f"plugins.{name}")
    assert hasattr(module, "NAME") and hasattr(module, "handle"), f"{name}: missing NAME or handle"
    for phrase, expect in takes.items():
        core = Core()
        assert module.handle(phrase, core) is True, f"{name}: does not take '{phrase}'"
        runs = [c for c in core.calls if isinstance(c, list)]
        assert runs and expect in runs[0], f"{name}: '{phrase}' does not start {expect}"
    for phrase in leaves:
        assert module.handle(phrase, Core()) is None, f"{name}: takes '{phrase}', which is not its own"
    print(f"{name} loads and works")
