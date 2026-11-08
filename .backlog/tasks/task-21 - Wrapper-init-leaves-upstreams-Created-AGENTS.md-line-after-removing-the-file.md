---
id: TASK-21
title: >-
  Wrapper: init leaves upstream's 'Created: AGENTS.md' line after removing the
  file
status: Done
assignee: []
created_date: '2026-10-21T09:26:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels:
  - hardening
dependencies: []
priority: low
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the 0.4.0 review. Upstream's init summary still reports the instruction file it wrote; the wrapper then restores or deletes it, so the output contradicts the disk. Repro: `backlog init demo --defaults --no-git` in an empty dir: output says Created: AGENTS.md, no AGENTS.md exists.

Impact on goal: doc-1 goal 1; init output matches what is on disk.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 After a corrected init, the output states which instruction files the wrapper reverted (one line) so no line is left contradicting the disk; selftest covers it
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Watched failing: tests/selftest.sh against a copy of the working-tree plugin dir taken before the edit (SELFTEST_BL) exited 1 with three failures: FAIL init --defaults --agent-instructions claude,agents,gemini,copilot names the reverted files: revert line []; FAIL init --defaults names the AGENTS.md it removed: revert line []; FAIL config wizard names the reverted Claude agent: revert line []. (The no-revert case for the cancelled init passed on the baseline, as expected: it prints no such line.) Log: (local log) task-21-selftest-prechange.log. After: tests/selftest.sh rc 0, 128 ok lines, no FAIL. Log: (local log) task-21-selftest-after.log. Change: run_undoing_instruction_writes() returns the files it put back or deleted (relative to root, INSTRUCTION_FILES then CLAUDE_AGENT order) and, when that list is non-empty, prints one stdout line 'backlog-extras: reverted upstream's writes to <files>; the backlog-md skill replaces its instructions' before init/config print the skill, whatever upstream's exit code.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
run_undoing_instruction_writes returns the files it reverted and prints one stdout line naming them (backlog-extras: reverted upstream's writes to AGENTS.md; the backlog-md skill replaces its instructions), for init and the config wizard. Selftest asserts the exact file list for init-new, the four-file seeded run, the config wizard, and no line after a cancelled init; the three positive cases watched failing (task-21-selftest-prechange.log).
<!-- SECTION:FINAL_SUMMARY:END -->
