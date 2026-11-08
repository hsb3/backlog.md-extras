<p align="center"><img src="assets/icon.svg" width="64" height="64" alt=""></p>

<h1 align="center">Backlog Extras</h1>

<p align="center">CLI-only Backlog.md for agents, in Claude Code and Codex.</p>

Fills the gaps in [Backlog.md](https://github.com/MrLesk/Backlog.md) and corrects its undesirable behaviour, so agents manage a Backlog.md project through the CLI alone and never edit its files directly. This is an independent add-on: it claims no ownership or authorship of Backlog.md, which is the work of its author, MrLesk; thanks to them for it. Backlog.md's maintainers do not endorse or support it.

The repo is a plugin marketplace for Claude Code and Codex, `backlog-md-extras`, with one plugin, `backlog-extras`:

- **A `backlog` wrapper**, in the plugin's `bin/`: in Claude Code the session doctor puts it first on the agent's PATH, so the agent keeps using `backlog` as upstream's instructions say; in Codex the session doctor gives the agent the wrapper's full path. It prefers a managed Backlog.md install at a tested release, passes commands through and adds the missing commands below.
- **`backlog-guard`** (PreToolUse): denies direct writes to the project's `.backlog/` folder (Claude Code file tools, Codex `apply_patch`, and shell writes in both). A Bash command that genuinely needs a direct write (a repair, a migration, a test on a copy) can carry a per-command bypass, `BACKLOG_GUARD_BYPASS="<reason>" <cmd>`; the reason is required and logged.
- **`session-doctor`** (SessionStart): puts the wrapper first on PATH (Claude Code), warns when the real `backlog` is missing or not a tested release, lists the added commands for the agent, and tells it to load the skill below.
- **The `backlog-md` skill** (Claude Code and Codex list it as `backlog-extras:backlog-md`): the agent's Backlog.md instructions: upstream's workflow guides by pointer (`backlog instructions ...`), every added command, and no direct board edits.

Supported layout: only `.backlog/config.yml` at the project root (`backlog init --backlog-dir .backlog`, which the wrapper's `init` passes for you). A project using `backlog/` or a root `backlog.config.yml` gets a session-doctor warning every session, the guard stays off there, and the added commands exit 1 naming the supported layout.

Full design, gate and runbooks: the [spec](https://github.com/hsb3/backlog.md-extras/blob/main/.backlog/docs/doc-1%20-%20backlog.md-extras-spec.md), Backlog.md document doc-1 (`backlog doc view doc-1` in a checkout).

## Requirements

[requirements.json](requirements.json) is the machine-readable source for release identity, exact compatibility pins, dependency minimums, supported platforms and CI action references. The gate rejects drift in the manifests, wrapper, installer and workflow.

| Use | Required |
|---|---|
| Local hooks and wrapper | macOS or Linux, Bash 3.2+, Python 3.8+, jq 1.6+, the declared system utilities, and a Backlog.md release from the declared tested list |
| Terminal setup | Runtime requirements, Node 22+ and npm 10+ |
| Piped setup | Terminal setup requirements plus gh 2+ with GitHub access |
| Marketplace access | Git |
| Development gate | Runtime requirements, Python 3.9+, Git, Perl, ShellCheck, npm 10+, uv, and the exact Codex, Claude and OpenSpec pins in requirements.json |

Native Windows is unsupported; use WSL. Newer consumer host versions are not blocked, but the gate uses the declared exact versions. Missing or too-old runtime dependencies produce an actionable error; the write guard exits 2 rather than proceeding without a check. Properly configured hooks stay silent outside Backlog.md projects.

From a checkout, check prerequisites without installing anything:

```sh
python3 bin/check-requirements runtime
```

## Install

### Claude Code

Enable it in a Backlog.md project by committing this to the project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "backlog-md-extras": { "source": { "source": "github", "repo": "hsb3/backlog.md-extras" } }
  },
  "enabledPlugins": { "backlog-extras@backlog-md-extras": true }
}
```

Then, once per machine, from the project directory:

```sh
claude plugin install backlog-extras@backlog-md-extras --scope project
```

The settings alone only register the marketplace: without the install, a session gets no wrapper, no guard and no warning. Outside a project:

```sh
claude plugin marketplace add hsb3/backlog.md-extras
claude plugin install backlog-extras@backlog-md-extras
```

### Codex

Once per machine (the plugin's hooks stay silent outside a Backlog.md project, so a user-level install is safe):

```sh
codex plugin marketplace add hsb3/backlog.md-extras
codex plugin add backlog-extras@backlog-md-extras
```

Then start a new `codex` session and approve the plugin's two hooks in `/hooks`. Installation and enablement do not grant hook trust. Until approval, the plugin supplies skills but its hooks provide no guard or session guidance. Codex reports hooks needing review at startup.

Update between sessions with `codex plugin marketplace upgrade backlog-md-extras`, then start a new session and review `/hooks` again. Verified with Codex 0.163.0: this refreshes the installed plugin, including its cached files. Upgrade can remove the previous cache path; an existing session's absolute wrapper path can stop working. Restart after every update, even when no new trust prompt appears.

### Backlog.md itself

The plugin does not install Backlog.md. For release 0.7.0's pinned `backlog`, and the wrapper in a terminal (as `bl`, since `backlog` there is npm's), run (needs `gh` signed in):

```sh
gh api -H 'Accept: application/vnd.github.raw' 'repos/hsb3/backlog.md-extras/contents/install.sh?ref=v0.7.0' | sh
```

From a checkout: `./install.sh`. Piped setup resolves the release tag to one commit, then downloads the wrapper, skill, requirements and checker from that commit; it never mixes files from moving refs. For a reviewed branch or commit, set `BACKLOG_EXTRAS_REF` on the installer process; its release identity must still match, and the override is also resolved once. Release tags must be published before the one-liner is available.

Rerun setup after updating the plugin. Backlog.md installs into `../share/backlog-extras/upstream` beside the install dir, independent of the active Node version's global packages. Setup also installs the skill, requirements and checker under `../share/backlog-extras/` (by default `$HOME/.local/share/backlog-extras/`; for a symlinked install dir, beside its target). It verifies that the installed `bl` resolves the required pin.

The wrapper first checks the managed install beside the terminal wrapper and at `$HOME/.local/share/backlog-extras/upstream`, accepting any tested release there. If neither qualifies, it uses the first readable executable `backlog` on PATH, excluding other backlog-extras wrappers and mise shims that cannot run. An incompatible PATH copy still triggers the version guard when no managed tested release is available. Plain `backlog` in a terminal stays under its existing package manager.

## Commands

Any command the wrapper does not recognise goes to the real `backlog` unchanged. Added (in a terminal, type `bl` for `backlog`; `backlog --help` and `backlog <group> --help` list them after upstream's help):

| Command | Fills the gap |
|---|---|
| `backlog decision view <id>` | No way to show one decision |
| `backlog decision update <id> [--content MD] [--status S]` | Decision bodies cannot be edited (status also via upstream `decision edit -s`) |
| `backlog decision remove <id>` | Deletes a live decision in one step, releasing its ID; upstream archives first, then `decision delete` |
| `backlog milestone view <id or title>` | No way to read a milestone description |
| `backlog milestone update <id or title> --description MD` | The description is fixed after `milestone add` |
| `backlog doc remove <id>` | Deletes a live doc in one step, releasing its ID; upstream archives first, then `doc delete` |
| `backlog doctor [--fix --yes]` | Stock doctor checks archived tasks but not archived drafts, whose IDs Backlog.md still reuses; it also reports a leftover upstream instruction block in `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` or `.github/copilot-instructions.md` |
| `backlog task edit <id> --add-dep X[,Y]` | Upstream `--dep` replaces the whole dependency list; this adds to it (case and zero padding ignored) |
| `backlog task edit <id> --remove-dep X[,Y]` | Removes only the named dependencies; upstream can only replace or clear the list |

Plain `--dep` and `--depends-on` still replace the list as upstream does, and on a tested release print one stderr line naming any dependencies they drop. Corrected (same name, upstream behaviour changed; the `backlog-md` skill is the one source of agent instructions):

- `backlog init`: upstream defaults to a `backlog/` folder, writes its instruction block into `AGENTS.md` (and the other instruction files named) and can install a Claude Code agent. The wrapper refuses `--backlog-dir` other than `.backlog` and `--config-location root` before upstream runs, refuses a `backlog/` or `backlog.config.yml` project already in that directory, and in a new project appends `--backlog-dir .backlog` when none is given; any such flag makes upstream skip every setup prompt but the project name, so set the rest with init's flags or later with `backlog config`. It then runs upstream init and puts `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` and `.claude/agents/project-manager-backlog.md` back exactly as they were (deleting any it created), prints one line naming the files it reverted, and prints the skill text (not after a cancelled prompt). With `--agent-instructions none`, `--integration-mode mcp` or `--integration-mode none` init writes no instructions, so it runs with at most that flag added.
- `backlog agents --update-instructions`: prints the skill text instead of writing the block; upstream is not run.
- `backlog config` (the wizard, no subcommand): its last question installs the Claude Code agent; the wrapper removes it again and prints the skill text.

Projects that already carry the block need it removed by hand; `backlog doctor` names the files. The added and corrected commands refuse to run unless `backlog --version` is a release in `BACKLOG_TESTED` in the wrapper, because they edit Backlog.md's files directly. If no eligible `backlog` executable is found, the wrapper exits 127.

## Learn more

- [Supported hosts](docs/harnesses.md), [Claude Code notes](docs/claude.md), [Codex notes](docs/codex.md)
- [Privacy](docs/privacy.md) and [verifying releases](docs/releases.md)
- Developing: [agent guidelines](https://github.com/hsb3/backlog.md-extras/blob/main/AGENTS.md), [testing and host records](https://github.com/hsb3/backlog.md-extras/blob/main/TESTING.md). The wrapper accepts every Backlog.md release in requirements.json `tested`; the installer installs the one in `pins`. To add a release, follow "Upgrade Backlog.md" in the spec.

## Limits

- The guard's Bash check matches patterns rather than parsing shell; obfuscated writes get through and some harmless commands are denied. It ignores `.backlog` in heredoc bodies, in quoted prose and as a `cp`/`rsync` source; interpreters and nested shells (`python3`, `node`, `bash -c`, `eval` and the like) are denied whenever the command names `.backlog`. On a case-insensitive disk (the macOS default) `.BACKLOG/` counts as the board too.
- The bypass covers one Bash command: an empty reason is denied, the hook never reads the variable from its environment (exporting it does nothing), and each use is appended as a JSON line to `${XDG_STATE_HOME:-~/.local/state}/backlog-extras/bypass.log`; if that write fails, the command is denied.
- Codex: plain `backlog` stays npm's; the added commands work only through the wrapper's full path, which the session doctor gives the agent.
- Codex 0.163.0 does not expose a shell call's `workdir` to hooks. A relative write executed inside `.backlog/` without naming that folder in the command can escape this guard. MCP file editors are outside the current matcher, and later input sent through `write_stdin` is not checked again. This is a local editing guardrail, not a filesystem security boundary.
- The wrapper wins over npm's `backlog` in Claude Code only through the session doctor's `CLAUDE_ENV_FILE` PATH entry; when Claude Code provides no `CLAUDE_ENV_FILE`, the session doctor warns.
- Not covered: renaming a decision, changing a task's parent, restoring or deleting a draft, editing a single task comment.
