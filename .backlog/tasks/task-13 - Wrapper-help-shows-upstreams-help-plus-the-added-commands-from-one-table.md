---
id: TASK-13
title: 'Wrapper: help shows upstream''s help plus the added commands, from one table'
status: Done
assignee: []
created_date: '2026-10-21T05:29:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels: []
milestone: m-2
dependencies:
  - TASK-12
priority: medium
ordinal: 13000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision 10 in doc-1. Today top-level help and help for unextended groups go to upstream, so agents never see the added commands, though upstream's AGENTS.md block tells them to run `backlog <command> --help`. Added subcommands print the wrapper's argparse help, and `milestone view --help` exits 1 (no milestone matching '--help'). The added commands are hand-listed in six places: the wrapper docstring, EXTENSIONS, the session doctor's guidance and warning strings, the backlog-guard deny message, the README table, doc-1 section 4.

Impact on goal: doc-1 goal 1 (every operation reachable through `backlog`); added commands discoverable from help, from 0 of 7 to all.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Help for every group the wrapper does not extend is byte-identical to upstream's
- [x] #2 A gate check fails when the README commands table and the wrapper table disagree; watched failing
- [x] #3 selftest and the session-doctor test cover the above; README Limits line about --help removed; doc-1 section 4 describes help
- [x] #4 `backlog --help`, `backlog -h`, `backlog help`, `backlog help <group>`, `<group> --help` for each group the wrapper extends, and `<group> <subcommand> --help` for each upstream subcommand it extends (e.g. `task edit`) print upstream's output unchanged, then an 'Added by backlog-extras' section listing exactly that scope's additions; exit 0
- [x] #5 `--help` on every added subcommand (including `milestone view --help`) prints its usage and exits 0
- [x] #6 One table in the wrapper is the only hand-written list of added commands: EXTENSIONS, the help sections, the session doctor's guidance and warning, and the backlog-guard deny message are derived from it
- [x] #7 doc-1 section 8 lists the new gate check
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
COMMANDS (bottom of the wrapper) is the one hand-written list: (usage, summary, handler, extends-upstream). Command words = usage tokens before the first <, [ or -, aliases tasks/milestones folded (the only top-level aliases in upstream 1.55.0 help). Dispatch, the version gate and help read it; the hidden flag --backlog-extras-commands prints usage<TAB>summary and feeds the session doctor (guidance and no-CLAUDE_ENV_FILE warning) and the guard (deny path only). decision() split into decision_view/update/remove; milestone view got an argparse parser. Help on an extended scope runs upstream with inherited stdout (not captured), so its output is unchanged by construction, then prints the section.

Judgment calls: the extends-upstream flag is a 4th table column rather than probing upstream at runtime (cheaper, explicit). Only argv[0] == help counts as the help command, so 'backlog decision help' passes through unchanged. A literal -h/--help option value counts as a help request (shortcut comment in the wrapper).

Watched failing:
- tests/selftest.sh with SELFTEST_BL pointed at the TASK-12 wrapper (git show :plugins/backlog-extras/bin/backlog): rc=1, FAIL --backlog-extras-commands printed nothing, FAIL help for --help/-h/help/milestones --help. Log: (local log) task-13-selftest-prechange.log. The same pre-change wrapper: 'milestone view --help' -> no milestone matching '--help', rc=1; 'decision view --help' -> 'usage: backlog decision [-h] ...' (not the subcommand).
- tests/selftest.sh against the new wrapper with help disabled (scope = None): rc=1, 13 FAIL lines, one per extended scope (--help, -h, help, milestones --help, help/--help for decision, doc, doctor, milestone). Log: (local log) task-13-selftest-nohelp.log
- session-doctor test.sh with the HEAD hook.sh in a scratch plugin copy: FAIL pinned guidance and FAIL no-CLAUDE_ENV_FILE warning (missing usages). Log: (local log) task-13-session-doctor-test-prechange.log
- backlog-guard test.sh with the HEAD hook.sh: rc=1, FAIL deny reason misses: decision view <id>... Log: (local log) task-13-guard-test-prechange.log
- scripts/check_commands.py on a README copy with the doc remove row dropped: rc=1 'missing from README: backlog doc remove <id>'; with doctor's usage changed: rc=1 missing/not in the wrapper. Log: (local log) task-13-check-commands-failing.log

After: tests/selftest.sh rc=0 (26 'help unchanged' checks for 13 upstream commands x 2 forms, 13 extended-scope checks, 6 added-command --help checks); both hook tests rc=0; check_commands.py rc=0; ./gate.sh exit 0 (new step 'README commands match the wrapper table'). Extended upstream subcommand path (task edit, TASK-16) probed with a scratch wrapper carrying a 'task edit <id> --add-dep ID' row: 'task edit --help' printed upstream's bytes unchanged, then the section with that row, rc 0; 'task create --help' unchanged.

Docs: README Limits --help line removed, Commands intro points at --help; doc-1 sections 3, 4 (table and help), 5, 6, 8 (items 2, 3, new 5) updated via doc update, body roundtrip diffed equal.

Review fixes (after d4961c9):
1. show_help passes an added command its real args (argparse help for a real -h, exit 2 for `decision update decision-1 --content -h`); `help <added cmd>` still passes --help. Watched failing: selftest with SELFTEST_BL = d4961c9 wrapper: 'FAIL --content -h (rc=0): usage: backlog decision update ...'. Log: (local log) task-13-review-selftest-prechange.log. After: ok --content -h is a usage error, ok writes nothing, ok help <added command> prints its usage.
2. scripts/check_commands.py also checks doc-1 section 4's table (read-only) and fails with a message, rc 1, when a section is missing. Watched failing: on the repo at d4961c9 it caught real drift (doc-1 rows 'task edit <id>... --add-dep'; fixed doc-1 to the wrapper usages); a doc-1 copy without the doc remove row: rc 1 'missing: backlog doc remove <id>'; copies without the section: rc 1 'no ... section'. The d4961c9 script on a README without the section: IndexError traceback. Log: (local log) task-13-review-check-commands.log
3. Hooks fall back to '`<cli> --help` lists' when the wrapper call yields an empty list (guard deny reason, session doctor guidance and warning). Guard test asserts 'decision view <id>' is in the deny reason and no longer aborts when the wrapper call fails. Watched failing with bin/backlog replaced by 'exit 1' in a scratch plugin copy: d4961c9 hook gives 'commands: . Flags' and the d4961c9 test only checked -n reason; the new test prints 'FAIL deny reason misses', rc 1. Log: (local log) task-13-review-hooks-empty-list.log
./gate.sh exit 0.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
One COMMANDS table in the wrapper now drives dispatch, the version gate, help (upstream's help plus an 'Added by backlog-extras' section for extended scopes, byte-identical passthrough otherwise, argparse usage for added subcommands), the session doctor's lists and the guard's deny message; scripts/check_commands.py gates the README table against it.
<!-- SECTION:FINAL_SUMMARY:END -->
