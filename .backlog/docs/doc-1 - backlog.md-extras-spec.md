---
id: doc-1
title: backlog.md-extras spec
type: specification
created_date: 2026-10-20 00:39
updated_date: '2026-11-09T02:45:00Z'
---
Status: accepted 2026-10-18; one CLI name (decision 6) added the same day; Codex support (decision 7) added 2026-10-19; moved from `docs/spec.md` into Backlog.md as doc-1 the same day. Scope widened 2026-10-21 (decision 9). One supported layout, the guard's narrowed Bash match and its per-command bypass added the same day (decisions 14-17). Upstream: [MrLesk/Backlog.md](https://github.com/MrLesk/Backlog.md), which does not take outside changes, so every augmentation lives here as a wrapper. CLI only: no MCP server.

Scope: the wrapper fills gaps (operations Backlog.md lacks) and corrects undesirable upstream behaviour (denies or rewrites selected upstream commands). Each correction is listed in the spec with its reason; anything not listed passes through unchanged.

## 1. Goal

Agents manage a Backlog.md project through a CLI alone, with no direct file edits, and every operation they need is available.

One layout is supported: `.backlog/config.yml` at the project root (decision 14). Any other Backlog.md layout (a `backlog/` folder, or a root `backlog.config.yml`, which upstream writes for any custom `--backlog-dir` or `--config-location root`) gets a loud session-doctor warning every session and added commands that exit 1 naming the supported layout, never silent half-support.

Done when, in a consumer project with the plugin enabled:

1. Every operation in section 4 runs through `backlog`, the one CLI name an agent sees; none needs a file edit.
2. In a supported project, a direct write under `.backlog/` by a Claude Code or Codex agent is denied (section 5), unless that one Bash command carries a bypass whose reason is logged.
3. Running against an untested Backlog.md release fails loudly before any wrapper file write.
4. A new machine gets everything from the marketplace plus one command (section 7), with no clone.
5. `bin/gate` passes on every tested release and goes red on each failure mode it guards.

## 2. Users and surfaces

| User | Surface | Gets |
|---|---|---|
| Claude Code agent in a consumer project | Plugin `backlog-extras` | The wrapper first on PATH as `backlog`, write guard, session doctor, `backlog-md` skill |
| Codex agent in a consumer project | Same plugin, Codex manifest | The wrapper by full path, write guard, session doctor, `backlog-md` skill |
| Person in a terminal | `install.sh` | The wrapper as `bl`, pinned `backlog` |
| Maintainer | This repo | Tests, gate, upgrade and rebuild runbooks |

Other agent apps (OpenCode) are out of scope until one is in use.

## 3. Repository layout

```
plugin.json                            canonical name, version, description, license, publisher, Codex listing (decision 19)
.claude-plugin/plugin.json             Claude Code manifest; hooks load from hooks/hooks.json by default
.claude-plugin/marketplace.json        Claude marketplace backlog-md-extras -> ./distributions/claude
.codex-plugin/plugin.json              Codex manifest: the same fields plus skills and hooks -> hooks/codex-hooks.json
.agents/plugins/marketplace.json       Codex marketplace backlog-md-extras -> ./distributions/openai
requirements.json                      release identity, Backlog.md pin and tested list, host pins, dependency minimums, CI pins
bin/backlog                            the wrapper; BACKLOG_VERSION and BACKLOG_TESTED are checked against requirements.json
bin/check-requirements                 read-only runtime/install/development prerequisite check
bin/gate                               every check (dev only, never shipped); non-zero if any fails
skills/backlog-md/                     SKILL.md (decisions 11 and 20, at most 150 lines), agents/openai.yaml, assets/icon.svg
hooks/prerequisites.sh                 shared fail-closed prerequisite bootstrap
hooks/hooks.json                       registers each hook dir below for Claude Code
hooks/codex-hooks.json                 the same for Codex: BACKLOG_EXTRAS_HARNESS=codex, ${PLUGIN_ROOT}, matcher apply_patch|Bash
hooks/backlog-guard/                   config.json, hook.sh, test.sh   (PreToolUse)
hooks/session-doctor/                  config.json, hook.sh, test.sh   (SessionStart)
assets/                                icon.svg, its icon.png render, brand.json palette
docs/                                  user docs: hosts, Claude Code, Codex, privacy, verifying releases (shipped)
distributions/claude, distributions/openai   generated runtimes the marketplaces install (scripts/pack_plugin.py --sync)
openspec/                              design: plugin-change schema, living specs, WORKFLOW.md (never shipped)
evals/backlog-md/                      claude plugin eval cases named by the spec scenarios
scripts/pack_plugin.py                 builds the runtimes from an allowlist; checks required files and hook script references
scripts/prepare_release.py             versioned ZIPs, SHA256SUMS and draft notes for .github/workflows/release.yml
scripts/checks.sh                      the shell and Python steps bin/gate runs before pytest
scripts/check_hook_layout.py           config.json agrees with hooks.json and codex-hooks.json, both ways; manifest versions match
scripts/check_install.sh               install.sh from a checkout and release-pinned piped setup
scripts/check_codex.py                 isolated real Codex install from distributions/openai, skill discovery, Git upgrade, invalid-manifest rejection
scripts/check_requirements.py          derived manifest, wrapper, installer and CI pins match requirements.json
scripts/check_commands.py              README and doc-1 section 4 command tables agree with the wrapper's command table; SKILL.md lists every row
scripts/check_tested.sh                the wrapper self-test against every other tested Backlog.md release
tests/selftest.sh, tests/setup_test.py wrapper behaviour against real backlog; setup failures against the shipped runtime
tests/unit/, tests/integration/        pytest: manifests, packaging, releases, images, links, specs and evals; strict Claude and OpenSpec validation
.github/workflows/tests.yml            bin/gate on macOS and Linux using declared runtimes and host pins; on push, PR and weekly
.github/workflows/upstream-watch.yml   weekly: opens an issue when npm has a Backlog.md release missing from the tested list
.github/workflows/release.yml          draft release with attested runtime ZIPs, from a tag on main
install.sh                             terminal install (pinned backlog via npm, the wrapper as bl, the skill as ../share/backlog-extras/SKILL.md)
.backlog/                              this repo's Backlog.md project: tasks, milestones, and this spec (doc-1)
README.md, LICENSE (MIT), AGENTS.md, TESTING.md
```

The wrapper lives only at `bin/backlog`; the packer ships it to both runtimes and `install.sh` copies it as `bl`, because in a terminal `backlog` is npm's and PATH order would decide which one runs.

## 4. Wrapper commands

The wrapper first checks the managed `../share/backlog-extras/upstream/bin/backlog` beside the terminal wrapper and `$HOME/.local/share/backlog-extras/upstream/bin/backlog`, using a managed executable only when it reports a tested Backlog.md release (decision 18). Otherwise it uses the first readable executable named `backlog` on PATH that is not a backlog-extras wrapper; unavailable mise shims are skipped. It exits 127 when none qualifies. An incompatible PATH executable is still rejected by added and corrected commands when no managed tested release is available. The wrapper can sit first on PATH under the same name, and two plugin copies never exec each other. It finds the project by walking up from the working directory (or `BACKLOG_CWD`) to the nearest folder holding a Backlog.md config of any layout, checking `.backlog/config.yml`, then `backlog/config.yml`, then `backlog.config.yml` in each folder; the nearest wins, so an unsupported project nested in a supported one is not mistaken for its parent. Only `.backlog/config.yml` is supported (decision 14). When the nearest config is another layout, the added commands exit 1 with `backlog-extras: this project keeps its Backlog.md config in <path>; backlog-extras supports only .backlog/config.yml at the project root` (`doctor` before running stock doctor); with no config at all, they exit 1 with "no backlog project found (run backlog init)". Passthrough commands work in any layout, and `config` outside a supported project runs upstream's wizard unchanged. Any argument list it does not claim is passed to the real `backlog` with `exec`, so output and exit code are upstream's and no version check runs.

Config check (decision 22): in a supported project, every command except help, `-v`/`--version` and `doctor` exits 1 before anything runs when `.backlog/config.yml` does not parse, naming the line. Backlog.md reads such a file as empty settings, and its next write (`config set`, for one) rewrites it from them, dropping every setting. The check covers the flat shape Backlog.md writes: top-level `key: value` lines, list items or nested keys only under a key with no value, and one-line values whose quotes and brackets close. `doctor` reports the same problem and exits 1.

The wrapper's claimed commands are one table, `COMMANDS` near the bottom of the wrapper: each row is a usage (after `backlog `), a one-line summary, a handler, and whether it extends a command upstream also has (`doctor`, `task edit`) rather than adding one. Extended commands run their own version check, because the parts of them that are upstream's (plain `task edit`) stay ungated. A row's command words are the usage's leading tokens before the first `<`, `[` or `-`, with upstream's aliases folded (`tasks`, `milestones`). Dispatch, the version check and help all read it; the hidden flag `backlog --backlog-extras-commands` prints it as `usage<TAB>summary` lines, and the session doctor and the guard build their command lists from that. It is the only hand-written list of the added commands; the gate checks the README table and the table below against it.

Help: a request is any argument list containing `--help` or `-h`, or starting with `help` (scope: the words after it). The scope is the leading non-flag words; a row matches when its words and the scope's are a prefix of one another.

- Scope inside an added command (`decision view`, `milestone view --help`): that command's argparse usage, exit 0.
- Rows match (`backlog --help`, `-h`, `help`, `help decision`, `doc --help`, `doctor --help`): upstream's help unchanged, then a blank line, `Added by backlog-extras:` and the matching rows' usages and summaries; upstream's exit code.
- No rows match (`search --help`, `help board`): `exec` upstream, so the output is upstream's byte for byte.

Help runs no version check. A literal `-h` or `--help` given as an option value also counts as a help request. A `-v` or `--version` anywhere in the arguments goes to upstream unchanged, help requests and added commands included, because upstream then prints its version whatever else is given (`backlog help -v` prints only the version); a literal `-v` option value counts too.

Claimed commands, and the corrected paths below, first check the real `backlog --version` equals `BACKLOG_VERSION`; on mismatch they exit 1 naming both versions and the upgrade runbook, before touching a file.

| Command | Behaviour | Exit |
|---|---|---|
| `backlog decision view <id>` | Print the raw decision file | 0; 1 if not found |
| `backlog decision update <id> [--content MD] [--status S]` | `--content` replaces the whole body (newline appended if missing); `--status` written YAML single-quoted; at least one required | 0; 1 not found; 2 usage |
| `backlog decision remove <id>` | Delete the file | 0; 1 not found |
| `backlog milestone view <id or title>` | Print the raw active milestone file; title match is case-insensitive | 0; 1 not found |
| `backlog milestone update <id or title> --description MD` | Replace the body with `\n## Description\n\n<MD>\n`, the shape `milestone add` writes; frontmatter untouched | 0; 1; 2 usage |
| `backlog doc remove <id>` | Delete the doc, searching subfolders | 0; 1 not found |
| `backlog doctor [--fix --yes]` | Run stock `backlog doctor` with the arguments, then report each draft ID shared by an archived and a live draft (stock checks tasks, not drafts), with every live task or draft that mentions it, and each of `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` at the project root (the backlog folder's parent) holding `BACKLOG.MD GUIDELINES START` or `BACKLOG.MD MCP GUIDELINES`, with the fix (remove the block by hand; the skill replaces it) | stock exit if non-zero, else 1 on a hit, else 0 |
| `backlog task edit <id> --add-dep X[,Y]` | Read each task's dependencies (`task view --json`), append the new ones not already there (case and zero padding ignored), and run upstream `task edit <id> <other args> --dep <merged>`, once per task (several IDs allowed); repeatable, comma lists, `--add-dep=X` | upstream's; 1 task not found or another layout; 2 usage |
| `backlog task edit <id> --remove-dep X[,Y]` | The same, dropping only the named dependencies; an empty result runs `--clear-deps` instead | as above |

Corrections: upstream commands whose behaviour the wrapper changes. They are not rows of the table above (they add no command), so their help stays upstream's byte for byte, and each runs the version check on its corrected path only.

- `init` (decisions 11, 15): first the layout. An explicit `--backlog-dir` other than `.backlog` (spellings that normalise to it, such as `./.backlog/`, are accepted) or `--config-location root` (either `--x v` or `--x=v`) exits 2 naming the supported layout, before upstream runs. A `backlog/config.yml` or `backlog.config.yml` already in the directory init writes to (upstream looks there only, no walk-up) is refused the same way. With no `--backlog-dir` and no project there, the wrapper appends `--backlog-dir .backlog` to upstream's arguments on every path, the `exec` below included, because upstream defaults to `backlog/`; in an existing `.backlog/` project it appends nothing, because upstream rejects `--backlog-dir` on a re-init; `--config-location folder` is not needed, since `.backlog` alone gets folder mode. Upstream 1.55.0 turns off every setup prompt except the project name once any setup flag is given (`--backlog-dir` among them), so interactive init of a new project through the wrapper asks only for the name and takes upstream's defaults; integration mode, instruction files, task prefix and advanced settings are set with their flags, or later with `backlog config`. Then the instructions: upstream writes its instruction block (`<!-- BACKLOG.MD GUIDELINES START -->`) into `AGENTS.md` on every run in cli mode, the default, and into the files `--agent-instructions` names, and `--install-claude-agent true` installs `.claude/agents/project-manager-backlog.md`; the skill is the one source of agent instructions, so these writes are unwanted. With `--integration-mode mcp` or `none` (either form) or `--agent-instructions none`, init writes none of them, so the wrapper `exec`s it with no change but the appended backlog dir (if any), and no version check. Otherwise it snapshots those five files under the directory init writes to (the working directory, or `BACKLOG_CWD`), runs upstream with the terminal so the project-name prompt stays, then writes each file back byte for byte, deletes each it created and removes `.github/`, `.claude/agents/` and `.claude/` when init created them and they are empty, and prints the skill text (`SKILL.md` without frontmatter) to stdout when upstream exits 0 and wrote a config file (`backlog.config.yml` in that directory, which every custom `--backlog-dir` gets, or a `config.yml` one folder down, appeared or got a new mtime; a re-run rewrites it). A prompt cancelled with Ctrl-C also exits 0 but writes no config, so it prints nothing. The exit code is upstream's. Upstream's own summary still names the files it wrote, so after the run the wrapper prints one stdout line naming every file it reverted (`backlog-extras: reverted upstream's writes to AGENTS.md; the backlog-md skill replaces its instructions`), whatever the exit code, before the skill text.
- `agents --update-instructions`: upstream writes the block into the files picked in a terminal. The wrapper prints the skill text and exits 0 without running upstream. `agents` without the flag passes through.
- `config` with no subcommand (the wizard): checked on 1.55.0, it writes no instruction file, but its last question, "Install Claude Code Backlog.md agent?", installs `.claude/agents/project-manager-backlog.md` at the project root. The wrapper runs the wizard the same way as `init` and undoes that write, printing the reverted-files line and the skill text when it undid one. Its subcommands (`get`, `set`, `list`) and a directory with no project pass through.
- Skill text: the wrapper reads `../skills/backlog-md/SKILL.md` beside its `bin/` (the plugin layout), else `../share/backlog-extras/SKILL.md` (where `install.sh` puts it beside `bl`); with neither, it prints one stderr line with the skill's URL in this repo and keeps the exit code.
- `task edit --dep` (and `--depends-on`): upstream replaces the whole dependency list, and agents expect it to add, so they lose dependencies silently. Plain `--dep` still passes through unchanged; on a tested release the wrapper first prints one stderr line naming each dependency the new list drops, and nothing when none are. On any other release it passes through with no check and no warning. `--add-dep` or `--remove-dep` combined with `--dep`, `--depends-on` or `--clear-deps`, or given no task id, exits 2 and changes nothing. Shortcut: the wrapper finds task IDs among the arguments with the list of `task edit` options that take no value, the same on every tested release (checked on 1.55.3 and 1.55.0); recheck it when adding a release.

ID matching ignores case and zero padding; `TASK-2` does not match `TASK-2.1` or `TASK-20`. Files without frontmatter are refused, never rewritten.

Not provided, by decision: renaming a decision (file name embeds the slug), changing a task parent (subtask IDs embed the parent ID), restoring or deleting a draft (upstream restores and deletes archived tasks, docs and decisions since 1.55.0), editing a single task comment. Each becomes a wrapper command only when a real need appears.

## 5. Write guard (`backlog-guard`, PreToolUse)

Matcher: `Edit|Write|MultiEdit|NotebookEdit|Bash` (Claude Code), `apply_patch|Bash` (Codex). Silent (exit 0, no output) unless the session's project root holds `.backlog/config.yml`, the one supported layout; in a `backlog/` or root `backlog.config.yml` project it stays silent too, and the session doctor is the loud failure (section 6). The root is `CLAUDE_PROJECT_DIR` when set (Claude Code); otherwise (Codex) the nearest folder at or above the session `cwd` holding `.backlog/config.yml`.

- The backlog folder is `.backlog/`. When `<root>/.BACKLOG` is the same folder as `<root>/.backlog` (a case-insensitive disk, the macOS default), every path compare and pattern below except the bypass prefix ignores case, so `.BACKLOG/` and `.Backlog/` are the board too; on a case-sensitive disk they are other folders, left unguarded.
- File tools: deny when the normalised target path is inside the backlog folder. Codex `apply_patch`: the same check on every path in every string of its input (so an argv array is read too), from the patch's `*** Add File:`, `Update File:`, `Delete File:` and `Move to:` headers, relative to the session `cwd`.
- Bash: a command that does not name `.backlog` is allowed unchecked. Otherwise, in order:
  - Bypass (decision 17): a command starting with `BACKLOG_GUARD_BYPASS="<reason>"` (double-quoted, single-quoted or bare value) is allowed once one JSON line with `time`, `project`, `reason` and `command` is appended to `${XDG_STATE_HOME:-~/.local/state}/backlog-extras/bypass.log`. An empty or whitespace-only reason is denied, and so is a bypass whose line cannot be written. It covers that one command: the hook reads the prefix from the command text, never from its own environment, so exporting the variable does nothing, and there is no session-wide switch.
  - The `apply_patch` header check on the whole command (Codex accepts a patch as a shell heredoc).
  - Redirect: deny a `>` or `>>` into `.backlog` outside heredoc bodies (a body is the lines after `<<WORD`, `<<'WORD'`, `<<"WORD"` or `<<-WORD` up to the delimiter; `<<<` starts none).
  - Statements (decision 21): the remaining checks run per statement, split on `;`, `&&`, `||`, `&` and newlines; a pipeline stays one statement, so `ls .backlog/tasks | xargs rm` is one. A `cd` or `pushd` into the board, or a variable assigned a board path, anywhere in the command makes them run on the command as a whole instead.
  - Interpreters and nested shells (`python`, `python3`, `node`, `ruby`, `bun`, `deno`, `sh`, `bash`, `zsh`, `eval`) run outside quoted prose and heredoc bodies: deny when their statement names `.backlog` (quoted prose naming it counts), or when their statement takes a heredoc and some heredoc body names it, since their text can write anywhere it names; quoting would otherwise hide `bash -c "rm .backlog/x"`.
  - The remaining checks see a narrowed text (decision 16): heredoc bodies dropped (a line holding only the delimiter, or the delimiter followed by `)`, closes one); a quoted string holding a path into the board (`.backlog` at its start or after a `/`, followed by `/` or its end, such as `".backlog/tasks/task-1 - x.md"` or `"$ROOT/.backlog/x"`) kept as one word, an unclosed quote or heredoc leaving the rest of the command checked unmasked, a double-quoted string holding `$(` or a backtick rescanned without its quotes (it is code), and any other quoted string dropped as prose; and in each `cp` or `rsync` part of a pipeline only the command and its destination kept: the last word that is not an option, after redirections and a trailing `#` comment are removed, unless a `cp` `-t` short-flag cluster or `--target-directory` names the target first (rsync's `-t` keeps times). If `.backlog` is still in a statement, deny on a writing verb (`rm`, `rmdir`, `mv`, `cp`, `rsync`, `tee`, `touch`, `truncate`, `ln`, `dd`, `install`, `mkdir`, `chmod`), an in-place editor flag (`sed -i`, `perl -i`, `--in-place`), or a writing git subcommand (`checkout`, `restore`, `rm`, `mv`, `clean`, `reset`, `stash`).
- Deny output: `hookSpecificOutput.permissionDecision = "deny"` with one reason for every tool, naming `backlog` (under Codex, the wrapper's full path), the wrapper's added commands, read from `backlog --backlog-extras-commands` on the deny path only, so allowed calls start no extra process, and the bypass prefix with its log path.
- Reads (Read tool, `cat`, `ls`, `grep`, `git diff`) are allowed.

Known limits, accepted: pattern matching, not shell parsing, so obfuscated writes pass (variables, `eval` of built strings, base64, a prefixed copy such as `sudo cp` or `env cp`, escaped quotes, a second heredoc on one line, a `cp`/`rsync` option that names a file it writes such as `--backup-dir`, a quoted redirect target with a space before `.backlog`, a GNU `cp`/`rsync` option value written after the destination such as `--suffix .orig`) and some harmless commands are denied (a redirect fragment such as `> .backlog/x` inside quoted text, prose naming `.backlog` beside a writing verb inside `"$(...)"`); Codex does not pass the shell tool's `workdir` to hooks (verified codex-cli 0.163.0, TASK-10), so a relative path in a command run with a workdir is resolved against the session `cwd`; a bypass prefix covers the whole Bash call, every command in it (the full command is logged); binds only agents whose hooks run (under Codex, only once the hooks are trusted in `/hooks`).

## 6. Session doctor (`session-doctor`, SessionStart)

Before reading input, both hooks check runtime prerequisites from requirements.json. Missing or too-old tools emit actionable stderr and exit 2; PreToolUse therefore blocks rather than proceeding without its parser. With valid prerequisites, the doctor is silent outside a backlog project and writes no board files. The project root is found as the guard finds it, except that the walk-up stops at a folder holding any of `.backlog/config.yml`, `backlog/config.yml` or `backlog.config.yml`.

- Unsupported layout: a root holding `backlog/config.yml` or `backlog.config.yml` but no `.backlog/config.yml` gets one warning every session, the same text as `systemMessage` and as `additionalContext`, naming the config found, the supported layout (`.backlog/config.yml` at the project root), and that the guard and the wrapper's added commands do not work until the project uses it. Nothing else: no PATH entry, no version check, no guidance.

Inside a `.backlog/` project:

- PATH: append `export PATH="<plugin>/bin:$PATH"` to `CLAUDE_ENV_FILE`, which Claude Code sources before every Bash call, so `backlog` resolves to the wrapper. Claude Code itself appends the plugin's `bin/` to the end of PATH, where npm's `backlog` would win. Verified live with `claude -p` on Claude Code 2.1.303: the plugin hook receives `CLAUDE_ENV_FILE`, and the prepend holds across separate Bash calls and a `cd`. A resumed or compacted session runs the hook again and adds a harmless duplicate entry.
- No `CLAUDE_ENV_FILE`: warn, naming the wrapper's full path as the way to reach the added commands.
- Codex (`BACKLOG_EXTRAS_HARNESS=codex`, set by `codex-hooks.json`): Codex puts no plugin `bin/` on PATH and gives hooks no env file, so write nothing and name the wrapper's full path in the guidance in place of `backlog`; no warning, since this is the design there. Verified live on codex-cli 0.162.1 in an isolated `CODEX_HOME`: guidance received, `apply_patch` and shell writes into `.backlog/` denied, the wrapper's `decision view` ran by full path. Re-verified with plugin 0.4.1 on Claude Code 2.1.306 (`--plugin-dir`, empty `CLAUDE_CONFIG_DIR`) and codex-cli 0.163.0: the guidance names every usage the table prints and a write under `.backlog/` is denied with the table-derived reason. Isolating Codex takes a scratch `HOME` as well as `CODEX_HOME`, because Codex also reads user skills from `$HOME/.agents/skills`, and an empty read-only `$CODEX_HOME/plugins/cache/openai-curated-remote`, because it downloads the signed-in account's plugins there even with `remote_plugin = false`.
- The real `backlog` (found through the wrapper) missing, or its version differing from `BACKLOG_VERSION`: warn, naming both versions and the fix (`install.sh` or the upgrade runbook). The guard stays active either way.
- Every warning goes out as a user-visible `systemMessage` and in `additionalContext`. `additionalContext` always carries short guidance: load the `backlog-md` skill (listed as `backlog-extras:backlog-md`) before any Backlog.md work, run every Backlog.md command as `backlog` (under Codex, the wrapper's full path), and direct writes are blocked. Commands and workflow are left to the skill (decision 20), so they are not repeated each session. This replaces the per-project `AGENTS.md` line.

Skill (`skills/backlog-md/SKILL.md`, decisions 11 and 20): the agent learns the CLI from the skill alone, not from upstream's `AGENTS.md` block or `backlog instructions`. It is one self-contained guide written for the agent using the board: rules (CLI-only changes, read before writing, `--help` before unfamiliar commands, Codex full path), then finding, creating, working, finishing and archiving tasks, the other records, and what to do when a command refuses. Upstream's four guides are restated in it, and every wrapper command appears where the agent needs it, as `backlog <usage>` with the wrapper's summary. How the wrapper differs from upstream belongs in the README and this spec, not the skill. `scripts/check_upstream_guides.sh` fails when the pin's `backlog instructions overview|task-creation|task-execution|task-finalization` output differs from `tests/fixtures/upstream-instructions.md`, the snapshot the skill was last reviewed against. Under Codex, `backlog` there means the wrapper's full path from the guidance. It reads standalone, since the wrapper prints it from `init`, `agents --update-instructions` and the config wizard (section 4). Verified live in a scratch project with isolated config (pointer version of the skill): Claude Code 2.1.306 (`--plugin-dir`) and codex-cli 0.163.0 (marketplace install, isolated `CODEX_HOME`) both list it as `backlog-extras:backlog-md`, and on "List the tasks on this Backlog.md board." Claude Code invokes it through its Skill tool and Codex reads the installed `SKILL.md`.

## 7. Distribution

- Marketplace name: `backlog-md-extras` (kebab-case; the repo name with the dot replaced). Plugin name: `backlog-extras`.
- Enabling in a project: commit to its `.claude/settings.json`

  ```json
  {
    "extraKnownMarketplaces": {
      "backlog-md-extras": { "source": { "source": "github", "repo": "hsb3/backlog.md-extras" } }
    },
    "enabledPlugins": { "backlog-extras@backlog-md-extras": true }
  }
  ```

  Enabled per project, not globally, so other projects are untouched.
- Each machine then runs `claude plugin install backlog-extras@backlog-md-extras --scope project` in the project once. Observed on Claude Code 2.1.302: the settings alone registered the marketplace on the first session, but the plugin did not load, silently (no wrapper, no guard, no doctor), until this install ran.
- Direct install: `claude plugin marketplace add hsb3/backlog.md-extras`, then `claude plugin install backlog-extras@backlog-md-extras`.
- The plugin does not install Backlog.md itself; the session doctor reports when no tested release is found. Hooks come only from the plugin; `install.sh` installs no hook command.
- Terminal install, no clone: `gh api -H 'Accept: application/vnd.github.raw' 'repos/hsb3/backlog.md-extras/contents/install.sh?ref=v0.7.3' | sh`, which installs pinned Backlog.md with npm under `../share/backlog-extras/upstream` (skipped when that stable copy is pinned), independent of version-managed Node global packages, the wrapper as `bl`, and the skill as `../share/backlog-extras/SKILL.md` beside the install dir, for `bl` to print. A relative `BACKLOG_EXTRAS_INSTALL_DIR` is resolved to absolute, and the skill goes beside the install dir's physical parent, where `bl` looks after resolving symlinks. All downloaded files use the same release tag (v0.7.3 for this release). BACKLOG_EXTRAS_REF may name a reviewed branch or commit with matching release identity; the ref is resolved once through the GitHub commits API, and every artifact fetch uses the returned full commit SHA. Empty, abbreviated and invalid SHAs are rejected before installation. Tags must exist before distributing the one-liner. Setup installs requirements.json and its checker beside the terminal skill and verifies the installed wrapper resolves the pin.
- Codex, once per machine: `codex plugin marketplace add hsb3/backlog.md-extras`, `codex plugin add backlog-extras@backlog-md-extras`, then trust both hooks in `/hooks`. Codex reads `.agents/plugins/marketplace.json`, which points at `distributions/openai`. An untrusted hook never runs, so it supplies no guard or session guidance; Codex reports hooks needing review at startup. Review and trust the current definitions in /hooks and start a new session after installing or updating.
- Releases: bump `version` in `plugin.json`, both host manifests and `requirements.json` for every change users should receive, then `python3 scripts/pack_plugin.py --sync`; Claude Code consumers update with `claude plugin update backlog-extras@backlog-md-extras` or marketplace auto-update; Codex consumers with `codex plugin marketplace upgrade backlog-md-extras` (verified on codex-cli 0.163.0 with a temporary Git marketplace: installed files and version refresh).

## 8. Gate

`bin/gate` runs `scripts/checks.sh`, then pytest on `tests/unit` and `tests/integration`, and fails if any step fails:

1. Installed `backlog --version` equals `BACKLOG_VERSION`, the pin.
2. `tests/selftest.sh`: every wrapper command (including `task edit --add-dep`/`--remove-dep`, the usage errors, and the plain `--dep` warning, against `task view --plain`) against real Backlog.md in scratch projects, using stock read commands as the oracle; includes the version gate (stub `backlog` reporting another version) and passthrough exit codes, the wrapper first on PATH under its own name (a self-exec loop is killed after 20 s and fails), two wrapper copies ahead of the real `backlog` in both orders and a committed legacy self-only-exclusion fixture ahead of the fixed one (each killed after 5 s), exit 127 with neither a PATH nor stable `backlog`, an unavailable mise shim ahead of a working `backlog` skipped, an unreadable `backlog` ahead of the real one skipped, the corrections (init with `--defaults`, with each `--agent-instructions` value but `none`, with `--install-claude-agent true`, with `BACKLOG_CWD`, and interactively in a pseudo-terminal, where Ctrl-C at the first prompt prints no skill; `agents --update-instructions` and the config wizard in a pseudo-terminal; each leaving seeded `AGENTS.md`/`CLAUDE.md` byte-identical, creating no other instruction file or agent, and printing the skill, with one line naming exactly the files reverted; init with `--agent-instructions none`, `--integration-mode mcp` and `--integration-mode=none` byte-identical to upstream; the stderr line when no skill file is found; each refused off the pin), doctor's instruction-block report, and help: `help <cmd>` and `<cmd> --help` for every upstream command the wrapper does not extend byte-identical to upstream's, every extended scope's help is upstream's followed by exactly its rows, and every added command's `--help` exits 0 with its usage; `-v` or `--version` added to help requests and an added command is upstream's byte for byte. It fails if it stops before its last check (Bash 3.2 can abort on an error with exit 0). `scripts/check_tested.sh` then runs it against every other release in requirements.json `tested`, each npm-installed once into `~/.cache/backlog-extras/tested`, with an empty HOME so a managed install cannot stand in for that release.
3. Each hook's `test.sh`: sample hook inputs, asserting allow, deny or silence, including the not-a-backlog-project case; the guard's deny reason and the session doctor's guidance and no-`CLAUDE_ENV_FILE` warning name every usage the wrapper's table prints, and the guidance tells the agent to load the `backlog-md` skill before any Backlog.md work.
4. `scripts/check_hook_layout.py`: every hook dir has `config.json`, `hook.sh`, `test.sh`, and matches `hooks.json` and `codex-hooks.json` both ways (Codex entries against `codexMatcher`, since its tool names differ); the two manifests carry one name and one version; the Codex manifest points `hooks` at `./hooks/codex-hooks.json` and `skills` at an existing `./` dir in the plugin; and `codex-hooks.json` uses only Codex hook events, groups of `matcher` and `hooks`, and `command` handlers carrying only the keys codex-rs `config/src/hook_config.rs` (rust-v0.163.0) allows, with no top-level key beyond `description` and `hooks`. The layout checker also rejects a non-object Codex interface. The real Codex lifecycle check below is the authoritative manifest compatibility check; the hand-written hook schema check remains supplemental.
5. `scripts/check_commands.py`: the command cells of the README `## Commands` table and of the section 4 table here equal `backlog <usage>` for the wrapper's table rows, same rows in the same order; a missing section fails with a message. The skill's `SKILL.md` has at most 80 lines and holds, for each row, the line ``- `backlog <usage>`: <summary>.`` with the table's summary, and no other bullet opening with a backticked `backlog ...` usage (upstream commands appear only in prose); an overlong skill and each missing, differing or extra line fail, named.
6. `scripts/check_install.sh`: checkout and piped installs into temp dirs, and checkout installs into a relative dir and a symlinked dir; each installs the skill as `../share/backlog-extras/SKILL.md` and the installed `bl` prints it. With an isolated HOME and Python executable, both terminal and plugin wrappers must find the stable installation behind an unavailable mise shim.
7. `tests/integration`: strict `claude plugin validate` on the repo, its marketplace and `distributions/claude`; `openspec validate --all --strict`. `tests/unit`: manifests agree with `plugin.json`, marketplaces point at `distributions/`, the packer ships exactly the runtime allowlist (no portable `plugin.json` in the Codex package), refuses missing hook scripts, builds reproducibly and `distributions/` is current; release archives; links; images on the brand palette; every spec scenario names an eval and every eval is named.
8. `shellcheck` on every shell file.
9. requirements.json is readable and its runtime/development requirements and exact host pins are satisfied. Manifests, wrapper constants (the pin and the tested list, which must hold the pin and no repeat), installer release, asset paths and literal CI references agree with that declaration.
10. tests/setup_test.py verifies a managed tested release beats an incompatible PATH runtime, missing jq causes both hooks to exit 2 with an actionable message, and invalid Codex interface metadata is rejected.
11. scripts/check_codex.py installs the real plugin from `distributions/openai` with isolated HOME and CODEX_HOME, confirms every cached file equals the runtime and the skill is discovered, upgrades a temporary Git marketplace and verifies the new installed version and files, then verifies Codex rejects malformed metadata. Git URL rewriting points only to a local fixture; no account, network or model call is needed.
12. GitHub Actions runs the full gate on macOS and Linux from a shallow checkout. The self-test uses a checked-in legacy fixture and requires no repository history.

Every new check is first watched failing against the code it guards.

## 9. Runbooks

### Upgrade Backlog.md

1. `npm install -g backlog.md@<new>`.
2. Read upstream's release notes since the newest tested release, and compare `backlog task edit --help` with the wrapper's `TASK_EDIT_SWITCHES`. When changing the pin, `sh scripts/check_upstream_guides.sh` shows how upstream's workflow guides changed: update the skill to match, then rerun it with `--update`.
3. Append `<new>` to `tested.backlog.md` in requirements.json and to its derived `BACKLOG_TESTED` in bin/backlog; to make it the installed release, also set `pins.backlog.md` and `BACKLOG_VERSION`. Host pins and dependency requirements live in that same declaration. Drop a release from the list only when the wrapper stops supporting it.
4. `bin/gate`. On failure, fix the wrapper or revert: `npm install -g backlog.md@<old>` and leave the lists.
5. Cut a release (below).
6. Each machine: rerun the `install.sh` one-liner (terminal), `claude plugin update backlog-extras@backlog-md-extras`, and for Codex `codex plugin marketplace upgrade backlog-md-extras` (verified on codex-cli 0.163.0), then start a new session and review `/hooks`. Upgrade may remove the previous cache path; existing sessions hold an absolute wrapper path that can stop working.

### Release

1. Bump `version` in plugin.json, both host manifests and pluginVersion in requirements.json, and the `?ref=vX.Y.Z` examples in README and this spec; `python3 scripts/pack_plugin.py --sync`; `bin/gate`.
2. Commit to main and push. Wait for the Tests workflow on that commit to pass on both OSes.
3. Tag that green commit: `git tag -a vX.Y.Z -m vX.Y.Z <sha> && git push origin vX.Y.Z`. Tags are annotated, `v`-prefixed semver, and only ever on a main commit whose CI passed.
4. `gh workflow run release.yml -f tag=vX.Y.Z`; it reruns the gate on the tag and creates a draft release with attested ZIPs. Check the draft's assets and notes, then publish it.
5. A tag never moves once its release is published: fix forward with a patch release. A tag with no published release may be moved only to repair it (for example a tag whose CI failed), and the move is noted in the commit or release notes.

### Rebuild from nothing (unverified until run on a clean machine)

1. `gh auth login`.
2. Install the runtime and setup requirements declared in requirements.json (macOS or Linux/WSL, Bash, Python, jq, Node, npm and system utilities). Native Windows is unsupported.
3. `gh api -H 'Accept: application/vnd.github.raw' 'repos/hsb3/backlog.md-extras/contents/install.sh?ref=v0.7.3' | sh`.
4. In each consumer project: `claude plugin install backlog-extras@backlog-md-extras --scope project` (registers the marketplace from the project settings if needed).
5. Start a session in a consumer project; the session doctor's guidance or warning confirms the plugin loaded. Missing session guidance requires checking plugin installation, prerequisite errors and, for Codex, hook trust in /hooks.

## 10. Tracking

Work on this repo is tracked with Backlog.md in `.backlog/`, managed through the wrapper, so the repo is its own first consumer: tasks and milestones, and this spec as doc-1 (type `specification`). The guard blocks direct edits here too, so change the spec with `backlog doc update doc-1 --content "$(cat new.md)"`, which replaces the whole body. The the owner's reference project project, outside this repo, stays the reference for upstream behaviour.

## 11. Decisions (accepted 2026-10-18)

| # | Decision | Outcome |
|---|---|---|
| 1 | Plugin name | `backlog-extras`, plain and matching the repo |
| 2 | Session doctor replaces the `AGENTS.md` line | Yes: tooling over directive |
| 3 | Track this repo's work with Backlog.md in-repo | Yes: dogfooding exercises the wrapper daily |
| 4 | Keep `install.sh` alongside the plugin | Yes: terminal users and the pinned `backlog` need it |
| 5 | One plugin for all functionality | Yes |
| 6 | One CLI name for agents | The plugin ships the wrapper as `backlog` and the session doctor puts it first on PATH; agents never see `bl`, which stays the terminal name |
| 7 | Codex support | Same plugin dir, a second manifest and hooks file; the hook scripts branch on `BACKLOG_EXTRAS_HARNESS=codex` only where Codex differs (no PATH prepend, `apply_patch` paths, wrapper named by full path) |
| 8 | `backlog doctor` from Backlog.md 1.55.0 | Drafts only: since 1.54.0 archived task IDs stay reserved (verified 2026-11-08; 1.53.0 reuses them) and its stock doctor finds and repairs older task collisions; archived draft IDs are still reused and stock doctor misses them |
| 9 | Wrapper scope (2026-10-21) | Fills gaps and corrects undesirable upstream behaviour: it may deny or rewrite selected upstream commands, each listed with its reason. Previously it only filled gaps |
| 10 | Help (2026-10-21) | `backlog --help`, `backlog help [cmd]` and `<group> --help` for the extended groups print upstream's help plus an "Added by backlog-extras" section. One table of added commands in the wrapper feeds the help, the session doctor's guidance and the guard's deny message; the gate checks the README table against it |
| 11 | Agent instructions (2026-10-21) | A skill shipped in the plugin is the one source of Backlog.md agent instructions: upstream's lifecycle guides by pointer (`backlog instructions ...`), the added commands, no direct board edits. The wrapper never lets upstream write its AGENTS.md/CLAUDE.md block: in cli mode (the default) `init` creates or changes no instruction file and installs no Claude agent, undoing those writes rather than appending `--agent-instructions none` (upstream rejects it in mcp and none modes; which prompts remain is decision 15), and where upstream would write instructions (`init`, `agents --update-instructions`) the wrapper prints the skill text to stdout instead. `backlog doctor` reports a leftover upstream block |
| 12 | Task dependencies (2026-10-21) | The wrapper adds `task edit --add-dep` and `--remove-dep`, merged with the current list and passed to upstream as a full `--dep`. Plain `--dep` keeps upstream's replace meaning and warns on stderr when it drops existing dependencies |
| 13 | `decision remove`, `doc remove`, `decision update --status` after 1.55.0 (2026-10-21) | Keep all three. `remove` deletes a live decision or doc in one step and releases its ID, where upstream needs `archive` then `delete`; `--status` stays beside upstream's `decision edit -s` so one `decision update` call can set body and status |
| 14 | One supported layout (2026-10-21, TASK-26) | Only `.backlog/config.yml` at the project root. This plugin is an opinionated use of Backlog.md, and half-support (a guard and doctor silent in a root-config project) failed quietly; any other layout gets the doctor's warning and refusing added commands |
| 15 | `init` appends `--backlog-dir .backlog` to a new project (2026-10-21, TASK-26) | Upstream defaults to `backlog/`, so without the flag init would make an unsupported project; other `--backlog-dir` values and `--config-location root` are refused before upstream runs. Cost: upstream then skips every setup prompt but the project name. Amends decision 11, which kept init's interactive prompts and appended nothing |
| 16 | Guard narrowing (2026-10-21, TASK-27, owner decision) | The Bash match ignores the board name as a `cp`/`rsync` source, in quoted prose and in heredoc bodies of non-interpreter commands, which were GitHub #4's false positives; interpreters and nested shells whose text names the board stay denied |
| 17 | Per-command guard bypass (2026-10-21, TASK-27, owner decision) | `BACKLOG_GUARD_BYPASS="<reason>" <cmd>`, Bash only: a reason is required and logged with time, project and command, and it is never a session-wide switch |
| 18 | Tested releases instead of one pin (2026-11-08) | The added and corrected commands accept any Backlog.md release in requirements.json `tested` (1.54.0 to 1.55.3); `install.sh` and CI install the one in `pins`. Not a semver range: patch releases change behaviour (1.55.2 broke Git HTTPS proxies, 1.55.3 fixed task reads and writes) and the wrapper edits board files, so every accepted release must pass the self-test. 1.53.0 is excluded: it reuses archived task IDs |
| 19 | plugin-factory layout (2026-11-08, owner decision) | The plugin sits at the repo root, ported from the owner's plugin-factory template: canonical `plugin.json`, generated `distributions/claude` and `distributions/openai` that the marketplaces install, OpenSpec design with eval-mapped scenarios, attested draft releases, MIT license. The template refuses hooks; here the packer ships exactly the wrapper, both hooks and `requirements.json`, and fails when a hook command names an unbundled script. The Codex runtime carries no portable `plugin.json`, because Codex 0.163.0 reads it in place of `.codex-plugin/plugin.json`, the only manifest declaring the hooks. Marketplace name stays `backlog-md-extras` so install commands do not change |
| 20 | Self-contained skill (2026-11-08, owner decision) | The skill restates upstream's workflow guides instead of pointing at `backlog instructions`, and speaks only to the agent using the board; wrapper-versus-upstream detail lives in the README and this spec. One read gives the agent the whole workflow with the wrapper's commands in place, and upstream's guides (which name a `backlog/` folder and teach `--dep` as the way to add dependencies) no longer conflict with it. Cost: the text no longer follows the pin by itself, so the gate snapshots the pin's guides and fails when they change. Amends decision 11 |
| 21 | Guard checks per statement (2026-11-09, GitHub #2) | A write verb or interpreter in one statement no longer blocks a read of the board in another (`rm -rf /tmp/x && git add .backlog`). Pipelines stay whole, and a `cd` into the board or a board-path variable switches back to the whole-command check, because each carries the board into later statements. Amends decision 16 |
| 22 | Refuse a config that does not parse (2026-11-09, GitHub #3) | Upstream silently reads a malformed `config.yml` as empty settings and its next write drops them all. The wrapper refuses every command but help, version and doctor until the file is repaired. Not full YAML (the runtime has no YAML library): it checks the flat shape Backlog.md writes, verified against upstream 1.55.3 on flow lists, block lists at both indents, inline comments, orphaned items, stray text and unclosed brackets |



### Marketplace hardening decision (2026-10-24)

The owner authorized the Codex marketplace audit improvements while preserving Claude support. Keep one shared Claude-compatible marketplace catalog (superseded by decision 19: one marketplace file per host), separate host manifests and hook registrations, and shared hook implementations. Put Codex listing text, category and icon references in its manifest. requirements.json is the canonical release/dependency declaration; validate unavoidable copied values in scripts, manifests and CI. Prefer a correctly pinned managed Backlog installation over PATH. Piped setup fetches every artifact from one release ref. The README publishes the accepted workdir, MCP-editor and interactive-input guard limits, and requires restarting after Codex upgrades.
