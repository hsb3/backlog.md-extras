---
id: TASK-10
title: 'backlog-guard: confirm and cover Codex shell workdir'
status: Done
assignee: []
created_date: 2026-10-20 00:38
updated_date: '2026-11-08T20:39:00Z'
labels: []
dependencies: []
priority: low
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Codex's shell tool takes a working-directory parameter. If Codex passes it to hooks (e.g. tool_input.workdir), a command like 'rm task-1.md' with workdir <proj>/.backlog/tasks is allowed because the guard only looks for the folder name in the command text. Unconfirmed; found by the PR #1 review. Also seen: a patch context line ' *** Add File: .backlog/x.md' (leading space) is falsely denied; harmless.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A live codex exec shows the PreToolUse payload for a shell call with a working directory; recorded in notes
- [x] #2 If the field exists, a write-verb command run with a workdir inside the backlog folder is denied, with a hook test watched failing
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Live probe 2026-10-21, codex-cli 0.163.0 (codex exec, isolated CODEX_HOME and HOME, hooks enabled, logging PreToolUse hook with matcher ".*"). Prompted to run pwd with the shell tool workdir set to <proj>/sub; the rollout shows the model passed workdir:"<proj>/sub" and Codex ran "/bin/zsh -lc pwd in <proj>/sub". The hook payload carried no workdir under any key: {"cwd":"<proj>","hook_event_name":"PreToolUse","permission_mode":"bypassPermissions","tool_name":"Bash","tool_input":{"command":"pwd"},"tool_use_id":"exec-...", plus session_id, turn_id, transcript_path, model}. tool_name is "Bash"; top-level cwd is the session dir, not the workdir. So AC #2 does not apply: the guard cannot see the workdir, and relative paths in such a command resolve against the session cwd. Only an absolute workdir was tried. Evidence: (local log) task-10-payloads.log, task-10-run.log, task-10-rollout.jsonl.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Live probe on codex-cli 0.163.0 (isolated CODEX_HOME and HOME, hooks enabled, logging PreToolUse hook): the model passed workdir <proj>/sub and Codex ran the command there, but the hook payload carried no workdir under any key (tool_input is {command} only; cwd is the session dir); payload in the notes, evidence (local log) task-10-payloads.log, task-10-run.log, task-10-rollout.jsonl. AC #2 is conditional on the field existing; it does not, so there is nothing the guard can read and no code change. The gap is recorded as a known limit in doc-1 section 5 (a relative path in a command run with a workdir resolves against the session cwd). Only an absolute workdir was probed.
<!-- SECTION:FINAL_SUMMARY:END -->
