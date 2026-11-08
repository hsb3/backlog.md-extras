---
id: TASK-16
title: >-
  Wrapper: task edit --add-dep and --remove-dep; warn when --dep drops
  dependencies
status: Done
assignee: []
created_date: '2026-10-21T05:29:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels: []
milestone: m-2
dependencies:
  - TASK-13
priority: medium
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision 12 in doc-1. Checked on 1.55.0: a task depending on TASK-1, then `task edit <id> --dep task-2`, depends on TASK-2 only. Upstream has add/remove pairs for labels and references, but for dependencies only `--dep`/`--depends-on` (set) and `--clear-deps`. Agents expect --dep to add, and lose dependencies silently.

Impact on goal: doc-1 goal 1; silent dependency loss on edit, from every multi-dependency --dep to 0.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `task edit <id> --add-dep X[,Y]` keeps existing dependencies and adds X and Y without duplicates (case and padding ignored); `--remove-dep X` removes only X; other flags in the same call reach upstream unchanged; `task view --plain` is the oracle
- [x] #2 Plain `--dep`/`--depends-on` behaves exactly as upstream and prints one stderr line naming the dependencies it dropped; nothing is printed when none are dropped
- [x] #3 --add-dep or --remove-dep combined with --dep, --depends-on or --clear-deps exits 2 with a usage message and changes nothing
- [x] #4 `task edit --help` lists both flags in the added section (task-13); refuses to run off the pin
- [x] #5 selftest covers every case above, each watched failing on the pre-change wrapper; doc-1 section 4 and README updated
- [x] #6 Off the pin, --add-dep and --remove-dep refuse to run like the added commands, and plain --dep passes through unchanged without the warning
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Two COMMANDS rows (extends-upstream) share task_edit(): 'task edit <id> --add-dep X[,Y]' and '--remove-dep X[,Y]'; README has the same two rows (check_commands.py passes). split_task_edit() finds task IDs and the dep flags (--x V, --x=V, -xV, repeatable, comma lists) using task edit's value-less options at 1.55.0 (shortcut comment). --add-dep/--remove-dep: current deps from 'task view <id> --json' -> task.dependencies, merged with norm() (existing order, then new), then upstream 'task edit <id> <other args> --dep a,b' (or --clear-deps when empty), one call per task ID since each list differs. Plain --dep/--depends-on: on the pin, one stderr line per task naming dropped deps, then exec with argv unchanged; off the pin no check, no warning. Extended rows now gate themselves (doctor calls require_pinned_backlog itself) so plain task edit stays ungated.

Watched failing: tests/selftest.sh with SELFTEST_BL = git show 72e8c0f:plugins/backlog-extras/bin/backlog: rc=1, 10 FAIL lines: --add-dep keeps/adds/dedupes, passes other flags, --remove-dep (one, all), four usage errors (unknown option '--add-dep', rc 1 not 2), plain --dep names nothing dropped, version gate let --add-dep run. Log: (local log) task-16-selftest-prechange.log. Not watched failing because they already held before: '--depends-on that drops nothing is silent' and 'off the pin plain --dep passes through without warning'. task edit --help on 72e8c0f had no 'Added by backlog-extras' section (count 0); now lists both rows. Log: (local log) task-16-help-prechange.log

After: tests/selftest.sh rc=0, all ok, including help task, task --help, task edit --help adding exactly the two rows (log: (local log) task-16-selftest-after.log); ./gate.sh exit 0. Manual: 'task edit 4 5 --add-dep=3 --notes "x --add-dep"' merged per task; '--add-dep' with no value exits 2; 'task edit 99 --add-dep 1' exits 1 'no task 99'.

Docs: README rows plus a line on the --dep warning; doc-1 section 4 (table rows, the --dep correction with its reason, extended commands gate themselves) and section 8 item 2; body roundtrip diffed equal.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
task edit gains --add-dep and --remove-dep (merged with the current list, passed to upstream as a full --dep, one call per task), plain --dep warns on stderr about dropped dependencies on the pin, usage errors exit 2; help, hooks and README pick up the two rows from COMMANDS.
<!-- SECTION:FINAL_SUMMARY:END -->
