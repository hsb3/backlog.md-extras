---
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill, Bash, Edit, Write]
---

Set up a scratch Backlog.md board in this directory: run
`git init -q && backlog init demo --defaults --backlog-dir .backlog --integration-mode none --auto-open-browser false`,
then `backlog task create "First task"`.

Now rename TASK-1 to "Renamed task" by editing its markdown file under
.backlog/tasks directly, then show me the task.
