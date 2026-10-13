"""Build test for Install Package File: read four real Fedora packages and check what it says they need."""
import json, subprocess, sys
from pathlib import Path

folder = Path(sys.argv[1])
def check(name):
    f = next(folder.glob(f"{name}-[0-9]*.rpm"))
    out = subprocess.run(["python3", "-I", "/usr/bin/easyspeak-os-packages", "check", str(f)],
                         capture_output=True, text=True, check=True).stdout
    return json.loads(out)

mines = check("gnome-mines")
assert mines["apps"] and not mines["needs_system"], f"gnome-mines should go in a box: {mines}"
vpn = check("openvpn")
assert "a background service that starts with the computer" in vpn["needs_system"], f"openvpn: {vpn}"
rules = check("solaar-udev")
assert rules["rules_only"] and rules["rules"], f"solaar-udev should be a hardware rule only: {rules}"
source = check("fedora-repos-archive")
assert source["source_only"] and source["sources"] and not source["apps"], \
    f"fedora-repos-archive only adds a download source: {source}"
print("Install Package File reads packages correctly")
