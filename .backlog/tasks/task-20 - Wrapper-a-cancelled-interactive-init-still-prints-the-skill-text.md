---
id: TASK-20
title: 'Wrapper: a cancelled interactive init still prints the skill text'
status: Done
assignee: []
created_date: '2026-10-21T09:26:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels:
  - hardening
dependencies: []
priority: low
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the 0.4.0 review. init() in plugins/backlog-extras/bin/backlog:251 prints the skill when upstream exits 0, and upstream exits 0 when the interactive prompt is cancelled. Repro: `backlog init` in a terminal, cancel at the first prompt.

Impact on goal: doc-1 goal 1; no misleading output after a cancelled init.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 After a cancelled interactive init (no config.yml created), no skill text is printed; a pseudo-terminal selftest case covers it, watched failing first
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Watched failing: tests/selftest.sh against a copy of the working-tree plugin dir taken before the edit (SELFTEST_BL) exited 1 with exactly one failure: FAIL cancelled interactive init (rc=0): output ended with the skill text (Ctrl-C typed at the first prompt in a pseudo-terminal). Log: (local log) task-20-selftest-prechange.log. After: tests/selftest.sh rc 0, 124 ok lines, no FAIL; the interactive and --defaults init cases still print the skill. Log: (local log) task-20-selftest-after.log. Change: init() prints the skill only when upstream exits 0 and the st_mtime_ns of <start>/backlog.config.yml or <start>/*/config.yml changed or appeared during the run. Mtimes, not bytes: upstream's init demo --defaults re-run in an existing project rewrites backlog/config.yml with identical bytes and a new mtime (checked by hand), so the skill still prints on a re-run.

Review follow-up: dropped the shortcut comment about a nested --backlog-dir (a/b): upstream 1.55.0 writes backlog.config.yml at the root for every custom dir (verified: init demo --defaults --backlog-dir a/b writes ./backlog.config.yml), so the root-config stamp covers it; doc-1 section 4 says so.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
init prints the skill only when upstream exits 0 and a config file it writes (backlog.config.yml in the init dir or */config.yml one level down) appeared or got a new mtime; Ctrl-C at the first prompt (upstream rc 0, nothing written) prints nothing. Pseudo-terminal selftest case, watched failing (task-20-selftest-prechange.log), passing after (task-20-selftest-after.log).
<!-- SECTION:FINAL_SUMMARY:END -->
