# Privacy

This plugin is a skill, a command-line wrapper and two local hooks. It runs
inside your coding agent with that agent's model, permissions and data handling.
It collects no telemetry and sends nothing anywhere. The wrapper runs your local
Backlog.md; the terminal installer and `install.sh` download from GitHub and npm
only when you run them.

The guard's bypass, `BACKLOG_GUARD_BYPASS="<reason>" <command>`, appends the time,
project, command and reason to `${XDG_STATE_HOME:-~/.local/state}/backlog-extras/bypass.log`
on your machine.
