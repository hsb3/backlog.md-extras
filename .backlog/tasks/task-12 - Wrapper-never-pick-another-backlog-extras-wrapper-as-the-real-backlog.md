---
id: TASK-12
title: 'Wrapper: never pick another backlog-extras wrapper as the real backlog'
status: Done
assignee: []
created_date: '2026-10-21T05:28:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels: []
milestone: m-2
dependencies: []
references:
  - https://github.com/hsb3/backlog.md-extras/issues/6
priority: high
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
real_backlog() in plugins/backlog-extras/bin/backlog skips only its own file. With two plugin copies on PATH (seen: the 0.2.0 and 0.3.1 cache dirs in one Claude Code session) each wrapper picks the other as the real backlog and they exec each other forever: a bare `--version` loops through the passthrough, `backlog doctor` through require_pinned_backlog() (hung past 120 s), and the session doctor's `$wrapper --version` hangs until its 15 s hook timeout. Fix once in real_backlog(): skip any PATH candidate that is itself a backlog-extras wrapper. Lands before the other dispatch changes in this milestone. GitHub issue #6.

Impact on goal: doc-1 goals 3 and 5 assume the version check returns; known hang triggers, from 1 to 0.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 With two wrapper copies ahead of the pinned backlog on PATH, in both orders, `backlog --version` prints the pinned version and exits 0 within 5 s, and `backlog decision view <id>` works
- [x] #2 tests/selftest.sh covers both cases and was watched failing (killed by its timeout) against the pre-fix wrapper
- [x] #3 GitHub issue #6 closed with the selftest output as proof
- [x] #4 The wrapper from commit d26a1bf (unfixed) first on PATH with the fixed one second also terminates within 5 s
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
real_backlog() now skips every PATH candidate whose first 4 KB contain the docstring marker `backlog.md-extras wrapper` (is_wrapper); this covers itself, other plugin copies, and the d26a1bf wrapper, which carries the same marker. selftest limit() takes a seconds argument; new cases run with limit 5.

Watched failing: new tests/selftest.sh run against the pre-fix wrapper (fix not yet applied): rc=1, all six new checks FAIL with rc=124 (killed by the 5 s limit): two wrappers (a:b), (b:a), (old:a) --version and decision view. Log: (local log) task-12-selftest-prefix.log

After fix: tests/selftest.sh rc=0, all ok. Log: (local log) task-12-selftest-fixed.log
  ok   two wrappers (a:b) --version
  ok   two wrappers (a:b) decision view
  ok   two wrappers (b:a) --version
  ok   two wrappers (b:a) decision view
  ok   two wrappers (old:a) --version
  ok   two wrappers (old:a) decision view
(old = git show d26a1bf wrapper first, fixed second: AC #4.) ./gate.sh exit 0.

doc-1 section 4 (real backlog resolution) and section 8 item 2 updated via doc update; body roundtrip verified by diff.

AC #3 deferred to the user: issue #6 stays open until merge; proposed comment for #6 is the six ok lines above plus: 'Fixed in plugin-0.4.0: real_backlog() skips any PATH candidate carrying the backlog.md-extras wrapper marker; tests/selftest.sh covers both orders and the d26a1bf wrapper first.'
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed in PR #8 (merge 5c94b78): real_backlog() skips any PATH candidate carrying the wrapper marker. Selftest covers both orders and the d26a1bf wrapper first, each watched failing first. GitHub issue #6 closed with the six selftest ok lines as proof.
<!-- SECTION:FINAL_SUMMARY:END -->
