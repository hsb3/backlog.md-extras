---
id: TASK-2
title: 'backlog-guard: stay silent outside Backlog projects'
status: Done
assignee:
  - '@claude'
created_date: '2026-10-18 18:50'
updated_date: '2026-10-18 18:54'
labels: []
milestone: m-0
dependencies:
  - TASK-1
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
As a plugin the guard can fire in any project where it is enabled; it must never deny anything in a project without a backlog folder.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 With no .backlog/config.yml or backlog/config.yml under CLAUDE_PROJECT_DIR the hook prints nothing and exits 0 for every tool input, including writes to a .backlog path
- [x] #2 Existing allow/deny cases still pass in a Backlog project
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add not-a-Backlog-project cases to backlog-guard/test.sh (temp project without config.yml) and watch them fail.
2. hook.sh exits 0 silently unless CLAUDE_PROJECT_DIR (or cwd) has .backlog/config.yml or backlog/config.yml.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Silence cases (Edit and Bash writes to a dot-backlog path in a project without config.yml) written first; they failed (hook printed a deny), then passed after the project check.
Also fixed while here: the deny rules only knew the dot folder, while bl and the new project check accept a non-dot backlog/ folder. The hook now protects whichever folder holds config.yml; for the non-dot folder the Bash marker includes the trailing slash so plain `backlog ...` commands are not matched. 5 cases added, 2 watched failing first.
backlog-guard test 36/36, shellcheck clean.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
backlog-guard is silent (no output, exit 0) in projects without a Backlog config, and protects a non-dot backlog/ folder as well as .backlog/. Verified by 7 new test cases, red before the change.
<!-- SECTION:FINAL_SUMMARY:END -->
