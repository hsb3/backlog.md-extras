---
id: TASK-18
title: >-
  Wrapper: an unreadable executable named backlog on PATH crashes with a
  traceback
status: Done
assignee: []
created_date: '2026-10-21T09:26:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels:
  - hardening
dependencies: []
priority: low
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the 0.4.0 review. real_backlog() (plugins/backlog-extras/bin/backlog:28-32) reads each candidate to detect wrappers; an executable without read permission raises instead of being skipped. Repro: `chmod 111` a stub named backlog first on PATH, run `backlog --version`.

Impact on goal: doc-1 goal 3 (fail loudly and clearly, never a traceback).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 An unreadable candidate is skipped (or named in a one-line error), never a traceback; selftest covers it, watched failing first
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Watched failing: tests/selftest.sh against a copy of the working-tree plugin dir taken before the edit (SELFTEST_BL) exited 1 with exactly one failure: FAIL unreadable backlog on PATH (rc=1): Traceback (most recent call last): ... Log: (local log) task-18-selftest-prechange.log. After: tests/selftest.sh rc 0, 123 ok lines, no FAIL. Log: (local log) task-18-selftest-after.log. Change: real_backlog() requires read as well as execute permission (os.R_OK | os.X_OK) for a candidate, so an unreadable backlog on PATH is skipped.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
real_backlog() requires read as well as execute permission, so an unreadable backlog on PATH is skipped; selftest case with a mode-111 stub first on PATH, watched failing with a PermissionError traceback (task-18-selftest-prechange.log), passing after (task-18-selftest-after.log).
<!-- SECTION:FINAL_SUMMARY:END -->
