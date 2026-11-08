---
id: TASK-6
title: 'Codex support: same plugin as a Codex plugin'
status: Done
assignee:
  - '@claude'
created_date: 2026-10-20 00:31
updated_date: '2026-11-08T20:39:00Z'
labels: []
dependencies: []
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Ship backlog-extras to Codex from the same plugin dir: .codex-plugin/plugin.json and hooks/codex-hooks.json (BACKLOG_EXTRAS_HARNESS=codex). Codex reads .claude-plugin/marketplace.json, has no CLAUDE_ENV_FILE and no plugin bin/ on PATH, and edits files with apply_patch. Spec decision 7.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 backlog-guard denies apply_patch whose Add/Update/Delete/Move-to headers name a path in the backlog folder
- [x] #2 session-doctor under Codex writes nothing, gives no CLAUDE_ENV_FILE warning, and names the wrapper by full path
- [x] #3 check_hook_layout.py checks codex-hooks.json both ways and that both manifests carry one version; each new check watched failing
- [x] #4 Version 0.3.0 in both manifests; ./gate.sh passes; live codex exec (0.162.1, isolated CODEX_HOME) shows guidance, both denials and wrapper decision view
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Live run log: (local log) codex-live-0.3.0-2026-10-19.jsonl. Real /hooks trust flow, SSH marketplace install and marketplace upgrade not exercised.

PR #1 review fixes: walk up from cwd when CLAUDE_PROJECT_DIR is unset (Codex in a subdirectory), apply_patch header check on Bash heredocs and on every string of tool_input, codexMatcher compared in the layout check, Codex manifest hooks field checked. Live rerun from a subdirectory: guidance received, apply_patch and rm denied (codex-live-subdir-2026-10-19.jsonl). Deferred: TASK-9 (case), TASK-10 (workdir).
<!-- SECTION:NOTES:END -->
