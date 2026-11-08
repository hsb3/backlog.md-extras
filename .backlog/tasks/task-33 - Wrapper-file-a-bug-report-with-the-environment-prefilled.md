---
id: TASK-33
title: 'Wrapper: file a bug report with the environment prefilled'
status: To Do
assignee: []
created_date: '2026-10-24T18:50:00Z'
labels: []
dependencies: []
priority: medium
type: enhancement
ordinal: 33000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The bug report issue form (.github/ISSUE_TEMPLATE/bug_report.yml) requires versions, harness, OS, conditions and logs. Most of that the wrapper can collect itself, so a report should take one command instead of hand-copying version output.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An explicit wrapper command collects backlog-extras release, Backlog.md version, harness (Claude Code, Codex or terminal), OS, the resolved real backlog path, project layout and backlog doctor output.
- [ ] #2 It opens the new-issue page for hsb3/backlog.md-extras with bug_report.yml selected and those fields prefilled by field id (query parameters), or prints the URL when no browser is available; it never files an issue without the person submitting the form.
- [ ] #3 The home directory is replaced with ~ and nothing outside the listed fields is sent; the command prints what it collected before opening the page.
- [ ] #4 A gate test checks the generated URL against the field ids in bug_report.yml, so renaming a form field fails the gate.
- [ ] #5 Depends on bug_report.yml being committed to main.
<!-- AC:END -->
