---
id: TASK-23
title: Live-verify the 0.4.0 hooks in Claude Code and Codex sessions
status: Done
assignee: []
created_date: '2026-10-21T09:26:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels:
  - hardening
dependencies: []
priority: low
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The 0.4.0 live runs checked only skill listing and loading. The session doctor's table-derived guidance and the guard's table-derived deny message were covered by hook tests, not seen in a live session. The isolated CODEX_HOME also still listed skills from outside it, so the Codex isolation method needs a fix before the run counts.

Impact on goal: doc-1 goals 1 and 2 on real harnesses.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 In a live Claude Code session and a live Codex session with only this plugin, the session doctor guidance lists the table's commands and an edit under .backlog/ is denied with the table-derived message; transcripts recorded in the task notes
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Live run (2026-10-21), claude 2.1.306 (Claude Code), codex-cli 0.163.0, Backlog.md 1.55.0. Scratch project <scratch>/builder-task23/proj (git init; backlog init demo --defaults --integration-mode none --auto-open-browser false --backlog-dir .backlog). After every run find .backlog -type f listed only config.yml. ~/.codex/config.toml and ~/.claude/settings.json mtimes were the same before and after.

Claude Code: CLAUDE_CONFIG_DIR=<scratch empty dir> claude -p --plugin-dir <repo>/plugins/backlog-extras --output-format stream-json --verbose --include-hook-events --permission-mode bypassPermissions --model haiku. init.plugins lists backlog-extras@inline 0.4.1 plus the cc-plugin-* builtins only. The SessionStart hook_response additionalContext (the model quoted it back verbatim) names all 9 table usages: "...adds or extends: `backlog decision view <id>` (print one decision file); ... `backlog task edit <id> --remove-dep X[,Y]` (remove only these dependencies)." Write .backlog/tasks/probe.md was rejected by the hook (tool_result_meta permission_decision source "hook"), and the tool_result reads: "PreToolUse:Write hook error: Backlog files are CLI-only. Use `backlog`, the backlog-extras wrapper, which adds or extends these Backlog.md commands: `backlog decision view <id>`, `backlog decision update <id> [--content MD] [--status S]`, `backlog decision remove <id>`, `backlog milestone view <id or title>`, `backlog milestone update <id or title> --description MD`, `backlog doc remove <id>`, `backlog doctor [--fix --yes]`, `backlog task edit <id> --add-dep X[,Y]`, `backlog task edit <id> --remove-dep X[,Y]`. Flags: `backlog <cmd> --help`." Transcript: (local log) task-23-claude-hooks-2026-10-21.jsonl

Codex, why skills from outside CODEX_HOME were listed (two causes, both proven): (1) Codex reads user-scope skills from $HOME/.agents/skills. With a scratch CODEX_HOME and the real HOME, codex debug prompt-input shows skill root r0 = ~/.agents/skills, giving agentsview-finding-history, herdr, ical-cli, rem-cli, use-railway and zed-cli-expert, which are exactly the 6 extra skills in task-14-codex-list. With a scratch HOME as well, that root disappears (task-23-codex-promptinput-realhome / -scratchhome-2026-10-21.json). (2) auth.json brings the ChatGPT account's remote-installed plugins. During a session Codex downloads them into $CODEX_HOME/plugins/cache/openai-curated-remote, and from the second session on their skills are listed (app-6a8d...:*, impeccable, pages, product-design, sites, work-pets: task-23-codex-homeonly-skills-rollout). [features] remote_plugin = false plus apps = false does not stop this (task-23-codex-flagsonly-skills-rollout).
Fix used: scratch HOME and scratch CODEX_HOME. auth.json is symlinked from ~/.codex/auth.json. config.toml has [features] hooks = true, remote_plugin = false, apps = false. Marketplace add of a git archive HEAD export (5992937) and plugin add backlog-extras@backlog-md-extras. Before the first session, an empty read-only (chmod 555) $CODEX_HOME/plugins/cache/openai-curated-remote. Then: codex exec --json --dangerously-bypass-hook-trust -m gpt-6-luna -s workspace-write -C <proj> ... </dev/null. Three sessions in a row then listed only the Codex built-in system skills (imagegen, openai-docs, skill-creator, skill-installer from $CODEX_HOME/skills/.system) plus backlog-extras:backlog-md (task-23-codex-skills1/skills2-2026-10-21.jsonl and the hooks rollout).

Codex evidence (task-23-codex-hooks-rollout-2026-10-21.jsonl, exec stream in task-23-codex-hooks-2026-10-21.jsonl): the SessionStart guidance reaches the model as a developer message, "Run it as `<CODEX_HOME>/plugins/cache/backlog-md-extras/backlog-extras/0.4.1/bin/backlog`, the backlog-extras wrapper: it passes every command to Backlog.md and adds or extends: ...", which names all 9 usages, each prefixed with that full path. apply_patch "*** Add File: .backlog/tasks/probe.md" and exec_command "printf probe > .backlog/tasks/probe2.md" were both denied with: "Command blocked by PreToolUse hook: Backlog files are CLI-only. Use `<wrapper full path>`, the backlog-extras wrapper, which adds or extends these Backlog.md commands: `<wrapper> decision view <id>`, ... `<wrapper> task edit <id> --remove-dep X[,Y]`. Flags: `<wrapper> <cmd> --help`." A per-usage grep found all 9 usages in the guidance and in both deny messages. The first two hooks prompts were refused by the model, which followed the skill's never-edit-board-files rule (task-23-codex-hooks-refused*). The third prompt stated an explicit user override for the test.
Command log: (local log) task-23-commands-2026-10-21.log
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Live Claude Code 2.1.306 (--plugin-dir, empty CLAUDE_CONFIG_DIR) and codex-cli 0.163.0 (scratch HOME and CODEX_HOME, read-only openai-curated-remote cache) sessions with only this plugin: the session doctor guidance names all 9 table usages and writes under .backlog/ (Write; apply_patch and shell) are denied with the table-derived reason. Codex leak causes: $HOME/.agents/skills and account plugins downloaded into CODEX_HOME. Transcripts in the notes.
<!-- SECTION:FINAL_SUMMARY:END -->
