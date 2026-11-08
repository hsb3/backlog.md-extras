# Agent guidelines

- `plugin.json` is canonical for name, version, description, license and publisher.
  Change it first, then mirror the value into `.claude-plugin/plugin.json`,
  `.codex-plugin/plugin.json` and `requirements.json` `pluginVersion`; `bin/gate`
  rejects drift.
- Never edit `distributions/` by hand. After any change to shipped files run
  `python3 scripts/pack_plugin.py --sync`; marketplaces install those folders.
  The packer ships the skill, `bin/backlog`, `bin/check-requirements`, the hooks
  and `requirements.json`; `bin/gate`, hook `test.sh` and `config.json` stay out.
- The Codex package has no `plugin.json`: Codex 0.163.0 reads it in place of
  `.codex-plugin/plugin.json`, which alone declares the hooks. Keep it that way.
- A new feature or behavior change is an OpenSpec change on the `plugin-change`
  schema (`openspec new change <name>`). Code changes wait until its `design.md`
  says `Status: Approved`. Bug fixes need no change.
- Work queues are GitHub issues: `bug` is the rework queue, fixed directly;
  `enhancement` is the feature queue, and each accepted request becomes an
  OpenSpec change before code.
- Design lives in `openspec/`; implementation tasks, build decisions and the
  build spec (doc-1) live in backlog.md (`.backlog/`, CLI only: the guard denies
  direct writes). A "task" is always a backlog.md task. `openspec/WORKFLOW.md`
  has the phases and the handoff.
- Every spec scenario ends with `- **EVAL** evals/<skill>/<case>`; every eval case
  is named by a scenario. `bin/gate` enforces both directions.
- Skills: folder name equals frontmatter `name`; body under 24,000 bytes and the
  backlog-md skill under 80 lines; each has `agents/openai.yaml` and
  `assets/icon.svg`. The README Commands table, the spec's section 4 table and
  the skill's command lines all follow the wrapper's `COMMANDS` table.
- The wrapper accepts every Backlog.md release in `requirements.json` `tested`
  and the installer installs the one in `pins`. To add a release, follow
  "Upgrade Backlog.md" in doc-1.
- Shell must run on Bash 3.2 (macOS `/bin/bash`): no `${x,,}`, no `mapfile`, and
  guard empty arrays under `set -u` with `${a[@]+"${a[@]}"}`.
- `docs/*.md` and `README.md` are user-facing and ship in every package.
  Development files (`AGENTS.md`, `TESTING.md`, `openspec/`, `.backlog/`) never
  ship; shipped files link to them by absolute GitHub URL.
- Images: every SVG uses only colors listed in `assets/brand.json`, and every PNG
  has its SVG source beside it.
- Runtime packages carry no MCP servers or apps unless a change's design adds
  them and the packer and tests change with it.
- Done means `bin/gate` passes and `TESTING.md` records any host run claimed.
- EGM artifact directory: .dev/egm
