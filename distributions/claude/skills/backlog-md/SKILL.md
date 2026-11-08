---
name: backlog-md
description: How to work a Backlog.md board through the `backlog` CLI. Load before any Backlog.md work - viewing, creating, editing or finishing tasks, drafts, milestones, decisions or docs, running any `backlog` command, or working in a project with a `.backlog/` folder.
---

# Backlog.md

This project is managed with Backlog.md, through its `backlog` CLI only.

In Claude Code, `backlog` is the backlog-extras wrapper: it passes every command to Backlog.md and adds the commands below. In Codex, plain `backlog` is upstream's without them, so run every `backlog` command here as the wrapper's full path, which the session doctor names at session start.

## Upstream's workflow

The guides below come from the installed Backlog.md, so they always match its version. Read them; do not rely on memory of them.

- At the start of Backlog.md work in a conversation, run `backlog instructions overview` once, before answering or acting. It says when to search, read, create or update tasks.
- Before creating or splitting tasks: `backlog instructions task-creation`.
- Before planning, changing status or assignee, adding a plan or notes, or implementing task work: `backlog instructions task-execution`.
- Before checking acceptance criteria, writing final summaries, or moving tasks to a terminal status: `backlog instructions task-finalization`.
- Before an unfamiliar command: `backlog <command> --help`. Help shows options, fields and examples, then any commands backlog-extras adds to that group.

## Never edit board files

Do not create, edit, move or delete task, draft, document, decision or milestone files under the backlog folder, by any tool. Use the CLI, so metadata, relationships and history stay consistent. The backlog-guard hook denies direct writes there.

backlog-extras supports only `.backlog/config.yml` at the project root; in any other Backlog.md layout its added commands refuse to run and the session doctor says so.

Only for a legitimate direct operation (a repair, a migration, a test on a copy), prefix that one Bash command with `BACKLOG_GUARD_BYPASS="<reason>"`; give a real reason, since every use is logged.

## Added commands

backlog-extras fills these gaps in Backlog.md:

- `backlog decision view <id>`: print one decision file.
- `backlog decision update <id> [--content MD] [--status S]`: replace a decision's body and/or status.
- `backlog decision remove <id>`: delete a live decision, releasing its ID.
- `backlog milestone view <id or title>`: print one milestone file.
- `backlog milestone update <id or title> --description MD`: replace a milestone's description.
- `backlog doc remove <id>`: delete a live doc, releasing its ID.
- `backlog doctor [--fix --yes]`: stock doctor, then archived draft IDs reused by live drafts and leftover upstream instruction blocks.
- `backlog task edit <id> --add-dep X[,Y]`: add dependencies, keeping the current ones.
- `backlog task edit <id> --remove-dep X[,Y]`: remove only these dependencies.

Dependencies: `--dep` and `--depends-on` replace a task's whole dependency list, and the wrapper prints a stderr line naming any they drop. To add one dependency, use `--add-dep`; to drop one, `--remove-dep`.

Draft IDs: Backlog.md reuses the IDs of archived drafts. Run `backlog doctor` after `backlog draft create` or `backlog task demote` in a project with archived drafts, and resolve any collision it reports.

The added commands run only against the Backlog.md releases the wrapper is tested against; on any other they exit 1 naming the found and tested versions, and the session doctor warns at session start.
