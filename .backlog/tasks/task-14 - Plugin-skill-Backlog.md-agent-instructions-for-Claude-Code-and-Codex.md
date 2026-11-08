---
id: TASK-14
title: 'Plugin skill: Backlog.md agent instructions for Claude Code and Codex'
status: Done
assignee: []
created_date: '2026-10-21T05:29:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels: []
milestone: m-2
dependencies:
  - TASK-13
priority: medium
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision 11 in doc-1. The skill replaces upstream's AGENTS.md/CLAUDE.md block as the one instruction source. It says what that block says (run `backlog instructions overview` at the start of Backlog.md work, the task-creation, task-execution and task-finalization guides before those steps, `backlog <command> --help` before unfamiliar commands, never edit board files), points at upstream's guides rather than copying them so they follow the pin, and adds the added commands and the doctor-after-draft rule. Codex plugin manifests carry `"skills": "./skills/"` (seen in OpenAI-curated plugins on codex-cli 0.163.0); loading from this plugin is untested.

Impact on goal: doc-1 goal 1; agents get the extras and house rules from one source instead of 0 (upstream block) plus the session doctor's paragraph.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A gate check fails when the skill omits a command in the wrapper's table (task-13); watched failing
- [x] #2 Live proof in Codex (isolated CODEX_HOME): the skill is listed and loads; if Codex cannot load plugin skills, that and the chosen fallback are recorded in doc-1
- [x] #3 The session doctor's guidance names the skill and tells the agent to load it before Backlog.md work; its hook test covers this
- [x] #4 plugins/backlog-extras/skills/<name>/SKILL.md exists, at most 80 lines; both manifests register it; `claude plugin validate --strict` passes for the plugin and the marketplace
- [x] #5 Live proof in Claude Code: a session in a scratch Backlog.md project with the plugin installed lists the skill and loads it on a Backlog.md request; transcript location recorded in the task notes
- [x] #6 doc-1 sections 3 (layout gains skills/), 6 (the upstream block no longer names the CLI; the skill does) and 8 (the skill coverage check) updated
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Proof (2026-10-21):
- AC1: scripts/check_commands.py gains a SKILL.md check (each `backlog <usage>` from the wrapper table, backticked). Watched failing: before SKILL.md existed it printed "FAIL .../skills/backlog-md/SKILL.md: missing" (rc=1); on a SKILL.md copy without the --remove-dep line: "FAIL <tmp>/SKILL.md omits `backlog task edit <id> --remove-dep X[,Y]`" (rc=1). Real SKILL.md: rc=0.
- AC4: plugins/backlog-extras/skills/backlog-md/SKILL.md, 44 lines (wc -l). "skills": "./skills/" in .claude-plugin/plugin.json and .codex-plugin/plugin.json. claude plugin validate . --strict and plugins/backlog-extras --strict: both "Validation passed" (directory profile LICENSE/icon notes are advisory, unchanged by this task).
- AC3: session-doctor guidance now says "load the `backlog-md` skill (listed as `backlog-extras:backlog-md`) before any Backlog.md work". test.sh asserts it in the pinned and codex cases; watched failing against the old hook: "FAIL pinned: ... and the skill" and "FAIL codex: ... and the skill", then 9/9 ok.
- AC5 (Claude Code 2.1.306, CLAUDE_CONFIG_DIR empty scratch dir, --plugin-dir, scratch project <scratch>/builder14/proj): (local log) task-14-claude-list-2026-10-21.jsonl result lists "`backlog-extras:backlog-md`"; (local log) task-14-claude-load-2026-10-21.jsonl has tool_use {"name":"Skill","input":{"skill":"backlog-extras:backlog-md"}} then Bash "backlog instructions overview; echo ---; backlog task list --plain".
- AC2 (codex-cli 0.163.0, isolated CODEX_HOME, marketplace add of an rsync copy + plugin add): (local log) task-14-codex-list-2026-10-21.jsonl agent message lists "backlog-extras:backlog-md"; (local log) task-14-codex-load-2026-10-21.jsonl runs "cat <CODEX_HOME>/plugins/cache/backlog-md-extras/backlog-extras/0.3.1/skills/backlog-md/SKILL.md" (exit 0), then "<wrapper full path> instructions overview" and "<wrapper full path> task list --plain". Codex loads plugin skills, so no fallback needed.
- AC6: doc-1 updated via doc update (body roundtrip verified): sections 2 (surfaces get the skill), 3 (skills/backlog-md/SKILL.md, manifest skills field, check_commands.py scope), 6 (skill paragraph: the skill, not the upstream block, teaches the CLI; live verification), 8 (steps 3 and 5).
- ./gate.sh exit 0.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added the backlog-md plugin skill (Backlog.md agent instructions: upstream guides by pointer, every added command, --add-dep vs --dep, doctor after draft create/task demote, no direct board edits), registered in both manifests; check_commands.py fails when SKILL.md omits a wrapper usage; session doctor tells the agent to load the skill; doc-1 and README updated; live-proven loading in Claude Code 2.1.306 and codex-cli 0.163.0.
<!-- SECTION:FINAL_SUMMARY:END -->
