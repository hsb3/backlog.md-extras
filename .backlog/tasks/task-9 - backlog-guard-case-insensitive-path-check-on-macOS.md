---
id: TASK-9
title: 'backlog-guard: case-insensitive path check on macOS'
status: Done
assignee: []
created_date: '2026-10-20 00:38'
updated_date: '2026-10-21T14:19:00Z'
labels: []
dependencies: []
priority: low
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
On a case-insensitive disk (macOS default) a write to .BACKLOG/tasks/x.md lands in .backlog/ but the guard compares paths case-sensitively, so Edit/Write, apply_patch and Bash all let it through. Pre-existing for Claude Code; found by the PR #1 review. Repro: apply_patch '*** Add File: .BACKLOG/tasks/x.md' in a project with .backlog/config.yml is allowed.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Each of Edit, apply_patch and a Bash redirect targeting .BACKLOG/ (any case variant) is denied where the disk is case-insensitive; a hook test covers it and was watched failing
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Guard sets nocasematch when <root>/.BACKLOG and <root>/.backlog are the same folder (-ef, bash 3.2 safe), so path compares and patterns ignore case on a case-insensitive disk (commit 2c50f3f; bypass prefix excepted, fa83e66). backlog-guard/test.sh adds Edit .BACKLOG/tasks/x.md, Bash 'echo x > .Backlog/tasks/x.md' and apply_patch '*** Add File: .BACKLOG/tasks/x.md', expecting deny where the disk is case-insensitive and allow otherwise; all three watched failing first on APFS (FAIL want deny got allow). Passes under /bin/bash 3.2 and bash 5.3; ./gate.sh exit 0. doc-1 section 5 no longer lists the case limit.
<!-- SECTION:FINAL_SUMMARY:END -->
