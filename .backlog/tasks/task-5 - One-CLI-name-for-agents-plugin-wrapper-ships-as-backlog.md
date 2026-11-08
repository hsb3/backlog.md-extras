---
id: TASK-5
title: 'One CLI name for agents: plugin wrapper ships as backlog'
status: Done
assignee:
  - '@claude'
created_date: 2026-10-19 01:33
updated_date: '2026-11-08T20:39:00Z'
labels: []
milestone: m-1
dependencies: []
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Agents juggled two names (backlog from upstream instructions, bl from the session doctor). Ship the wrapper as plugins/backlog-extras/bin/backlog; session-doctor writes a PATH prepend to CLAUDE_ENV_FILE so it wins over npm's backlog (verified live with claude -p on 2026-10-18). The wrapper finds the real backlog by skipping itself on PATH. install.sh keeps installing it as bl for terminals.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 plugins/backlog-extras/bin/backlog exists and bin/bl does not; passthrough and every added command work when the wrapper is first on PATH, with no recursion
- [x] #2 With no real backlog on PATH the wrapper exits 127 naming the problem
- [x] #3 session-doctor writes the PATH prepend to CLAUDE_ENV_FILE, and warns loudly (systemMessage) when CLAUDE_ENV_FILE is not provided
- [x] #4 Guard message, session-doctor guidance, spec, README and plugin descriptions name backlog, not bl, for agents; install.sh still installs bl
- [x] #5 plugin.json version is 0.2.0; ./gate.sh passes; a live claude session in the owner's reference project resolves backlog to the plugin copy and runs backlog decision view
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Tests first: selftest runs the wrapper as bin/backlog first on PATH (recursion, 127 when real missing); session-doctor test expects CLAUDE_ENV_FILE prepend and a warning without it. Watch both fail.
2. git mv bin/bl bin/backlog; wrapper resolves the real backlog by skipping files that are itself; version check and doctor use it.
3. session-doctor: version via the wrapper, write PATH line, drop the bl shadow check, guidance names backlog.
4. install.sh/check_install/gate path updates; install still writes bl.
5. Guard message, descriptions, spec, README, the reference project's docs; bump 0.2.0.
6. gate, live session check, commit, push.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Red first: unfixed wrapper first on PATH looped forever (the first selftest run hung; forked children kept the output pipe open), so the test now kills the process group after 20s and failed with rc=124 x3; session-doctor tests failed 4/6 on the old hook. Fix: real_backlog() skips files resolving to itself; os.execv the resolved path.
Live: claude -p in the owner's reference project after plugin update 0.1.0->0.2.0 resolved backlog to the plugin cache 0.2.0 bin/backlog; backlog decision view decision-999 answered by the wrapper (rc 1); session context named the wrapper.
Not verified: interactive session UI, resume/compact re-run (duplicate PATH entry expected, harmless).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Plugin ships the wrapper as bin/backlog; session-doctor prepends the plugin's bin/ via CLAUDE_ENV_FILE and warns when it is missing; wrapper finds the real backlog by skipping itself (127 when none). install.sh still installs it as bl. Verified: ./gate.sh 9/9 PASS, new tests watched failing first, live claude -p session in the owner's reference project resolved backlog to plugin 0.2.0. Pushed as cf64339.
<!-- SECTION:FINAL_SUMMARY:END -->
