---
id: TASK-35
title: 'README: ground-up rewrite with value proposition and visual proof'
status: To Do
assignee: []
created_date: '2026-10-24T18:50:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels: []
dependencies: []
priority: medium
type: chore
ordinal: 35000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Rewrite README.md from scratch following a README value-and-proof skill: an honest pitch for a willing user and real proof of the working parts. The current README grew by accretion and reads as a reference manual. Best done after TASK-30..33 land so it documents update, uninstall and bug reporting.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Sections: why this exists, what it provides today with a plain 'what it is not yet' paragraph (private, no native Windows, live hook sessions last verified on named versions), install for each host, commands, and a roadmap that links the Backlog.md board and GitHub issues instead of duplicating them.
- [ ] #2 Visuals: at least one diagram of how the wrapper, hooks and upstream Backlog.md fit together (Mermaid, labels without parentheses) and captured images of real runs in a synthetic demo project: the session-doctor message, the guard blocking a direct write, and backlog --help showing the added commands.
- [ ] #3 Every image is captured from a real run, looked at, and checked for leaked paths, usernames or tokens; images live in docs/images/ and every reference resolves.
- [ ] #4 No hyperbole, no second person, no paths outside the repo; derived versions are not restated where requirements.json is the source.
- [ ] #5 check_commands.py and the full gate stay green, since the README Commands table is gated against the wrapper table.
<!-- AC:END -->
