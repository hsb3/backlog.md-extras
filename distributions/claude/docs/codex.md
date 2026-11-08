# Codex notes

Pick the Backlog.md skill from the skill list or type `$backlog-extras:backlog-md`.

Codex installs the plugin's hooks but runs them only after you approve them in
`/hooks`; until then the plugin supplies the skill only. Review `/hooks` again
after each update.

Codex does not put plugin `bin/` folders on PATH and gives hooks no environment
file, so plain `backlog` stays npm's. The session-doctor hook tells the agent the
wrapper's full path, and the added commands work only through it.

The backlog-guard hook runs before `apply_patch` and shell calls and denies
writes under the project's `.backlog/` folder. Codex 0.163.0 does not give hooks
a shell call's working directory, so a relative write run inside `.backlog/`
without naming it can get through.
