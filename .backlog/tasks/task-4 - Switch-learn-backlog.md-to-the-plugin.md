---
id: TASK-4
title: Switch the owner's reference project to the plugin
status: Done
assignee:
  - '@claude'
created_date: 2026-10-18 18:50
updated_date: '2026-11-08T20:39:00Z'
labels: []
milestone: m-0
dependencies:
  - TASK-1
  - TASK-2
  - TASK-3
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
the owner's reference project is the first consumer. It currently registers the installed backlog-cli-only command by hand and carries an AGENTS.md line; both should come from the plugin instead.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Its .claude/settings.json declares the marketplace and enables backlog-extras@backlog-md-extras, with no hand-registered hook
- [x] #2 The bl line is gone from its AGENTS.md and docs point at the plugin
- [x] #3 A live claude -p session in that repo has bl on PATH, is denied a write under .backlog/, and receives the session-doctor context
- [x] #4 The old backlog-cli-only command is removed from the local bin directory
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Replace the hand-registered hook in the owner's reference project settings with extraKnownMarketplaces + enabledPlugins.
2. Remove the bl line from its AGENTS.md; point docs/README.md at the plugin.
3. Live claude -p in that repo: bl on PATH, denied write, session-doctor context.
4. Remove the old backlog-cli-only command from the local bin dir.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
the owner's reference project settings now hold only extraKnownMarketplaces + enabledPlugins; its AGENTS.md bl line is removed and docs/README.md describes the plugin.
Silent failure found: with only the settings, a claude -p session registered the marketplace but did not load the plugin (no bl, no guard: a probe write went through and was then deleted by hand, no doctor context). Fixed by `claude plugin install backlog-extras@backlog-md-extras --scope project`; documented as a required per-machine step in README and the spec.
After install, live claude -p (haiku, local bin dir removed from PATH): bl resolved to the plugin cache copy, a touch under the backlog tasks folder was denied with the guard message (file not created), and the session-doctor guidance arrived as session context.
Old backlog-cli-only removed from the local bin dir; the terminal bl stays (identical to the plugin copy).
Gap: nothing can warn when the plugin is not loaded, since the warning would come from the plugin itself.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
the owner's reference project now gets bl, the write guard and the session doctor from the backlog-extras plugin via its project settings plus a one-time project-scope install. Verified live in that repo; the settings-only silent failure is documented with its fix.
<!-- SECTION:FINAL_SUMMARY:END -->
