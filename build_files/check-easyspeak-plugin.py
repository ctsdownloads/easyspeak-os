"""Build test: load the EasySpeak-OS plugin exactly the way EasySpeak loads its plugins, and try it."""
import importlib, sys
from pathlib import Path

plugins_dir = Path(sys.argv[1])
sys.path.insert(0, str(plugins_dir.parent))           # what EasySpeak's load_plugins() does
module = importlib.import_module("plugins.easyspeak_os_update")
assert hasattr(module, "NAME") and hasattr(module, "handle"), "missing NAME or handle"


class Core:
    def __init__(self):
        self.calls = []

    def speak(self, text):
        self.calls.append("speak")

    def host_run(self, cmd, background=False, clean_env=False):
        self.calls.append("run")


core = Core()
assert module.handle("update system", core) is True and "run" in core.calls, "does not start the update"
assert module.handle("open browser", Core()) is None, "takes commands that are not its own"
print("update plugin loads and works")
