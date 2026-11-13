---
name: backlog-md
description: Manages a Backlog.md project board (tasks, drafts, documents, decisions, milestones) through the `backlog` CLI, from finding and creating tasks to planning, implementing and finishing them. Use for any Backlog.md work, any `backlog` command, or any request about tasks or the board in a project with a `.backlog/` folder.
---

# Backlog.md

The board lives in `.backlog/` and records committed work: what will be built, fixed or changed. This guide is complete; you do not need `backlog instructions`.

## Rules

- Change the board only with `backlog` commands. Never create, edit, move or delete files under `.backlog/` with any tool; a hook denies those writes. The CLI keeps IDs, metadata, relationships and history consistent.
- In Codex, run every `backlog` command as the wrapper's full path given at session start; plain `backlog` there lacks commands this guide uses.
- Read before changing: `backlog task view TASK-123 --plain`. Use `--plain` for reading, `--json` for scripts (`task list`, `task view`, `draft list`, `decision list`, `search`; not with `--plain`).
- Run `backlog <command> --help` before an unfamiliar command or field, and to see the project's statuses: `backlog task edit --help`.
- Put text containing backticks in single quotes, so the shell passes it unchanged: `--ac 'Mentions `backlog init` literally'`.
- Write long or multi-line text (description, plan, notes, a document body) to a temp file and pass it as `--content "$(cat "$f")"`; run a helper script from a file too, not inline. Inline text naming the board can trip the write guard.
- Do not expand scope silently, and do not create or start follow-up tasks without the user's approval.

## Pick the workflow

- Question about the work: [Find work](#find-work).
- New work to track: [Create tasks](#create-tasks).
- Working on an existing task: [Work a task](#work-a-task), then [Finish a task](#finish-a-task).
- Documents, decisions, milestones: [Other records](#other-records).
- Skip creating a task for questions, exploration and obvious mechanical edits.

## Find work

```bash
backlog search "query" --plain
backlog task list --status "<todo status>" --plain
backlog task list --search "login" --labels frontend,bug --limit 20 --plain
backlog task view TASK-123 --plain
```

Filter rather than list everything: `--status`, `--exclude-status`, `--type`, `--assignee`, `--unassigned`, `--parent`, `--priority`, `--labels`, `--search`, `--limit`. `--count` gives the total; `--max-count` with `--skip` reads a long list in windows, and cut output ends with the command for the next window.

## Create tasks

1. Search first; the work may already be tracked.
2. Size it: one task if it fits one focused pull request a reviewer can take in at once. Otherwise split it.
3. Split by shape. One goal in one subsystem: a parent task and subtasks, `backlog task create -p TASK-10 "Wire IPC"` (`-p` takes a task ID only; use `-m` for a milestone). Independent components: separate tasks joined by dependencies, `backlog task create "Add bulk update UI" --dep TASK-21`.
4. Write each task so an agent with no conversation context can act on it:
   - a clear title;
   - a description of why it exists: the problem or need, and context the code cannot show. Do not restate the acceptance criteria;
   - acceptance criteria (`--ac`, repeated): testable, independent behaviour, edge cases where relevant; not implementation steps;
   - `--ref`, `--doc`, `--dep` where needed; `-a` for a known owner (`-a ""` leaves it unassigned); `--dod` only for extra completion checks this task needs.
5. Add no implementation plan; the worker writes it after research. Exception: work created already in an active status may carry its current plan.
6. Report the new IDs, titles and key criteria to the user.

```bash
backlog task create "Add project search" \
  -d "Finding anything takes three commands, and matches in the ones you skip are missed silently." \
  --ac "Search returns matching tasks by title and description" \
  --ac "Tests cover task, document and decision results"
```

## Work a task

1. `backlog task view TASK-123 --plain`. Check status, criteria, dependencies and references, and that the task is ready and in scope. In its Dependency Graph, an `unknown task ID` or `ambiguous task ID` is unresolved, not satisfied: run `backlog doctor`.
2. Start it: `backlog task edit TASK-123 -s "<active status>" -a @your-name`.
3. Research the current code and tests; do not trust an approach suggested at creation.
4. Record the plan: `backlog task edit TASK-123 --plan "1. ..."`. If it holds a product, architecture or workflow decision, or review was requested, present it and wait for approval.
5. Work in slices: implement, run the checks, then `--append-notes "What changed and what was verified"`. Questions for review go in `--comment "..." --comment-author @your-name`.
6. When the approach changes, replace the plan with `--plan` or add steps with `--append-plan`.

Editing a task:

- Dependencies: `--dep` replaces the whole list. To change one, use:
- `backlog task edit <id> --add-dep X[,Y]`: add dependencies, keeping the current ones.
- `backlog task edit <id> --remove-dep X[,Y]`: remove only these dependencies.
- Acceptance criteria: `--acceptance-criteria`, repeated, replaces the list; matching text keeps its check state. Check or uncheck with `--check-ac`/`--uncheck-ac` in a separate edit.
- Linked documents: `--add-doc`/`--remove-doc` change entries, `--doc` replaces the list, `--clear-docs` empties it; do not mix the two kinds.
- If replacing a description, plan, notes or summary is refused because its boundary is ambiguous, stop: ask the user to add the BEGIN and END markers the error names, then retry. Appending still works.

Out-of-scope work you discover: ask whether to add it to this task or create a follow-up. With subtasks, finish them one at a time, each with its own plan, notes, checked criteria and summary; continue to the next only if the user assigned the whole series.

## Finish a task

- [ ] Re-read the task and find evidence for every acceptance criterion and Definition of Done item.
- [ ] Run the tests and checks; exercise UI or interactive behaviour for real. Code, grep output and intent are not evidence.
- [ ] Check only proven items: `backlog task edit TASK-123 --check-ac 1 --check-dod 1`. Fix failures first.
- [ ] Make the recorded plan match what was built; record decisions and results with `--append-notes`.
- [ ] `--final-summary "..."`: what changed, why, how it was verified, risks and follow-ups.
- [ ] After any review the user requires: `-s "<terminal status>"`.

A parent finishes only when all its subtasks are done.

## Archive, restore, delete

- Finished tasks stay on the board until cleanup. `backlog task archive TASK-123` takes any task off the board (finished, canceled, duplicate, invalid); it keeps its ID and links, and becomes read-only, so finish notes first.
- `backlog task restore TASK-123` brings it back with its ID and status; restore before editing.
- `backlog task delete TASK-123` permanently removes an archived task, releases its ID and removes links to it. Use it only for work that should leave no record. A task with existing subtasks is not deleted.
- Drafts: archived draft IDs get reused. In a project with archived drafts, run `backlog doctor` after `backlog draft create` or `backlog task demote` and resolve any collision it reports.
- `backlog doctor [--fix --yes]`: check for duplicate or reused IDs, broken dependencies and stray Backlog.md instruction blocks.

## Other records

Documents: `backlog doc create "Title"`, `backlog doc view doc-1`, `backlog doc update doc-1 --content "Markdown"`. Decisions: `backlog decision create "Title"`, `backlog decision list`. Milestones: `backlog milestone add "Name"`, `backlog milestone list`; assign a task with `-m`.

- `backlog decision view <id>`: print one decision file.
- `backlog decision update <id> [--content MD] [--status S]`: replace a decision's body and/or status.
- `backlog decision remove <id>`: delete a live decision, releasing its ID.
- `backlog milestone view <id or title>`: print one milestone file.
- `backlog milestone update <id or title> --description MD`: replace a milestone's description.
- `backlog doc remove <id>`: delete a live doc, releasing its ID.

`archive` keeps a document or decision readable and its ID reserved; `restore` brings it back. Tasks that link a removed or archived file are listed, not changed.

## When a command refuses

- Not a tested Backlog.md release, or a project not using `.backlog/config.yml` at its root: tell the user the error; do not migrate or reinstall unasked.
- `.backlog/config.yml does not parse`: tell the user the line it names and ask them to repair the file; do not edit it yourself.
- Write denied under `.backlog/`: do it with the CLI. Only for a repair, migration or test on a copy that the user wants, prefix that one Bash command with `BACKLOG_GUARD_BYPASS="<reason>"`; every use is logged.
