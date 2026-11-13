---
id: TASK-36
title: 'backlog-guard: interpreter denies name the cause and the temp-file remedy'
status: In Progress
assignee:
  - '@claude'
created_date: '2026-11-13T16:35:00Z'
updated_date: '2026-11-13T17:18:00Z'
labels:
  - guard
  - hardening
dependencies: []
references:
  - 'https://github.com/hsb3/backlog.md-extras/issues/4'
priority: medium
type: bug
ordinal: 36000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
GitHub issue #4. The guard denies a single-segment interpreter command (python3 -c, python3 - <<heredoc) whenever the board path appears anywhere in it, including inside a string literal or heredoc body written to another file. The cat/echo forms with the same prose are allowed, so only the interpreter path fails to tell prose from targets. Hit while migrating a repo onto Backlog.md: scripts that rewrote AGENTS.md to document the board were denied. Reproduced on 0.7.3 (dev, 2026-11-13).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A denied interpreter command whose text names the board says the board path appears in interpreter source and suggests running the script from a temp file
- [x] #2 The same script run by path (python3 "$f") is allowed
- [x] #3 The backlog-md skill tells agents to pass long or multi-line text via a temp file and to run helper scripts from a file
- [x] #4 hooks/backlog-guard/test.sh covers the deny reason and the run-by-path case
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Keep the interpreter rule as is (fail safe); add a deny reason naming the cause and the temp-file remedy.
2. Skill: one rule line on temp files for long text and scripts.
3. Tests for the reason and the run-by-path allow.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Approach changed on owner direction (2026-11-13): a content heuristic that let interpreter prose through was built and reviewed; an adversarial review found 13 board writes it let through (os.system with sh -c, exec, /bin/rm, unlink, find -delete, an apostrophe in a comment shifting quote pairing) and a quadratic slowdown past the 10 s hook timeout. Hardened, it closed those, but the owner chose instructions over heuristics: agents put content and scripts in temp files, and the deny reason teaches that at the point of failure. Heuristic patch kept outside the repo. New deny-reason test fails against the HEAD hook and passes after.

Verified 2026-11-13: guard test passes (deny reason + run-by-path cases; reason test fails on HEAD hook), shellcheck PASS, pytest PASS, skill/table checks PASS. bin/gate exits 1 on both dev and clean main with identical failures from host drift: claude 2.1.323 vs pin 2.1.310, openspec 1.14.0 vs 1.14.3, and a second Backlog.md 1.55.0 under mise node/26 that the self-test and installer resolve. Not Done until gate is green on a matching host or CI.
<!-- SECTION:NOTES:END -->
