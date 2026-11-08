---
id: TASK-17
title: 'Wrapper: `backlog help -v` prints the version, then the added-commands section'
status: Done
assignee: []
created_date: '2026-10-21T09:26:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels:
  - hardening
dependencies: []
priority: low
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the 0.4.0 review. Help interception in plugins/backlog-extras/bin/backlog treats `help -v` as a help request, so the 'Added by backlog-extras' section follows upstream's version line. Repro: `backlog help -v`.

Impact on goal: doc-1 goal 1; help output correct for every flag combination.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `backlog help -v` output and exit code are byte-identical to upstream's; a selftest case covers it, watched failing first
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Watched failing: tests/selftest.sh against HEAD's wrapper (git archive HEAD plugins/backlog-extras, SELFTEST_BL) exited 1 with exactly the 8 new cases failing: FAIL version flag differs from upstream: help -v / help --version / --help -v / -h --version / help decision -v / decision --help -v / doctor --help -v / decision view -v. Log: (local log) task-17-selftest-prechange.log. After: tests/selftest.sh rc 0, 122 ok lines, no FAIL. Log: (local log) task-17-selftest-after.log. Change: main() execs upstream unchanged when any argv token is exactly -v or --version, before help handling and dispatch (after the hidden --backlog-extras-commands check), with a shortcut comment for a literal -v option value.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
main() hands any argv with -v or --version to upstream unchanged, so help -v (and every help or added-command form with a version flag) is upstream's byte for byte; selftest compares 8 forms with upstream (output and exit code), watched failing (task-17-selftest-prechange.log, 8 FAIL), passing after (task-17-selftest-after.log). shortcut: a literal -v option value is a version request, as it is upstream.
<!-- SECTION:FINAL_SUMMARY:END -->
