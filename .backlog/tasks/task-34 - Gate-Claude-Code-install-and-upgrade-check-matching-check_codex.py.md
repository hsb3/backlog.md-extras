---
id: TASK-34
title: 'Gate: Claude Code install and upgrade check matching check_codex.py'
status: To Do
assignee: []
created_date: '2026-10-24T18:50:00Z'
updated_date: '2026-10-24T18:51:00Z'
labels: []
dependencies: []
priority: medium
type: chore
ordinal: 34000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
scripts/check_codex.py installs and upgrades the real plugin with Codex in an isolated HOME and CODEX_HOME. The Claude Code side only runs the strict marketplace and plugin validators, so a Claude install or upgrade regression passes the gate. Bring the scripts/ checks to parity across both harnesses (scope confirmed by the owner 2026-10-24).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An audit table in the PR lists each scripts/ check and whether it covers Claude Code, Codex or both; every one-sided gap is closed or justified in one line.
- [ ] #2 A Claude Code lifecycle check installs the plugin from a local marketplace copy with an isolated HOME and Claude config dir, confirms the installed wrapper, skill, hooks and requirements bytes, upgrades to a bumped version and confirms the new files, and rejects a malformed manifest.
- [ ] #3 It needs no model call or account and never touches the live Claude Code config; gate.sh runs it on macOS and Linux CI.
- [ ] #4 Each new check is observed failing against a deliberately broken disposable copy.
<!-- AC:END -->
