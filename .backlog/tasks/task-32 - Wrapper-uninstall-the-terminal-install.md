---
id: TASK-32
title: 'Wrapper: uninstall the terminal install'
status: To Do
assignee: []
created_date: '2026-10-24T18:50:00Z'
labels: []
dependencies: []
priority: medium
type: enhancement
ordinal: 32000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
install.sh writes bl into the install dir and the skill, requirements, checker and managed Backlog.md under ../share/backlog-extras/, but nothing removes them. Add an uninstall that removes exactly what install.sh created.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An explicit uninstall (wrapper command or install.sh flag, decided in the PR) lists every path it will remove and removes them only with --yes; without --yes it changes nothing.
- [ ] #2 It removes only bl and ../share/backlog-extras/ for the resolved install dir (honouring BACKLOG_EXTRAS_INSTALL_DIR and the symlinked-install-dir rule); npm's global backlog, project .backlog/ folders and plugin installs are untouched.
- [ ] #3 It prints the Claude Code and Codex commands to remove the plugin, since those belong to the hosts.
- [ ] #4 A gate check installs into a temp dir, uninstalls, and finds no leftover files; observed failing before the change.
<!-- AC:END -->
