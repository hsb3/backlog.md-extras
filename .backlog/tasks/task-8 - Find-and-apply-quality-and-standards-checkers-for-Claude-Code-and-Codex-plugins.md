---
id: TASK-8
title: >-
  Find and apply quality and standards checkers for Claude Code and Codex
  plugins
status: Done
assignee: []
created_date: 2026-10-20 00:31
updated_date: '2026-11-08T20:40:00Z'
labels: []
dependencies: []
priority: medium
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The gate checks manifests only with claude plugin validate --strict and shellcheck; Codex has nothing (codex-cli 0.162.1 has no plugin validate). Find what exists and wire in what applies. Candidates: claude plugin eval suites for the hooks' behaviour; a JSON schema check for .codex-plugin/plugin.json and codex-hooks.json (from OpenAI's plugin docs or codex-rs); hooks.json schema for Claude; OpenAI's Submit-your-Claude-Code-plugin guide checks; checkers used in the owner's other plugin repos and the claude-plugins-official marketplace.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A short survey in the task notes: each checker found, what it covers, adopted or rejected with a reason
- [x] #2 Each adopted checker runs in ./gate.sh and has been watched failing on a seeded defect
- [x] #3 Codex manifest and hooks file are validated by at least one check beyond check_hook_layout.py, or the notes say why none exists
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Survey 2026-10-21 (Claude Code 2.1.306, codex-cli 0.163.0). Each checker: what it covers; verdict and reason.

Adopted
- Codex schema check (new, in scripts/check_hook_layout.py, gate step "hook layout"). Covers codex-hooks.json events, group keys (matcher, hooks) and command-handler keys against codex-rs core/config.schema.json at rust-v0.163.0 (HooksToml, MatcherGroup, HookHandlerConfig), plus Codex manifest: same name as the Claude manifest, skills an existing ./ dir (codex-rs core-plugins/src/manifest.rs resolves paths only as ./ inside the plugin root). Pattern from a sibling repo's check_catalog.py codex_problems. Reason: no Codex validator exists and Codex ignores unknown keys, so a typo is silently inert; `claude plugin validate --strict` never opens .codex-plugin/ or codex-hooks.json (seeded bad name, bogus key and bogus hook type there: it passed). Watched failing on scratch copies: handler `timeoutt`, group key `matchr`, event `Notification`, handler type `prompt`, skills `./skill/`, skills `skills/`, skills missing, Codex name `backlog-extraz`; and ./gate.sh exit 1 with `timeoutt` seeded in the real codex-hooks.json (only "hook layout" failed; "plugin manifest" passed).
- Kept: `claude plugin validate --strict` on the marketplace and plugin. It already covers hooks.json (unknown hook type fails, unknown event warns, so strict fails), SKILL.md frontmatter (missing description fails under strict), name kebab-case, and marketplace/plugin version drift. shellcheck kept.

Rejected
- Codex CLI validation: none exists. `codex plugin` has only add/list/marketplace/remove; `codex debug`/`doctor` do not validate plugin files; OpenAI's plugin build guide and hooks docs name no linter (manual rules only: ./ paths inside the root, kebab-case names).
- `codex app-server` `hooks/list` (reports per-cwd hook parse errors): experimental JSON-RPC, needs a Codex runtime and client; too heavy for the gate.
- SchemaStore codex-hooks.json / codex-plugin-manifest.json schemas: unofficial, need a new dependency (check-jsonschema or ajv), and the manifest schema requires author/interface and has no `hooks`, so it rejects a manifest Codex loads. The hand check above uses the official codex-rs sets instead.
- codex-rs hooks/schema/generated/*.command.{input,output}.schema.json (hook stdout shapes): needs a JSON Schema validator (new dependency); hooks' test.sh already assert their outputs.
- `claude plugin validate --profile directory`: Anthropic directory submission checks. Red today only on LICENSE_MISSING (and warns on no icon); a license is an owner decision under TASK-7 (public readiness). Adopt when a LICENSE lands.
- `claude plugin tag --dry-run`: checks plugin.json against the marketplace entry, which validate --strict already does (seeded version drift fails both). Gap left open: a marketplace entry renamed to backlog-extraz passes both validate --strict and tag; without --force it also fails on a dirty tree or an existing tag.
- `claude plugin eval`: every case is billed model runs (3 runs plus a no-plugin baseline), not deterministic; hook behaviour is covered deterministically by each hook's test.sh.
- `claude plugin details`: inventory and projected token cost, no pass/fail, needs the plugin loaded.
- SchemaStore claude-code-plugin-manifest / marketplace schemas: add nothing over validate, which the docs call authoritative.
- anthropics/claude-plugins-official CI (validate-plugins.yml checks I1-I11: name regex, description length, hidden Unicode, https URLs, pinned SHAs, JSON parse; validate-frontmatter.yml; scan-plugins.yml): name/description/JSON parse covered by validate --strict; URL and SHA rules have no subject here (no URLs or remote sources); hidden-Unicode scan and frontmatter script are for third-party submissions, revisit with TASK-7; scan-plugins needs an API key.
- quick_validate.py (anthropics/skills skill-creator) and skills-ref validate (agentskills): SKILL.md frontmatter rules; need PyYAML or Python 3.11 + click + strictyaml (new dependencies), and validate --strict already parses the frontmatter and requires a description.
- Community linters (claude-code-lint, csklint, claude-pre-commit): new dependencies, unvetted, nothing beyond the above.
- A sibling plugin repo's gate: same pattern (validate, hook layout port), nothing new. Another sibling repo: check_manifests.py is validate --strict (have it); check_catalog codex_problems adopted as above; check_version_bump.py rejected (this repo has no bump-per-change rule; gate-only changes ship no plugin version).

Review follow-up 2026-10-21 (an independent reviewer against codex-rs rust-v0.163.0 source):
- Added: unknown top-level keys in codex-hooks.json fail (Codex drops the whole file on one, hook_config.rs HooksFile); watched failing on "descripton". skills "./" now fails (Codex rejects it, manifest.rs); command_windows alias accepted.
- Repo rules, not Codex failures: a missing skills key and "skills/" both fall back to ./skills in Codex; the check fails them to keep the manifest explicit. A skills array is valid Codex but fails here (this repo uses a string).
- TASK-25 bullet match widened to +, numbered, multi-space/tab and bold bullets; each watched failing. Known limit: a bullet opening with an upstream command fails by design (doc-1 section 8 item 5).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Survey in the notes (15 checkers; 1 adopted, validate --strict and shellcheck kept, rest rejected with reasons). Adopted: a Codex schema check in scripts/check_hook_layout.py (gate step 'hook layout'): codex-hooks.json events, group keys and command-handler keys against codex-rs core/config.schema.json at rust-v0.163.0; Codex manifest name equals the Claude one and skills is an existing ./ dir. No Codex validator exists (notes say why). Proof: watched failing on 8 seeded scratch defects (handler timeoutt, group key matchr, event Notification, handler type prompt, skills ./skill/, skills/, missing, name backlog-extraz); ./gate.sh exit 1 with timeoutt seeded in the real codex-hooks.json while 'plugin manifest' (claude validate) passed; ./gate.sh exit 0 after restoring. doc-1 section 8 item 4 updated. No new dependency.
<!-- SECTION:FINAL_SUMMARY:END -->
