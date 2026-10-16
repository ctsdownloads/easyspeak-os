"""Build test: load the EasySpeakOS plugins exactly the way EasySpeak loads its plugins, and try them."""
import importlib, json, os, sys, tempfile
from pathlib import Path

os.environ["XDG_RUNTIME_DIR"] = tempfile.mkdtemp()     # the dialogs plugin looks for open windows here

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
                           "repair app boxes": "repair", "fix the box": "repair",
                           "start apps at login": "login", "apps at startup": "login"},
                          ["install updates", "open browser", "update system", "remove word", "log out"]),
    "easyspeak_os_tools": ({"system tools": "/usr/bin/easyspeak-os-tools",
                            "open system tools": "/usr/bin/easyspeak-os-tools",
                            "setup checklist": "setup", "set up the computer": "setup"},
                           ["update system", "open settings", "install a package", "open browser", "set up"]),
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

# The dialogs plugin: it takes nothing while no EasySpeakOS window is open, and presses a window's button by name.
dialogs = importlib.import_module("plugins.easyspeak_os_dialogs")
assert dialogs.handle("cancel", Core()) is None, "dialogs plugin takes words while no window is open"
folder = Path(dialogs.DIALOGS)
folder.mkdir(parents=True, exist_ok=True)
(folder / f"{os.getpid()}.json").write_text(json.dumps({
    "pid": os.getpid(), "time": 1, "text": "Install Discord?", "rows": [],
    "buttons": [{"say": "Set up and install", "does": "ok"}, {"say": "Cancel", "does": "cancel"}]}))
assert dialogs.handle("open browser", Core()) is None, "dialogs plugin takes words that are not a button"
assert dialogs.handle("set up and install", Core()) is True, "dialogs plugin does not press a button by name"
assert (folder / f"{os.getpid()}.answer").read_text() == "ok", "dialogs plugin pressed the wrong button"
# Apostrophes and "do not" don't matter; "next" goes on only when the main button just moves forward.
(folder / f"{os.getpid()}.answer").unlink()
(folder / f"{os.getpid()}.json").write_text(json.dumps({
    "pid": os.getpid(), "time": 1, "text": "Welcome.", "rows": [],
    "buttons": [{"say": "Start", "does": "ok"}, {"say": "Later", "does": "cancel"},
                {"say": "Don't show again", "does": "extra:Don't show again"}]}))
assert dialogs.handle("do not show again", Core()) is True and \
    (folder / f"{os.getpid()}.answer").read_text() == "extra:Don't show again", "'do not show again' not pressed"
(folder / f"{os.getpid()}.answer").unlink()
assert dialogs.handle("next", Core()) is True and \
    (folder / f"{os.getpid()}.answer").read_text() == "ok", "'next' does not press Start"
(folder / f"{os.getpid()}.answer").unlink()
(folder / f"{os.getpid()}.json").write_text(json.dumps({
    "pid": os.getpid(), "time": 1, "text": "Turn off?", "rows": [],
    "buttons": [{"say": "Turn off", "does": "ok"}, {"say": "Keep it on", "does": "cancel"}]}))
assert dialogs.handle("next", Core()) is None, "'next' pressed a button that changes something"
# Spacing doesn't matter: the live USB's "Install EasySpeakOS" button, said as separate words.
(folder / f"{os.getpid()}.json").write_text(json.dumps({
    "pid": os.getpid(), "time": 1, "text": "Welcome to EasySpeakOS.", "rows": [],
    "buttons": [{"say": "Install EasySpeakOS", "does": "ok"}, {"say": "Try it first", "does": "cancel"}]}))
assert dialogs.handle("install easy speak os", Core()) is True and \
    (folder / f"{os.getpid()}.answer").read_text() == "ok", "'install easy speak os' does not press Install EasySpeakOS"
(folder / f"{os.getpid()}.answer").unlink()
assert dialogs.handle("try it first", Core()) is True and \
    (folder / f"{os.getpid()}.answer").read_text() == "cancel", "'try it first' not pressed"
(folder / f"{os.getpid()}.answer").unlink()
# A list window from easyspeak-os-dialog: its lines are named by their name, not by the visible number column
dialog = Path(sys.argv[2]) if len(sys.argv) > 2 else None
if dialog:
    import importlib.machinery
    dlg = importlib.machinery.SourceFileLoader("dialog", str(dialog)).load_module()
    info = dlg.describe(["--list", "--print-column=1", "--hide-column=1", "--column=n", "--column=No.",
                         "--column=App", "--column=Installed in"],
                        ["0", "1", "Google Chrome", "Flathub", "1", "2", "Discord", "Ubuntu box"])
    assert [r["say"] for r in info["rows"]] == ["Google Chrome", "Discord"], f"list lines named wrong: {info['rows']}"
    (folder / f"{os.getpid()}.answer").unlink(missing_ok=True)
    (folder / f"{os.getpid()}.json").write_text(json.dumps({**info, "pid": os.getpid(), "time": 2}))
    assert dialogs.handle("number two", Core()) is True and \
        (folder / f"{os.getpid()}.answer").read_text() == "row:1", "'number two' does not pick line 2"
    (folder / f"{os.getpid()}.answer").unlink()
    assert dialogs.handle("discord", Core()) is True and \
        (folder / f"{os.getpid()}.answer").read_text() == "row:1", "a line's name does not pick it"
print("easyspeak_os_dialogs loads and works")
