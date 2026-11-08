---
id: TASK-3
title: 'session-doctor: SessionStart pin check and bl guidance'
status: Done
assignee:
  - '@claude-builder'
created_date: '2026-10-18 18:50'
updated_date: '2026-10-18 18:56'
labels: []
milestone: m-0
dependencies:
  - TASK-1
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Spec section 6. Replaces the per-project AGENTS.md line (tooling over directive) and makes an untested or missing backlog.md loud at session start instead of at the first bl write.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Outside a Backlog project: no output, exit 0
- [x] #2 backlog missing or not at BACKLOG_VERSION: a visible warning naming both versions and the fix
- [x] #3 Otherwise additionalContext tells the agent to use bl, lists its added commands, and says to run bl doctor after archiving or demoting
- [x] #4 Hook test covers all three cases and was watched failing first
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. New hook dir plugins/backlog-extras/hooks/session-doctor (config.json, hook.sh, test.sh), registered in hooks.json under SessionStart.
2. Silent outside a Backlog project; pin read from ${CLAUDE_PLUGIN_ROOT}/bin/bl.
3. Missing or off-pin backlog: systemMessage (user-visible) plus additionalContext warning.
4. bl on PATH that is not the plugin copy and differs from it: warning (PATH order puts the plugin bin last).
5. Otherwise additionalContext guidance on bl.
6. test.sh written first and watched failing; live claude -p check that the context arrives.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Built by a builder agent; verified independently here. Builder: test.sh written first and run against a stub hook that prints nothing; 6 of 7 cases failed, then all 7 passed with the real hook. Hermetic PATH per case.
My checks: full gate.sh all 9 steps PASS. Live claude -p (haiku) in a scratch Backlog project: normal case delivered the bl guidance as session context (builder run); off-pin case with a stub backlog reporting 9.9.9 first on PATH delivered the warning to the agent, and the stream-json hook response carried the same text as systemMessage.
Not verified live: the shadowed-bl warning (the local bl is identical to the plugin copy), and how systemMessage renders in the interactive UI.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added the session-doctor SessionStart hook: silent outside Backlog projects; warns (user-visible systemMessage plus agent context) when backlog is missing, off the pin, or a different bl shadows the plugin copy; otherwise gives the agent the bl guidance that replaces the AGENTS.md line. Verified by a red-first hook test, the gate, and two live sessions.
<!-- SECTION:FINAL_SUMMARY:END -->
