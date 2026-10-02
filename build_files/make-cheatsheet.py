#!/usr/bin/env python3
"""Turns EasySpeak's commands.md into a one-page offline cheat sheet (HTML).

usage: make-cheatsheet.py COMMANDS.md OUT.html VERSION
Only the Python standard library is used.
"""
import html
import json
import os
import re
import sys


def clean(text):
    text = re.sub(r"\[\^[^\]]+\]", "", text)           # footnote markers
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)  # links keep their text
    text = text.replace("**", "").replace("`", "")
    return text.strip()


def expand(cell):
    """'volume up/down (or louder / quieter)' -> ['volume up', 'volume down', 'louder', 'quieter']"""
    extra = []
    m = re.search(r"\(or ([^)]*)\)", cell)
    if m:
        extra = [x.strip() for x in m.group(1).split("/")]
        cell = (cell[:m.start()] + cell[m.end():]).strip()
    alts = [a.strip() for a in cell.split(" / ")]
    first = alts[0].split()
    verb = first[0] if first and first[0] in ("open", "close") else None
    out = []
    for i, alt in enumerate(alts):
        if verb and i > 0 and alt.split() and alt.split()[0] != verb:
            alt = verb + " " + alt                    # the verb carries over to later alternatives
        variants = [[]]
        for w in alt.split():
            opts = w.split("/") if "/" in w else [w]
            variants = [v + [o] for v in variants for o in opts]
        out += [" ".join(v) for v in variants]
    return [x for x in out + extra if x]


def parse(md):
    cards, section, sub, i = [], "", "", 0
    lines = md.splitlines()
    sep = re.compile(r"^\|[\s:|-]+\|$")
    while i < len(lines):
        line = lines[i].rstrip()
        if line.startswith("## "):
            section, sub = clean(line[3:]), ""
        elif line.startswith("### "):
            sub = clean(line[4:])
        elif line.startswith("|") and i + 1 < len(lines) and sep.match(lines[i + 1].strip()):
            rows, i = [], i + 2
            while i < len(lines) and lines[i].startswith("|"):
                cells = [clean(c) for c in lines[i].strip().strip("|").split("|")]
                if cells and cells[0]:
                    rows.append((cells[0], " ".join(cells[1:])))
                i += 1
            if rows:
                title = f"{section}: {sub}" if sub else section
                cards.append((title, rows))
            continue
        i += 1
    return cards


PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>EasySpeak commands</title>
<style>
  :root {{ color-scheme: light dark; --bg: #ffffff; --fg: #111111; --card: #f3f3f3;
          --line: #cccccc; --accent: #8a6d00; }}
  @media (prefers-color-scheme: dark) {{
    :root {{ --bg: #16161a; --fg: #f2f2f2; --card: #202026; --line: #3a3a44; --accent: #ffd60a; }}
  }}
  body {{ margin: 0; padding: 1.5rem; background: var(--bg); color: var(--fg);
         font: 18px/1.45 system-ui, sans-serif; }}
  h1 {{ margin: 0 0 .25rem; font-size: 1.7rem; }}
  .intro {{ margin: 0 0 1rem; max-width: 60rem; }}
  .intro b {{ color: var(--accent); }}
  input {{ font: inherit; padding: .5rem .75rem; width: min(100%, 24rem); margin-bottom: 1rem;
          background: var(--card); color: var(--fg); border: 2px solid var(--line); border-radius: .5rem; }}
  .grid {{ columns: 22rem; column-gap: 1rem; }}
  .card {{ break-inside: avoid; background: var(--card); border: 1px solid var(--line);
          border-radius: .75rem; padding: .75rem 1rem; margin: 0 0 1rem; }}
  h2 {{ margin: 0 0 .5rem; font-size: 1.1rem; color: var(--accent); }}
  table {{ border-collapse: collapse; width: 100%; }}
  td {{ padding: .2rem .4rem .2rem 0; vertical-align: top; border-top: 1px solid var(--line); }}
  td:first-child {{ font-weight: 600; width: 45%; }}
  footer {{ margin-top: 1rem; font-size: .9rem; opacity: .8; }}
  .hidden {{ display: none; }}
  details > summary {{ list-style: none; cursor: pointer; }}
  details > summary::-webkit-details-marker {{ display: none; }}
  summary h2 {{ display: flex; justify-content: space-between; margin: 0; }}
  summary h2::after {{ content: "\\25B8"; opacity: .7; }}
  details[open] > summary h2::after {{ content: "\\25BE"; }}
  details[open] > summary h2 {{ margin-bottom: .5rem; }}
  .count {{ font-weight: normal; opacity: .7; font-size: .9rem; margin-left: .5rem; }}
  .more {{ margin: 1.25rem 0 .5rem; font-size: 1rem; opacity: .8; }}
</style>
</head>
<body>
<h1>EasySpeak commands</h1>
<p class="intro">Say <b>&ldquo;Hey Jarvis&rdquo;</b>, wait for the chime, then say a command.
After a command you can keep going without the wake word until it goes quiet.
Say <b>&ldquo;help&rdquo;</b> to print this list in a terminal.
Yellow dot = go ahead and speak, orange = busy, no dot = say the wake word.</p>
<input id="q" type="search" placeholder="Type to filter commands" aria-label="Filter commands" autofocus>
<div class="grid">
{cards}
</div>
<p class="more">{more_note}</p>
<div class="grid">
{more}
</div>
<footer>Generated from the EasySpeak {version} documentation when the image was built.
Full docs: https://easyspeak.dev/</footer>
<script>
  const q = document.getElementById('q');
  q.addEventListener('input', () => {{
    const t = q.value.trim().toLowerCase();
    document.querySelectorAll('.card').forEach(card => {{
      let any = false;
      if (!('wasOpen' in card.dataset)) card.dataset.wasOpen = card.open ? '1' : '';
      card.querySelectorAll('tr').forEach(tr => {{
        const hit = !t || tr.textContent.toLowerCase().includes(t);
        tr.classList.toggle('hidden', !hit);
        any = any || hit;
      }});
      card.classList.toggle('hidden', !any);
      card.open = t ? any : card.dataset.wasOpen === '1';
    }});
  }});
</script>
</body>
</html>
"""


# Everyday commands first; anything not listed keeps the document's order after them.
FIRST = ("General", "Apps", "Files", "Media", "System")


def order(cards):
    rank = lambda title: next((i for i, n in enumerate(FIRST) if title == n), len(FIRST))
    return sorted(cards, key=lambda c: rank(c[0]))   # sorted() is stable


def card_html(title, rows, is_open):
    body = "\n".join(
        f"<tr><td>{html.escape(say)}</td><td>{html.escape(does)}</td></tr>"
        for say, does in rows)
    return (f'<details class="card"{" open" if is_open else ""}><summary><h2>'
            f'<span>{html.escape(title)}<span class="count">{len(rows)}</span></span></h2></summary>'
            f"<table>\n{body}\n</table></details>")


def render(cards, version):
    cards = order(cards)
    everyday = [card_html(t, r, True) for t, r in cards if t in FIRST]
    more = [card_html(t, r, False) for t, r in cards if t not in FIRST]
    return PAGE.format(cards="\n".join(everyday), more="\n".join(more),
                       more_note="More commands, for when you use these modes (tap to open):",
                       version=html.escape(version))


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    md_path, out_path, version = sys.argv[1:]
    cards = parse(open(md_path, encoding="utf-8").read())
    if len(cards) < 5 or sum(len(r) for _, r in cards) < 50:
        sys.exit(f"cheat sheet: only {len(cards)} sections found, the doc format may have changed")
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(render(cards, version))
    ordered = order(cards)
    sections = [{"title": title, "say": [say for say, _ in rows]} for title, rows in ordered]
    with open(os.path.join(os.path.dirname(out_path) or ".", "cheatsheet.json"), "w", encoding="utf-8") as f:
        json.dump(sections, f, ensure_ascii=False)
    phrases = [{"phrase": p.lower(), "section": title}
               for title, rows in cards for say, _ in rows for p in expand(say)]
    with open(os.path.join(os.path.dirname(out_path) or ".", "commands.json"), "w", encoding="utf-8") as f:
        json.dump(phrases, f, ensure_ascii=False)
    print(f"cheat sheet: {len(cards)} sections, {sum(len(r) for _, r in cards)} commands -> {out_path}")


if __name__ == "__main__":
    main()
