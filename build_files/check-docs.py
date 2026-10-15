#!/usr/bin/python3 -I
"""The build test that the README and the help keep up with the software.

1. The README's table of contents (between <!-- contents --> and <!-- /contents -->) lists every section and
   sub-section, in order, with the same words, and each link goes to its section.
2. Every link to a section inside the README (#...) goes to a section that exists.
3. Every button in the software windows (Install Package File, Remove Apps, Repair App Boxes, Start Apps at Login,
   System Tools) is named in the help's Software section, so it can be found by voice.

Run from the repository root:  python3 build_files/check-docs.py
"""
import ast
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors = []


def slug(text):
    """GitHub's anchor for a heading."""
    text = re.sub(r"[`*_]", "", text).strip().lower()
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


# ---------------------------------------------------------------- README
readme = (ROOT / "README.md").read_text().splitlines()
headings, anchors, seen, fence = [], set(), {}, False
for line in readme:
    if line.startswith("```"):
        fence = not fence
    if fence:
        continue
    m = re.match(r"^(#{2,3}) (.+?)\s*$", line)
    if m:
        text = m.group(2)
        a = slug(text)
        n = seen.get(a, 0)
        seen[a] = n + 1
        a = a if n == 0 else f"{a}-{n}"
        anchors.add(a)
        if text != "Contents":
            headings.append((len(m.group(1)), text, a))

try:
    first = readme.index("<!-- contents -->")
    last = readme.index("<!-- /contents -->")
except ValueError:
    errors.append("README.md has no table of contents between <!-- contents --> and <!-- /contents -->")
    first = last = 0
listed = []
for line in readme[first + 1:last]:
    if not line.strip():
        continue
    m = re.match(r"^( *)- \[(.+)\]\(#([^)]+)\)$", line)
    if not m:
        errors.append(f"README.md table of contents: not a contents line: {line!r}")
        continue
    listed.append((2 if m.group(1) == "" else 3, m.group(2), m.group(3)))

for i in range(max(len(headings), len(listed))):
    h = headings[i] if i < len(headings) else None
    t = listed[i] if i < len(listed) else None
    if h != t:
        want = f"{'  ' * (h[0] - 2)}- [{h[1]}](#{h[2]})" if h else "(nothing more)"
        got = f"{'  ' * (t[0] - 2)}- [{t[1]}](#{t[2]})" if t else "(nothing)"
        errors.append(f"README.md table of contents, line {i + 1}: should be {want}, is {got}")
        break

for line in readme:
    for a in re.findall(r"\]\(#([^)]+)\)", line):
        if a not in anchors:
            errors.append(f"README.md links to a section that does not exist: #{a}")

# ---------------------------------------------------------------- help: every window button
TOOLS = ["easyspeak-os-packages", "easyspeak-os-tools"]
trees = [ast.parse((ROOT / "build_files" / t).read_text()) for t in TOOLS]


def strings(node, names):
    """The button words a value can be: a string, either side of an 'x if c else y', or a variable set to one."""
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return {node.value}
    if isinstance(node, ast.IfExp):
        return strings(node.body, names) | strings(node.orelse, names)
    if isinstance(node, ast.Name):
        return names.get(node.id, set())
    return set()


buttons = {"Yes", "Cancel"}          # ask()'s own defaults
for fn in (n for tree in trees for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)):
    names = {}
    for n in ast.walk(fn):
        if isinstance(n, ast.Assign) and len(n.targets) == 1 and isinstance(n.targets[0], ast.Name):
            names.setdefault(n.targets[0].id, set()).update(strings(n.value, {}))
    for n in ast.walk(fn):
        if not (isinstance(n, ast.Call) and isinstance(n.func, ast.Name)):
            continue
        if n.func.id == "ask":
            for k in n.keywords:
                if k.arg in ("ok", "cancel", "extra"):
                    buttons |= strings(k.value, names)
        if n.func.id == "failed":
            for k in n.keywords:
                if k.arg == "offer" and isinstance(k.value, ast.Tuple):
                    buttons |= strings(k.value.elts[0], names)

dialogs = ast.parse((ROOT / "build_files" / "easyspeak_os_dialogs.py").read_text())
help_lines = next(ast.literal_eval(n.value) for n in dialogs.body
                  if isinstance(n, ast.Assign) and getattr(n.targets[0], "id", "") == "HELP_SOFTWARE")
said = set()
for line in help_lines:
    said |= {w.strip().lower() for w in line.split(" - ")[0].split("/")}
missing = sorted(b for b in buttons if b.lower() not in said)
if missing:
    errors.append("The help's Software section does not name these window buttons: " + ", ".join(missing))

if errors:
    print("\n".join("ERROR: " + e for e in errors))
    sys.exit(1)
print(f"README contents: {len(headings)} sections, all listed and linked. Help: all {len(buttons)} window buttons named.")
