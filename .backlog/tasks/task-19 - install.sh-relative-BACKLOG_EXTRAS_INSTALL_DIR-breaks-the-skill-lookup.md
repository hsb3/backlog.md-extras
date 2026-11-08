---
id: TASK-19
title: 'install.sh: relative BACKLOG_EXTRAS_INSTALL_DIR breaks the skill lookup'
status: Done
assignee: []
created_date: '2026-10-21T09:26:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels:
  - hardening
dependencies: []
priority: low
ordinal: 19000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Found in the 0.4.0 review. install.sh:39 derives the share dir from a relative $d, so the wrapper later cannot find share/backlog-extras/SKILL.md and falls back to the repo URL. Repro: `BACKLOG_EXTRAS_INSTALL_DIR=rel/bin ./install.sh`, then `rel/bin/bl agents --update-instructions`.

Impact on goal: doc-1 goal 4 (terminal install works from one command).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A relative install dir is resolved to absolute (or rejected with a message); scripts/check_install.sh covers it, watched failing first
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Repro findings: the literal repro (BACKLOG_EXTRAS_INSTALL_DIR=rel/bin from a scratch cwd) does not break the skill lookup; what failed was messages naming rel/bin/bl and a false 'rel/bin is not on PATH' warning. Sibling defect confirmed: a symlinked install dir put share/ beside the link while bl resolves beside the target. Watched failing first against pre-change install.sh: 'relative: output does not name the absolute path' and 'symlink: skill not installed in ../share/backlog-extras' (log: (local log) task-19-check-install-prechange.log). After: scripts/check_install.sh passes, rc=0, shellcheck clean (task-19-check-install-after.log). Change: install.sh resolves d to absolute after mkdir and derives share from the physical (pwd -P) parent.

Review follow-up: install.sh unsets CDPATH (an exported CDPATH made $(cd ... && pwd) capture the echoed path too, rc 71); the relative case in scripts/check_install.sh now runs with CDPATH exported, watched failing ((local log) task-19-cdpath-prechange.log, rc=71) and passing (task-19-cdpath-after.log, rc=0). Branch install.sh piped through real gh with a relative dir on macOS and Linux: see TASK-24 (task-24-*-piped-branch.log).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
install.sh resolves BACKLOG_EXTRAS_INSTALL_DIR to absolute and puts the skill beside the dir's physical parent (where bl looks after resolving symlinks); scripts/check_install.sh covers a relative dir (absolute paths in output, no false PATH warning, CDPATH exported) and a symlinked dir, each watched failing first.
<!-- SECTION:FINAL_SUMMARY:END -->
