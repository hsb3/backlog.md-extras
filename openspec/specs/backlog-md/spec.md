# backlog-md Specification

## Purpose

Agents manage a Backlog.md board through the `backlog` CLI alone, with the
wrapper's added commands and a guard that refuses direct writes to the board.

## Requirements

### Requirement: Board edits go through the CLI
In a Backlog.md project the agent SHALL change the board only with `backlog`
commands, and a direct write to a file under `.backlog/` SHALL be refused by the
backlog-guard hook.

#### Scenario: Asked to edit a task file directly
- **WHEN** the user asks to rename a task by editing its markdown file
- **THEN** the direct write is refused or never attempted, and the title changes through `backlog task edit`
- **EVAL** evals/backlog-md/edits-board-through-cli

### Requirement: Board work loads the skill
For Backlog.md work the agent SHALL load the backlog-md skill and use the CLI
commands it names.

#### Scenario: Create a task with an acceptance criterion
- **WHEN** the user asks for a new task with an acceptance criterion
- **THEN** the agent loads the skill, creates the task with `backlog task create` and shows it with `backlog task view`
- **EVAL** evals/backlog-md/creates-task-with-cli

### Requirement: Stay out of unrelated requests
The skill SHALL NOT run for requests that are not Backlog.md work.

#### Scenario: Arithmetic question
- **WHEN** the user asks an unrelated question
- **THEN** the agent answers directly and runs no backlog command
- **EVAL** evals/backlog-md/ignores-unrelated-request
