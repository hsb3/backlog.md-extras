---
id: TASK-31
title: 'Wrapper: update the terminal install in place'
status: To Do
assignee: []
created_date: '2026-10-24T18:50:00Z'
labels: []
dependencies:
  - TASK-30
priority: medium
type: enhancement
ordinal: 31000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Updating the terminal install today means re-running the piped install.sh one-liner by hand with the right tag. Add a wrapper command that does it, reusing install.sh rather than a second install path.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An explicit wrapper command updates bl, the skill, requirements, checker and managed Backlog.md to the latest published release, or to a given ref, by running that release's install.sh resolved to one commit.
- [ ] #2 After success it prints old and new release and verifies the new bl resolves the new Backlog.md pin; when already current it says so and changes nothing.
- [ ] #3 A failed download or install leaves the previous working install in place and exits non-zero naming the failed step.
- [ ] #4 check_install.sh (or a sibling) installs an older fixture release, runs the update against a fake gh, and checks the installed files match the newer release; observed failing before the change.
- [ ] #5 README documents the command next to the existing 'Rerun setup after updating the plugin' guidance.
<!-- AC:END -->
