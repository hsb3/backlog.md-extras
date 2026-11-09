#!/usr/bin/env python3
"""The hand-written command tables (README `## Commands`, doc-1 section 4) name exactly the wrapper's COMMANDS rows, in order;
the plugin skill lists each of them with the wrapper's summary, and no other `backlog ...` bullet, in at most SKILL_MAX_LINES lines.

Usage: check_commands.py [--readme P] [--doc P] [--skill P] [--wrapper P]  (defaults: this repo's)
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL_MAX_LINES = 150


def table_commands(text, heading):
    """Backticked `backlog ...` first cells of the table under heading, or None when the section is missing."""
    m = re.search(rf"^{re.escape(heading)}\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    return re.findall(r"^\| `(backlog [^`]*)` \|", m.group(1), re.M) if m else None


def wrapper_rows(wrapper):
    """(`backlog <usage>`, summary) per COMMANDS row."""
    out = subprocess.run([sys.executable, str(wrapper), "--backlog-extras-commands"],
                         capture_output=True, text=True, check=True).stdout
    return [(f"backlog {u}", s) for u, s in (line.split("\t", 1) for line in out.splitlines())]


def compare(path, heading, want):
    have = table_commands(path.read_text(), heading)
    if have is None:
        print(f"FAIL {path}: no `{heading}` section")
        return 1
    if have == want:
        return 0
    print(f"FAIL {path} `{heading}` table disagrees with the wrapper's COMMANDS table")
    for c in want:
        if c not in have:
            print(f"  missing: {c}")
    for c in have:
        if c not in want:
            print(f"  not in the wrapper: {c}")
    if sorted(have) == sorted(want):
        print("  same rows, different order")
    return 1


def mentions(path, rows):
    if not path.is_file():
        print(f"FAIL {path}: missing")
        return 1
    lines = path.read_text().splitlines()
    bad = [(c, s) for c, s in rows if f"- `{c}`: {s}." not in lines]
    for c, s in bad:
        print(f"FAIL {path} omits `{c}` with its summary: {s}")
    # a bullet of the form "- `backlog <usage>`: <summary>" is a wrapper-row line; upstream commands never take that form
    known = {c for c, _ in rows}
    stale = [m.group(1) for m in map(re.compile(r"\s*(?:[-*+]|\d+[.)])\s+\**`(backlog [^`]*)`: ").match, lines) if m and m.group(1) not in known]
    for c in stale:
        print(f"FAIL {path} lists `{c}`, which is not in the wrapper's COMMANDS table")
    if len(lines) > SKILL_MAX_LINES:
        print(f"FAIL {path} has {len(lines)} lines, over the {SKILL_MAX_LINES}-line limit")
    return 1 if bad or stale or len(lines) > SKILL_MAX_LINES else 0


def main(argv):
    p = argparse.ArgumentParser()
    p.add_argument("--readme", type=Path, default=ROOT / "README.md")
    p.add_argument("--doc", type=Path, default=next(ROOT.glob(".backlog/docs/doc-1 - *.md"), None))
    p.add_argument("--skill", type=Path, default=ROOT / "skills/backlog-md/SKILL.md")
    p.add_argument("--wrapper", type=Path, default=ROOT / "bin/backlog")
    a = p.parse_args(argv)
    if a.doc is None:
        print("FAIL no doc-1 under .backlog/docs")
        return 1
    rows = wrapper_rows(a.wrapper)
    want = [c for c, _ in rows]
    return compare(a.readme, "## Commands", want) | compare(a.doc, "## 4. Wrapper commands", want) | mentions(a.skill, rows)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
