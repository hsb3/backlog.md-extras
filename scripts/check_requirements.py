#!/usr/bin/env python3
"""Keep host manifests, installer and CI copies in sync with requirements.json."""
import json
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
plugin = root
r = json.loads((plugin / "requirements.json").read_text())
errors = []
for folder in (".claude-plugin", ".codex-plugin"):
    manifest = json.loads((plugin / folder / "plugin.json").read_text())
    if manifest["version"] != r["pluginVersion"]:
        errors.append(f"{folder} version differs from requirements.json")
    interface = manifest.get("interface", {})
    for key in ("composerIcon", "logo"):
        if key in interface:
            asset = (plugin / interface[key]).resolve()
            if plugin.resolve() not in asset.parents or not asset.is_file():
                errors.append(f"{folder} {key} is not an asset inside the plugin")
wrapper = (plugin / "bin/backlog").read_text()
if not re.search(r'^BACKLOG_VERSION = "' + re.escape(r["pins"]["backlog.md"]) + '"', wrapper, re.M):
    errors.append("wrapper BACKLOG_VERSION differs from requirements.json")
tested = r["tested"]["backlog.md"]
if len(set(tested)) != len(tested):
    errors.append("the tested Backlog.md list repeats a release")
if r["pins"]["backlog.md"] not in tested:
    errors.append("the Backlog.md pin is not in the tested list")
if f"BACKLOG_TESTED = ({', '.join(chr(34) + v + chr(34) for v in tested)})\n" not in wrapper:
    errors.append("wrapper BACKLOG_TESTED differs from requirements.json")
installer = (root / "install.sh").read_text()
if f'release={r["pluginVersion"]}\n' not in installer:
    errors.append("installer release differs from requirements.json")
workflow = (root / ".github/workflows/tests.yml").read_text()
uses = set(re.findall(r"^\s*- uses:\s*(\S+)", workflow, re.M))
if uses != {f"{action}@{ref}" for action, ref in r["actions"].items()}:
    errors.append("CI action references must exactly match requirements.json")
for tool in ("node", "python"):
    if f"{tool}-version: '{r['ci'][tool]}'" not in workflow:
        errors.append(f"CI {tool} version differs from requirements.json")
matrix = re.search(r"^\s*os:\s*\[([^]]+)\]", workflow, re.M)
if not matrix or [value.strip(" '\"") for value in matrix[1].split(",")] != r["ci"]["runners"]:
    errors.append("CI runners differ from requirements.json")
for error in errors:
    print(f"FAIL: {error}")
sys.exit(bool(errors))
