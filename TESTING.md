# Testing

| Tier | Command | Needs | Proves |
| --- | --- | --- | --- |
| Gate | `bin/gate` | The development requirements and exact host pins in `requirements.json` (Backlog.md, Claude Code, Codex, OpenSpec), uv, npm, jq, ShellCheck | Wrapper self-test on every tested Backlog.md release, hook behavior, setup failures, installer, Codex install/upgrade/rejection in a throwaway `CODEX_HOME`, strict Claude and OpenSpec validation, manifests agree, runtimes are lean, reproducible and current, every spec scenario names an existing eval |
| Unit only | `bin/gate tests/unit` | uv | The pytest part of the gate that needs no host CLI |
| Behavior | `claude plugin eval . --runs 1 --no-publish --allow-tools Bash Write Edit --trust-plugin` | Claude login, Backlog.md on PATH; uses model quota | The skill routes, the agent uses the CLI, and the guard keeps it off the board files, against a no-plugin baseline |
| Live Codex | `PLUGIN_LIVE=1 bin/gate tests/integration` | Codex login; uses model quota | The installed skill is discovered and read in a real `codex exec` turn |

CI runs the gate on macOS and Linux. Behavior and live tiers run locally before a
release; record each run below.

## Host record

| Host | Version | Date | Commit | Install | Behavior | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Claude Code | 2.1.310 | 2026-11-08 | factory-port working tree | Pass | Not run | `bin/gate`: strict validation of the repo, marketplace and `distributions/claude`. An isolated `CLAUDE_CONFIG_DIR` install from a local marketplace took its version from `.claude-plugin/plugin.json`, not the portable `plugin.json`. Behavior evals did not start: on the development Mac the eval sandbox refuses Bash because of the size of `~/.docker`; on a second Mac over SSH, claude was not logged in. |
| Codex CLI | 0.163.0 | 2026-11-08 | factory-port working tree | Pass | Not run | `scripts/check_codex.py`: installed files equal `distributions/openai`, skill discovered, Git upgrade refreshes files, a malformed `.codex-plugin/plugin.json` is rejected. Probe: with a portable `plugin.json` in the runtime, Codex read it instead of `.codex-plugin/plugin.json` (and so would drop the hooks); the Codex runtime now leaves it out. Hooks not exercised in a live session. |
| Backlog.md | 1.54.0, 1.55.0-1.55.3 | 2026-11-08 | factory-port working tree | Pass | n/a | Wrapper self-test, 147 checks, on each tested release; 1.53.0 fails the archived-ID check and is not listed. |
