---
id: TASK-26
title: Require .backlog/ with a nested config; every other layout fails loudly
status: Done
assignee: []
created_date: '2026-10-21T12:12:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels:
  - hardening
dependencies: []
priority: low
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Owner decision 2026-10-21: this plugin is an opinionated use of Backlog.md and supports exactly one layout, `.backlog/config.yml` at the project root. A `backlog/` folder or a root config (`backlog.config.yml`, which upstream writes for any custom `--backlog-dir` or `--config-location root`) is unsupported. Today the wrapper, guard and doctor accept `backlog/` too, and a root-config project gets silent hooks and unprotected board files (found in TASK-24, log task-24-root-config.log in agent artifacts).

Impact on goal: doc-1 goal 2 (direct writes denied): no layout the plugin meets is left silently unguarded.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 In a project with backlog/config.yml or backlog.config.yml and no .backlog/config.yml, the session doctor warns every session (systemMessage plus context) naming the required layout, and the wrapper's added commands exit 1 naming it; hook tests and the selftest cover both layouts, watched failing first
- [x] #2 Wrapper init leaves a .backlog/config.yml project: with no --backlog-dir it gets .backlog in folder mode (verify upstream's prompt and flags at the pin), and an explicit other --backlog-dir or --config-location root is refused before upstream runs
- [x] #3 Guard, doctor and wrapper no longer recognise backlog/; doc-1 (goal, sections 4-6, decisions table), README and the skill state the single supported layout
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Only .backlog/config.yml is supported (commits 2c50f3f, fa83e66, docs 2f5be5d, 98b9f0c, 5e7ee0e on branch guard-0.5.0). #1: session-doctor warns every session (systemMessage and additionalContext, no PATH prepend) in a backlog/config.yml or backlog.config.yml project, naming .backlog/config.yml; the wrapper's added commands (incl. doctor and task edit --add-dep/--remove-dep) exit 1 naming it. Covered by session-doctor/test.sh (both layouts, stdin-cwd walk-up), backlog-guard/test.sh (silent there) and tests/selftest.sh; watched failing first (e.g. FAIL backlog/config.yml project: warns naming .backlog/config.yml; FAIL doctor in a backlog/ project (rc=0); FAIL task edit 1 --add-dep 2 in a backlog/ project (rc=0)). #2: verified at 1.55.0 ((local log) task-26-init-flags.log): --backlog-dir .backlog alone gives folder mode; upstream checks only the init dir for an existing project and rejects --backlog-dir on re-init. Wrapper init appends --backlog-dir .backlog when the init dir has no project, appends nothing in an existing .backlog/ project, and refuses (exit 2, before upstream runs, passthrough included) another --backlog-dir, --config-location root, or an existing backlog/ or backlog.config.yml project; selftest covers each (stub proves upstream never ran). Cost recorded as decision 15: upstream then skips every setup prompt but the project name. #3: no backlog/ handling remains in guard, doctor or wrapper; doc-1 goal, sections 4-6, decisions 11 and 14-15, README Supported layout and the skill state the single layout. ./gate.sh exit 0. Adversarial review: two passes, findings fixed.
<!-- SECTION:FINAL_SUMMARY:END -->
