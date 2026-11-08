---
id: TASK-22
title: 'Gate: enforce the backlog-md skill''s 80-line limit and its doctor line'
status: Done
assignee: []
created_date: '2026-10-21T09:26:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels:
  - hardening
dependencies: []
priority: low
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the 0.4.0 review. TASK-14 set at most 80 lines for SKILL.md, but no gate check enforces it, and scripts/check_commands.py checks only usages, so the skill's doctor summary drifted from the wrapper table (fixed by hand when closing 0.4.0).

Impact on goal: doc-1 goal 5 (the gate goes red on each failure mode it guards).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 ./gate.sh fails when SKILL.md exceeds 80 lines or a command summary differs from the wrapper table; watched failing
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
check_commands.py mentions() now requires each wrapper row as the exact skill line '- `backlog <usage>`: <summary>.' and fails over 80 lines (SKILL_MAX_LINES); SKILL.md decision view / milestone view lines changed to the table summaries. Watched failing: (1) new check on the unedited SKILL.md named exactly those two lines ((local log) task-22-1-new-check-before-skill-edit.log); (2) pre-change check_commands.py exits 0 on an 81-line skill and on an altered doctor summary, new exits 1 on both ((local log) task-22-3-old-vs-new.log); (3) gate.sh in an rsync copy: clean copy PASS the 'command tables and skill' step; 81 lines and altered doctor each 'FAIL: command tables and skill match the wrapper table', gate exit 1 ((local log) task-22-4-gate.log). Clean repo check exits 0 ((local log) task-22-2-after.log).

Final: python3 scripts/check_commands.py rc=0 ((local log) task-22-check-commands-final.log).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
scripts/check_commands.py (gate step 'command tables and skill match the wrapper table') fails when SKILL.md exceeds 80 lines or lacks the exact line '- `backlog <usage>`: <summary>.' for a wrapper row; two drifted skill summaries aligned to the table. Watched failing: gate exit 1 on an 81-line skill and on an altered doctor summary in a scratch copy (task-22-4-gate.log).
<!-- SECTION:FINAL_SUMMARY:END -->
