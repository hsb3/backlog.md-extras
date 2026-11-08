---
id: TASK-7
title: Readiness list for making the repo public
status: Done
assignee: []
created_date: 2026-10-20 00:31
updated_date: '2026-11-08T20:40:00Z'
labels: []
dependencies: []
priority: medium
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Build the checklist of everything that must be true before hsb3/backlog.md-extras goes public, then work it. Seed ideas, to confirm, cut or extend:
- Secrets and personal data: scan full git history (gitleaks or trufflehog); decide on the personal commit email.
- Private-repo assumptions: install.sh one-liner and spec rebuild runbook need gh auth / SSH; public allows a plain curl raw URL and HTTPS marketplace add for both Claude Code and Codex.
- Owner-local references: spec section 10 cites an owner-local reference project, which readers cannot see.
- License: choose one (owner decision; add the file only once decided).
- CI: no GitHub Actions; run ./gate.sh on PRs (needs backlog.md at the pin, claude CLI for validate, shellcheck).
- In-repo .backlog/ tracking: keep public as dogfooding or prune.
- README for strangers: what Backlog.md is, the version pin and upgrade policy, limits, Claude Code vs Codex differences, hook trust step.
- Relationship to upstream: attribution and naming clear, no implied endorsement by MrLesk/Backlog.md.
- Releases: tags and changelog per plugin version.
- Directory listings: Claude Code community marketplaces; OpenAI's public directory refuses plugins with lifecycle hooks, so Codex stays self-hosted marketplace only.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A readiness checklist exists (task notes or a doc) with each seed idea kept, cut with a reason, or extended
- [x] #2 Each kept item is done or has its own task
- [x] #3 Owner decisions (license, commit email, .backlog/ kept or pruned) are recorded
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Owner decisions 2026-10-21:
- Stays private until the plugin is seen working in real use; cutover tasks get filed when the owner calls it, not before.
- Leaning: a fresh public repo with fresh commit history, carrying a public .backlog/ (dogfooding kept).
- README must state the relationship to upstream: an independent add-on, no ownership or authorship of Backlog.md claimed, thanks to its author (MrLesk).

Owner decisions 2026-11-08, worked in the plugin-factory port (decision 19 in doc-1):
- License: MIT (LICENSE), from the plugin-factory template.
- History: a fresh public hsb3/backlog.md-extras with one squashed commit authored with the GitHub noreply address; the old repo stays private as hsb3/backlog.md-extras-private.
- .backlog/ kept public (dogfooding). Task notes scrubbed through the backlog CLI of local log paths, scratch paths and other private project names; doc-1 updated the same way. One task file name keeps an old project name, because upstream does not rename files on a title change.
- Secrets: gitleaks found no leaks in 57 commits; no tokens, keys or home paths in files.
- Install: README and docs use the public marketplace shorthand (hsb3/backlog.md-extras) for both hosts; install.sh still uses gh.
- README: states the independent relationship to Backlog.md and thanks its author. The ground-up rewrite stays TASK-35.
- CI: bin/gate on macOS and Linux (.github/workflows/tests.yml); releases through the attested draft-release workflow.
- Directory listings: not pursued.
<!-- SECTION:NOTES:END -->
