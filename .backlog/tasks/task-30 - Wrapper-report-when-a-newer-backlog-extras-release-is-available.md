---
id: TASK-30
title: 'Wrapper: report when a newer backlog-extras release is available'
status: To Do
assignee: []
created_date: '2026-10-24T18:50:00Z'
labels: []
dependencies: []
priority: medium
type: enhancement
ordinal: 30000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The terminal install (bl from install.sh) has no way to tell that a newer backlog-extras release exists; it is pinned to the release it was installed from and silently drifts behind the plugin. Plugin installs update through each host's marketplace, so this covers the terminal install only.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An explicit wrapper command (name decided in the PR) prints the installed release (from the installed requirements.json) and the latest published release tag on hsb3/backlog.md-extras, plus the exact update command when they differ.
- [ ] #2 Exit 0 when up to date, a distinct documented non-zero code when an update is available, another when the check cannot run; missing gh, signed-out gh or no network print a one-line cause, never a traceback or a false 'up to date'.
- [ ] #3 Ordinary pass-through and added commands make no network call; only the explicit command does.
- [ ] #4 A gate test with a fake gh covers up-to-date, update-available and check-failed, and is observed failing against the pre-change wrapper.
- [ ] #5 README and the wrapper COMMANDS table list the command; check_commands.py stays green.
<!-- AC:END -->
