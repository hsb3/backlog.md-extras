---
id: TASK-27
title: >-
  backlog-guard: Bash false positives when a command only mentions the board;
  auditable per-command bypass
status: Done
assignee: []
created_date: '2026-10-21T13:12:00Z'
updated_date: '2026-10-21T14:19:00Z'
labels: []
dependencies: []
priority: medium
ordinal: 27000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Tracks GitHub #4 (https://github.com/hsb3/backlog.md-extras/issues/4). The Bash branch of hooks/backlog-guard/hook.sh denies when the board marker and any write verb both appear anywhere in the command, so copying the board out (cp -R .backlog $tmp), a python3 heredoc that writes another file but mentions .backlog/ in its text, and gh issue create with a body mentioning .backlog and cp are all denied. No sanctioned way past it for legitimate direct operations.

Impact on goal: doc-1 goal 2 (direct writes denied) without pushing agents to riskier workarounds such as testing on the real board.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Each of the three false positives in GitHub #4 is allowed or covered by the bypass per the recorded owner decision; every current deny case in backlog-guard/test.sh still denies; new tests watched failing first
- [x] #2 A per-command bypass requires a reason, records it, never switches the guard off for a session, and is described in the README, doc-1 section 5 and the deny message
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decisions 2026-10-21 (recommendations accepted):
- Narrowing: stop matching the board name when it appears only as a cp/rsync source or inside quoted arguments of non-interpreter commands (fixes GH #4 false positives 1 and 3). Interpreters (python3, node, ruby, bun, deno) whose text mentions the board stay denied; false positive 2 goes through the bypass.
- Bypass: per-command prefix `BACKLOG_GUARD_BYPASS="<reason>" <cmd>`, Bash only, empty reason denied, appended with timestamp, project and command to ${XDG_STATE_HOME:-~/.local/state}/backlog-extras/bypass.log, named in the deny message. Never a session-wide switch.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Guard Bash match narrowed and per-command bypass added (commits 78d6515, fa83e66, 5e7ee0e). #1: GH #4 FP1 (cp -R .backlog out to a temp dir) and FP3 (gh issue create --body "$(cat <<'EOF' ...)") allow; FP2 (python3 heredoc mentioning .backlog/) denies and allows with BACKLOG_GUARD_BYPASS="update handoff prose". Heredoc bodies, quoted prose and cp/rsync sources are ignored; interpreters and nested shells (python/node/ruby/bun/deno/sh/bash/zsh/eval) naming the board stay denied. Every pre-existing deny case in backlog-guard/test.sh is unchanged and still denies; new tests watched failing first (FPs, bypass log, deny message, rsync, bash -c, and the review repros: cp/rsync behind redirects, quoted paths with spaces, unclosed quotes/heredocs). #2: the prefix needs a non-empty reason (empty and whitespace-only deny), is read only from the command text (an exported variable does nothing; not session-wide), and appends a JSON line {time, project, reason, command} to ${XDG_STATE_HOME:-~/.local/state}/backlog-extras/bypass.log, denying if it cannot; tests use a scratch XDG_STATE_HOME. Described in README, doc-1 section 5 and decisions 16-17, the skill, and the deny message. ./gate.sh exit 0; two adversarial review passes. Known limits: a bypass prefix covers the whole Bash call (logged); pattern matcher, not a parser.
<!-- SECTION:FINAL_SUMMARY:END -->
