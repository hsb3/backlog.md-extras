#!/usr/bin/env python3
"""Check hooks/<name>/config.json <-> hooks.json and codex-hooks.json agree, both ways,
that the Claude and Codex manifests carry one name and version, and that the Codex files keep to Codex's schema."""
import json
import sys
from pathlib import Path

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
CMD = '"${CLAUDE_PLUGIN_ROOT}/hooks/%s/hook.sh"'
# Codex tool names differ (apply_patch for file edits), so its entries match config.json's codexMatcher
CODEX_CMD = 'BACKLOG_EXTRAS_HARNESS=codex "${PLUGIN_ROOT}/hooks/%s/hook.sh"'
# No Codex validator exists; these sets are codex-rs config/src/hook_config.rs (HooksFile, MatcherGroup, the command
# handler) at rust-v0.163.0. Codex drops the whole file on an unknown top-level key and ignores unknown nested ones.
CODEX_EVENTS = {"PreToolUse", "PermissionRequest", "PostToolUse", "PreCompact", "PostCompact", "SessionStart",
                "SessionEnd", "UserPromptSubmit", "Stop", "SubagentStart", "SubagentStop", "Interrupt"}
CODEX_HANDLER_KEYS = {"type", "command", "commandWindows", "command_windows", "timeout", "statusMessage", "async", "additionalContextLimit"}
errs, dirs = [], 0


def codex_schema(p, doc):
    if set(doc) - {"description", "hooks"}:
        errs.append(f"{p}: codex-hooks.json has unknown top-level keys {sorted(set(doc) - {'description', 'hooks'})}")
    for ev, ms in doc["hooks"].items():
        if ev not in CODEX_EVENTS:
            errs.append(f"{p}: codex-hooks.json event {ev!r} is not a Codex hook event")
        for m in ms:
            if set(m) - {"matcher", "hooks"}:
                errs.append(f"{p}: codex-hooks.json {ev} group has unknown keys {sorted(set(m) - {'matcher', 'hooks'})}")
            for h in m.get("hooks", []):
                if h.get("type") != "command" or not isinstance(h.get("command"), str) or set(h) - CODEX_HANDLER_KEYS:
                    errs.append(f"{p}: codex-hooks.json {ev} handler is not a Codex command handler: {h!r}")


def check(p, reg, configs, cmd, label, matcher_key):
    for name, c in configs.items():
        entries = [h for m in reg.get(c.get("event"), []) if m.get("matcher") == c.get(matcher_key)
                   for h in m.get("hooks", [])]
        if not any(h.get("command") == cmd % name and h.get("timeout") == c.get("timeout")
                   and h.get("statusMessage") == c.get("statusMessage") for h in entries):
            errs.append(f"{p}/{name}: no {label} entry matching its config.json under {c.get('event')}")
    for ev, ms in reg.items():
        for m in ms:
            for h in m.get("hooks", []):
                if not any(h.get("command") == cmd % n for n in configs):
                    errs.append(f"{p}: {label} {ev} entry {h.get('command')!r} has no hook dir")


for hooks in [root / "hooks"] if (root / "hooks").is_dir() else []:
    p = "hooks"
    configs = {}
    for d in sorted(x for x in hooks.iterdir() if x.is_dir()):
        dirs += 1
        configs[d.name] = {}
        for f in ("config.json", "hook.sh", "test.sh"):
            if not (d / f).is_file():
                errs.append(f"{p}/{d.name}: missing {f}")
        try:
            configs[d.name] = json.loads((d / "config.json").read_text())
        except (OSError, ValueError):
            pass
    for label, cmd, matcher_key in (("hooks.json", CMD, "matcher"), ("codex-hooks.json", CODEX_CMD, "codexMatcher")):
        try:
            doc = json.loads((hooks / label).read_text())
            reg = doc["hooks"]
        except (OSError, ValueError, KeyError) as e:
            errs.append(f"{p}: {label} unreadable: {e!r}")
            continue
        check(p, reg, configs, cmd, label, matcher_key)
        if label == "codex-hooks.json":
            codex_schema(p, doc)
    try:
        codex = json.loads((hooks.parent / ".codex-plugin" / "plugin.json").read_text())
        if "interface" in codex and not isinstance(codex["interface"], dict):
            errs.append(f"{p}: .codex-plugin/plugin.json interface must be an object")
        if codex.get("hooks") != "./hooks/codex-hooks.json":
            errs.append(f"{p}: .codex-plugin/plugin.json does not point hooks at ./hooks/codex-hooks.json")
        # Codex takes component paths only as ./... below the plugin root, never "./"; requiring the key is this repo's rule
        v = codex.get("skills")
        if not (isinstance(v, str) and v.startswith("./") and v.rstrip("/") != "." and ".." not in v.split("/")
                and (hooks.parent / v).is_dir()):
            errs.append(f"{p}: .codex-plugin/plugin.json skills {v!r} is not an existing ./ dir in the plugin")
        manifests = [json.loads((hooks.parent / m / "plugin.json").read_text()) for m in (".claude-plugin", ".codex-plugin")]
        versions = {m["version"] for m in manifests}
        names = {m["name"] for m in manifests}
    except (OSError, ValueError, KeyError) as e:
        errs.append(f"{p}: manifest unreadable: {e!r}")
    else:
        if len(versions) != 1:
            errs.append(f"{p}: Claude and Codex manifest versions differ: {sorted(versions)}")
        if len(names) != 1:
            errs.append(f"{p}: Claude and Codex manifest names differ: {sorted(names)}")

for e in errs:
    print(e)
if not dirs:
    errs.append("no hook dirs found")
    print("no hook dirs found")
sys.exit(1 if errs else 0)
