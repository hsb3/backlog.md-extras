---
id: TASK-25
title: 'Gate: flag skill lines for commands no longer in the wrapper table'
status: Done
assignee: []
created_date: '2026-10-21T12:12:00Z'
updated_date: '2026-10-21T13:41:00Z'
labels:
  - hardening
dependencies: []
priority: low
ordinal: 25000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the 0.4.2 build. scripts/check_commands.py fails when SKILL.md lacks a row of the wrapper's command table, but not when SKILL.md still lists a command the table has dropped, so a removed command can stay advertised to agents.

Impact on goal: doc-1 goal 5 (the gate goes red on each failure mode it guards).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 ./gate.sh fails when SKILL.md lists a backlog usage that is not in the wrapper table; watched failing on a scratch copy
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
scripts/check_commands.py now also fails on any SKILL.md bullet that opens with a backticked `backlog ...` usage not in the wrapper's COMMANDS table (upstream commands in SKILL.md appear only in prose, so the current file passes). Proof: ./gate.sh exit 1 with `- `backlog draft remove <id>`: delete a draft.` seeded into the real SKILL.md (step 'command tables and skill match the wrapper table' FAIL naming the line); --skill scratch copies with that line as a top-level and as a nested '  * ' bullet each exit 1; ./gate.sh exit 0 after restoring. doc-1 section 8 item 5 updated.
<!-- SECTION:FINAL_SUMMARY:END -->
