# Claude Code notes

The `backlog-md` skill is `/backlog-extras:backlog-md`; Claude also loads it on
its own for Backlog.md work.

At session start in a Backlog.md project, the session-doctor hook writes the
plugin's `bin/` to the front of PATH through `CLAUDE_ENV_FILE`, so `backlog` in
the agent's Bash calls is the wrapper. Without `CLAUDE_ENV_FILE` the hook warns
and names the wrapper's full path instead. The doctor also warns when the real
`backlog` is missing or not a tested release.

The backlog-guard hook runs before Edit, Write, MultiEdit, NotebookEdit and Bash,
and denies writes under the project's `.backlog/` folder. Both hooks stay silent
outside a Backlog.md project. This plugin adds no permission rules.

Local test without installing: `claude --plugin-dir distributions/claude`.
