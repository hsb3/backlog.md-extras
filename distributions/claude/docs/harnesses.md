# Supported hosts

One skill, one wrapper and two hooks serve both hosts.

| Host | Manifest | Install source | Hooks |
| --- | --- | --- | --- |
| Claude Code | `.claude-plugin/plugin.json` | `distributions/claude` via `.claude-plugin/marketplace.json` | `hooks/hooks.json` |
| Codex | `.codex-plugin/plugin.json` | `distributions/openai` via `.agents/plugins/marketplace.json` | `hooks/codex-hooks.json`, after approval in `/hooks` |

`plugin.json` is canonical for name, version, description and publisher. Host
manifests repeat those values; the unit tests reject drift. The Codex package
leaves `plugin.json` out, because Codex reads it in place of
`.codex-plugin/plugin.json`, the only manifest that declares the hooks.

Install the whole plugin. The hooks need `requirements.json` and the wrapper in
`bin/`. Native Windows is unsupported; use WSL. Antigravity is not supported.

Tested versions and dates live in the
[host record](https://github.com/hsb3/backlog.md-extras/blob/main/TESTING.md#host-record).
