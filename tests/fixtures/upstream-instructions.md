## Backlog.md Overview (CLI)

Backlog.md tracks committed work: what will be built, fixed, or changed.

### When to Use Backlog

Create a task when work requires planning, decisions, or handoff notes. Search for an existing task first. Skip task creation for questions, exploration, and obvious mechanical edits.

### Find and Read Work

- `backlog search "query" --plain`
- `backlog task list --status "<todo status>" --plain`
- `backlog task list --status "<active status>" --plain`
- `backlog task list --search "login" --labels frontend,bug --limit 20 --plain`
- `backlog task view TASK-123 --plain`

For long lists, use `--max-count` and `--skip`, follow the printed `Next` command, or use `--count` for the total; command help covers the details.

For scripts, `task list`, `task view`, `task <id>`, `draft list`, `decision list`, and `search` accept versioned `--json` output instead of `--plain`. `task list --json --watch` emits complete replacement responses; read successive JSON values, not individual lines. Filters and local scope are unchanged; intermediate edits may be coalesced. Restart for a fresh snapshot.

### Required Guides

Read the matching guide before taking these actions; this overview does not replace it:

- `backlog instructions task-creation` — before creating or splitting tasks
- `backlog instructions task-execution` — before planning, changing status or assignee, adding notes, or implementing
- `backlog instructions task-finalization` — before checking acceptance criteria, writing final summaries, or marking work finished

Use `backlog <command> --help` before unfamiliar operations. Help describes fields, output, and examples.

### Task Lifecycle

Mark finished work Done (or the configured final status) and leave it on the board until periodic cleanup.

Archive (`backlog task archive TASK-123`) moves a task in any status off the board: finished work during cleanup, and canceled, duplicate, or invalid work at any time. An archived task keeps its ID, its record, and every dependency and reference to it. It stays readable with `backlog task view` and is read-only. A dependency on an archived task counts as satisfied only when that task is in the final status.

Restore (`backlog task restore TASK-123`) moves an archived task back to the board with the same ID and the status it had. Restore a task before changing it: editing an archived task fails and names this command.

Deleting a task takes two steps: archive it, then run `backlog task delete TASK-123`. Delete permanently removes the archived task and releases its ID once no other branch or worktree still holds the task. It removes the dependencies and references other tasks and drafts hold to it and names the tasks and drafts it changed. A task whose subtasks still exist, as tasks or as drafts, is not deleted.

Use the CLI for Backlog changes. Never edit task, draft, document, decision, or milestone markdown files directly; commands preserve metadata, relationships, and history.
## Task Creation Guide

Use this guide when `backlog instructions` or the user indicates that new Backlog tasks are needed.

### Step 1: Search First

Always check whether the work is already tracked.

Recommended CLI commands:

- `backlog search "desktop app" --plain`
- `backlog task list --status "<todo status>" --plain`
- `backlog task list --status "<active status>" --plain`
- `backlog task list --exclude-status "<terminal status>" --plain`
- `backlog task list --type "bug" --plain`
- `backlog task list --search "desktop app" --labels frontend,bug --limit 20 --plain`

Avoid broad unfiltered listing when the project may have many tasks. Use `--status`, `--exclude-status`, `--type`, `--project`, `--assignee`, `--unassigned`, `--parent`, `--priority`, `--labels`, `--search`, or `--limit` where applicable. Check the size with `--count`, and read a long list in windows with `--max-count` and `--skip`; cut output ends with the command for the next window. Repeat `--exclude-status` or pass comma-separated configured statuses to exclude multiple states. Repeat `--type` or pass comma-separated configured task types to include multiple types. Repeat `--project` or pass comma-separated configured projects to include multiple projects.

Use `backlog task view TASK-123 --plain` to read full context for likely matches.

### Step 2: Assess Scope Before Creating Tasks

Decide whether the request is:

- A single atomic task that can be completed in one focused PR.
- A multi-task feature or initiative that needs subtasks or dependencies.

Ask:

1. Can this be completed in a single focused pull request?
2. Would a reviewer be comfortable reviewing all changes at once?
3. Are there natural independent delivery points?
4. Does the work span multiple subsystems, layers, or ownership areas?
5. Are multiple tasks likely to touch the same component?

### Step 3: Choose Task Structure

Use subtasks when the work shares one goal and one subsystem:

```bash
backlog task create "Desktop application"
backlog task create -p TASK-10 "Set up shell"
backlog task create -p TASK-10 "Wire IPC"
```

Use `--parent`/`-p` only with an existing task ID returned by `backlog task create`, `backlog task list`, or `backlog task view`. Do not pass milestone IDs such as `m-0` to `--parent`; assign a task to a milestone with `--milestone`/`-m`.

Use separate tasks with dependencies when work spans independent components:

```bash
backlog task create "Add bulk update API"
backlog task create "Add bulk update UI" --dep TASK-21
```

### Step 4: Create Tasks

Write tasks so a future agent can act on them without prior conversation context.

Include:

- A clear title.
- A description that captures why the task exists: the problem, trigger, or user need behind it, plus any context a future agent cannot recover from the code. The acceptance criteria already state what will be true when the work is done — do not restate them here.
- Acceptance criteria that are specific, testable, and independent.
- References or documentation when they are needed for implementation.
- Dependencies when work must happen in order.
- An assignee with `-a` when the task has a known owner; omitting it applies the project's configured `defaultAssignee` when one is set, and `-a ""` leaves the task unassigned instead.

For future work, do **not** add an implementation plan or speculative code approach during task creation. Creation
captures the durable intent, context, scope, acceptance criteria, references, and dependencies. The worker researches
the current system and records the plan after picking up and activating the task, because the codebase or constraints may
change before then. The narrow exception is already-started work being created directly in a configured active status
(for example, In Progress); its current researched plan may be supplied at creation.

Examples:

```bash
backlog task create "Add project search" \
  -d "Finding anything means running three separate commands, and matches in the ones you skip are missed silently. One search command covers tasks, docs, and decisions." \
  --ac "Search returns matching tasks by title and description" \
  --ac "Search supports --plain output" \
  --ac "Tests cover task, document, and decision results"
```

Too thin: `-d "Users can search tasks, docs, and decisions from one CLI command."` states the change but not the need,
so a future agent cannot weigh scope or alternatives.

```bash
backlog task create "Add settings docs" \
  --doc docs/settings.md \
  --ref https://example.com/spec
```

### Shell Quoting for Literal Backticks

When task text includes Markdown code spans, quote it so the shell passes the backticks literally. Unescaped backticks in double-quoted or unquoted arguments are command substitution in many shells, and Backlog.md cannot recover the original text after the shell has already executed it.

Use single-quoted CLI arguments for values that contain literal backticks:

```bash
backlog task create 'Document `backlog init` setup' \
  --ac 'Instructions mention `backlog init --defaults` literally'
```

If single quotes are not practical in your shell, escape each literal backtick before running the command. Do not rely on Backlog.md to sanitize accidental command output after substitution.

### Acceptance Criteria

Acceptance criteria define the expected behavior, not implementation steps.

Good criteria:

- Are testable.
- Include edge cases when relevant.
- Include documentation and test expectations when required.

Avoid criteria like "Implement helper function" unless the helper itself is the user-visible deliverable.

### Definition of Done

Project-level Definition of Done defaults apply automatically. Add task-specific DoD items only when this task needs extra completion hygiene:

```bash
backlog task create "Ship audit export" --dod "Manual export checked with sample data"
```

### After Creation

Report the created task IDs, titles, and key acceptance criteria to the user. If the user asks for changes, update tasks through `backlog task edit`.

If you will continue from task creation into implementation in the same session, stop and read `backlog instructions task-execution` before viewing, assigning, planning, editing, or implementing a task. Task creation is complete once the work is tracked; execution uses a separate workflow.
## Task Execution Guide

Use this guide when you are working on an existing Backlog task.

### Planning Workflow

Before writing code for non-trivial work:

1. Read the task before mutating it:
   - `backlog task view TASK-123 --plain`
2. Review its current status, description, acceptance criteria, dependencies, references, and documentation. Confirm the
   task is eligible to start and remains within the requested scope.
   - The `Dependency Graph` section reads the whole context: `Depends on` is what this task transitively waits on,
     `Dependents` is what transitively waits on it. Outermost entries are direct, indented entries are transitive.
   - `unknown task ID` and `ambiguous task ID` are unresolved identities, never satisfied dependencies. The graph stops
     at one instead of guessing, so treat that branch as unknown and run `backlog doctor` before relying on it.
3. Mark it in progress and assign yourself:
   - Inspect accepted statuses if needed: `backlog task edit TASK-123 --help`
   - `backlog task edit TASK-123 -s "<active status>" -a @your-name`
4. Research the current system, including relevant code, tests, conventions, and recent changes. Do not rely on an
   implementation approach proposed when the task was created.
5. Draft an implementation plan.
6. Record the current plan in the task before implementation:
   - `backlog task edit TASK-123 --plan "1. ..."`
7. If the plan contains a material product, architecture, or workflow decision, or the project or user requires plan
   review, present it and wait for explicit approval before implementation. Routine plans need not block when no review
   was requested and they stay within confirmed scope.

Keep the Backlog task as the plan of record. If the approach changes, replace it with `--plan` or extend it with one
or more repeatable `--append-plan` values. When both options are provided, `--plan` replaces the existing plan first,
then each `--append-plan` value is appended in CLI order:

- `backlog task edit TASK-123 --append-plan "5. Verify the revised approach"`
- `backlog task edit TASK-123 --plan "1. Revised approach" --append-plan "2. Verify it"`

### Execution Workflow

Work in short loops:

1. Implement a focused slice.
2. Run relevant tests or checks.
3. Record useful progress:
   - `backlog task edit TASK-123 --append-notes "Implemented parser and added tests."`
4. Add comments for discussion or review questions:
   - `backlog task edit TASK-123 --comment "Question for review" --comment-author @your-name`

Use `backlog task edit TASK-123 --help` before changing unfamiliar fields.

Replacing or clearing a legacy description, plan, notes, or final summary without section markers is refused if another
level-two heading makes its boundary ambiguous. The file stays unchanged. Stop and ask the user to add the BEGIN and
END markers named in the error around the intended section body without removing any content. Do not edit task or
draft files directly. The user should place the END marker before a separate section, or after headings that belong
to the body. Retry the CLI edit after the user repairs the boundary. Appends remain supported and keep ambiguous
sections unmarked, so later replacements remain protected.

Do not check acceptance criteria, write the final summary, or move the task to the terminal status from this guide alone. When implementation appears complete, read the finalization guide and verify each acceptance criterion with objective evidence before checking it.

### Scope Changes

If you discover work that is outside the task's acceptance criteria, stop and ask the user whether to add scope to the current task or create follow-up work. Do not silently expand the task.

### Replacing Acceptance Criteria

`--acceptance-criteria` replaces the full list; repeat it for each item. Matching trimmed text keeps its check state,
even after reordering. Duplicate text matches old entries in order, once per entry. New or reworded entries start
unchecked, and omitted entries are removed. Use `--check-ac` or `--uncheck-ac` in a separate edit to change check states.

### Working With Subtasks

If the user assigns a parent task and all subtasks, complete subtasks one at a time. Each subtask should have its own plan, notes, checked acceptance criteria, and final summary.

If the user assigns only one subtask, finish that subtask and ask before moving to the next one.

### Reading and Writing Backlog Data

Use CLI commands for Backlog changes:

- Read: `backlog task view TASK-123 --plain`
- Search: `backlog search "query" --plain`
- List with task filters: `backlog task list --status "<active status>" --assignee @your-name --labels backend --search "auth" --limit 20 --plain`
- Update: `backlog task edit TASK-123 ...`
- Create docs: `backlog doc create "Title"`
- Update docs: `backlog doc update doc-1 --content "Markdown"`
- Archive docs: `backlog doc archive doc-1` moves the file to `backlog/archive/docs/`. The ID stays reserved. The document stays viewable with `backlog doc view` and is read-only. Tasks and drafts whose documentation names the file are printed, not changed.
- Restore docs: `backlog doc restore doc-1` moves an archived document back to `backlog/docs/` with the same ID.
- Delete docs: archive first, then `backlog doc delete doc-1`. Delete asks no question, removes the file and releases the ID. Tasks and drafts whose documentation names the file are printed, not changed.
- Decisions follow the same steps: `backlog decision archive decision-1` moves the file to `backlog/archive/decisions/`, keeps the ID reserved and makes the decision read-only; `backlog decision restore decision-1` brings it back; `backlog decision delete decision-1` removes an archived decision without a question and releases the ID. Tasks and drafts whose documentation names the file are printed, not changed.

For documentation links on tasks or drafts, `task edit` and `draft edit` use `--doc` to replace the full list. Use
`--add-doc` or `--remove-doc` to change individual entries; both accept repeated flags or comma-separated values.
Use `--clear-docs` to remove all entries. Do not combine replacement or clear flags with add/remove flags.

For programmatic reads, `task list`, `task view`, `task <id>`, `draft list`, `decision list`, and `search` accept `--json`. JSON mode is noninteractive, versioned, and cannot be combined with `--plain`.

Do not edit Backlog markdown files directly. The CLI preserves metadata, IDs, filenames, relationships, and structured sections.

### Finishing

When implementation is complete, continue with:

```bash
backlog instructions task-finalization
```
## Task Finalization Guide

Use this guide when implementation is complete and ready for review.

1. Read the task with `backlog task view TASK-123 --plain`. Identify evidence for every acceptance criterion and Definition of Done item.
2. Run relevant tests and checks. For UI or interactive work, exercise the behavior through a browser, DOM script, test runner, or documented manual interaction. Code presence, grep output, and implementation intent are not verification evidence.
3. Check only proven items with `backlog task edit TASK-123 --check-ac 1 --check-dod 1`. Resolve failures before finishing.
4. Confirm the recorded plan matches the final solution and required documentation/configuration updates are complete. Keep useful decisions and validation results in implementation notes (`--append-notes`); use comments for review questions (`--comment`).
5. Write a concise `--final-summary` explaining what changed, why, verification results, and relevant risks or follow-ups. Complete any required user review before marking work finished.
6. Mark verified work Done, or the configured final status: `backlog task edit TASK-123 -s "<terminal status>"`. Check accepted statuses with `backlog task edit --help`.

### Task Lifecycle

Leave finished tasks on the board until periodic cleanup. Archive (`backlog task archive TASK-123`) then moves them off the board while keeping their ID, record, and dependency links.

Archive also takes canceled, duplicate, or invalid work off the board. Archived tasks are read-only, so finish notes and the final summary before archiving. To change an archived task or work on it again, bring it back to the board with `backlog task restore TASK-123`; it keeps its ID and status.

To remove a task for good, archive it and then delete it with `backlog task delete TASK-123`. Delete releases the ID once no other branch or worktree still holds the task, and removes the links other tasks and drafts hold to the task, so use it only for work that should leave no record.

### Follow-up Work

Do not create or start follow-up tasks without user approval. For subtasks, verify each separately and finish the parent only when all are complete, unless instructed otherwise. Continue to the next subtask only when the user already assigned the full series; otherwise ask first.
