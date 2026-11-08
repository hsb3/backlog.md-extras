---
id: TASK-11
title: >-
  Decide whether to keep decision remove and doc remove now upstream has archive
  and delete
status: Done
assignee: []
created_date: '2026-10-20T19:40:00Z'
updated_date: '2026-10-21T11:43:00Z'
labels: []
dependencies: []
priority: low
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Backlog.md 1.55.0 added decision archive/restore/delete and doc archive/restore/delete (archive keeps the ID reserved, delete releases it), plus decision edit -s for status. The wrapper's decision remove and doc remove hard-delete a live file in one step, which frees the ID immediately (after doc remove doc-3, doc create gives doc-3 again). Found in the review of the 1.55.0 pin bump.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Owner decision recorded in doc-1 section 11: keep, reroute through archive+delete, or drop each of decision remove, doc remove, and decision update --status
- [x] #2 Wrapper, README, spec and selftest match the decision; ./gate.sh green
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Decision 13 in doc-1 (2026-10-21): keep decision remove, doc remove and decision update --status unchanged. Wrapper, README, spec and selftest already match; ./gate.sh exit 0.
<!-- SECTION:FINAL_SUMMARY:END -->
