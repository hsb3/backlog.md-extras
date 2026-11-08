---
id: TASK-1
title: Restructure repo as marketplace with one backlog-extras plugin
status: Done
assignee:
  - '@claude'
created_date: 2026-10-18 18:50
updated_date: '2026-11-08T20:39:00Z'
labels: []
milestone: m-0
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Spec section 3: everything ships as one Claude Code plugin so a consumer project gets bl and the hooks by enabling it, with no per-machine hook install. bl moves into the plugin bin/ (Claude Code puts it on the agent shell PATH).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 .claude-plugin/marketplace.json (name backlog-md-extras) lists plugins/backlog-extras; plugin.json holds the only version field
- [x] #2 bl lives only at plugins/backlog-extras/bin/bl; install.sh (checkout and piped) installs it from there
- [x] #3 backlog-guard hook dir has config.json, hook.sh, test.sh and is registered in hooks.json; scripts/check_hook_layout.py fails on any mismatch
- [x] #4 gate.sh runs claude plugin validate --strict on the marketplace and the plugin
- [x] #5 A live claude -p run with the plugin loaded finds bl on PATH
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. git mv bin/bl and hooks/backlog-cli-only into plugins/backlog-extras/{bin,hooks/backlog-guard}; move tests/hooktest.sh to the hook dir as test.sh.
2. Add marketplace.json, plugin.json, hooks.json.
3. Port a sibling repo's check_hook_layout.py for hook.sh/test.sh.
4. Point install.sh, check_install.sh, gate.sh at new paths; add plugin validate steps.
5. Live check: claude -p --plugin-dir with Bash allowed runs command -v bl.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
gate.sh all PASS (pin, selftest 22/22, backlog-guard test 29/29, hook layout, installer checkout+piped, plugin validate --strict on marketplace and plugin, shellcheck).
Layout check watched red on a broken copy in both directions (config.json without matching hooks.json entry; hooks.json entry without hook dir; dir missing files).
Live: claude -p --plugin-dir puts plugins/backlog-extras/bin on PATH but APPENDED (position 35 here), so a terminal copy of bl earlier on PATH wins. With the local bin dir removed from PATH, command -v bl resolved to the plugin copy and bl --version printed 1.53.0. Follow-up in TASK-3: session doctor warns when the bl on PATH is not the plugin copy and differs from it.
The terminal installer no longer ships the hook command; the plugin supplies hooks. validate advises adding the one-step /plugin install line to the README (TASK-4 docs pass).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Repo is now a marketplace (backlog-md-extras) with one plugin (backlog-extras) carrying bl in bin/ and the backlog-guard hook; the installer, checks and gate follow the new layout, and gate adds strict manifest validation and a hook layout check. Verified by gate.sh and two live claude -p runs.
<!-- SECTION:FINAL_SUMMARY:END -->
