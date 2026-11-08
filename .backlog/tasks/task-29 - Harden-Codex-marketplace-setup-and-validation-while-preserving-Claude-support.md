---
id: TASK-29
title: Harden Codex marketplace setup and validation while preserving Claude support
status: Done
assignee:
  - '@codex'
created_date: '2026-10-24T04:02:00Z'
updated_date: '2026-10-24T05:45:00Z'
labels: []
dependencies: []
priority: high
type: enhancement
ordinal: 29000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The marketplace installs in both hosts, but a conflicting PATH runtime defeats the managed pin, undeclared hook dependencies fail without guidance, and the Codex checker accepts manifests the host rejects. The owner authorized all audit improvements and an explicit dependency/version declaration.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 One bundled machine-readable file declares runtime and development requirements, exact compatibility pins and release identity; consumers and checks read it or verify derived copies.
- [x] #2 A correctly pinned managed Backlog installation is selected ahead of an incompatible PATH copy; checkout and piped setup stay on one requested release.
- [x] #3 Missing hook prerequisites produce clear errors and direct-write checks fail closed; regressions are observed failing against pre-fix copies.
- [x] #4 The gate proves isolated Codex installation and upgrade, rejects invalid Codex manifests, validates Claude unchanged, and runs from a source export without Git history; CI is configured to run it on macOS and Linux.
- [x] #5 Both marketplaces remain compatible; Codex listing metadata, supported platforms, hook coverage, trust and restart instructions are documented and checked.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Declare release, exact host/upstream pins, dependency minimums and CI references in requirements.json, with drift checks.
2. Fix managed runtime selection, release-consistent setup and fail-closed prerequisite handling, observing regressions red before fixes.
3. Retain the shared Claude-compatible catalog; add Codex manifest listing metadata and icon, real install/upgrade checks, a history-free legacy fixture and pinned CI.
4. Update README and doc-1 through the CLI; run focused checks and the full gate from a source export, then inspect the diff.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented on branch codex-marketplace-hardening for plugin 0.6.0. requirements.json declares the Backlog.md 1.55.0 data-format pin, Codex 0.163.0 and Claude 2.1.310 tested host pins, tool minimums, supported platforms, CI runtime versions and action SHAs. The gate checks derived manifest, wrapper, installer and workflow values. No new Python or JS package dependency was added.

Fresh proof: the complete gate exited 0 in a copied source export without any Git metadata. It passed the wrapper self-test, hook tests, layout and command-table checks, checkout and release-pinned piped installer checks, actual Codex lifecycle checks, both Claude strict validators and ShellCheck. The latest standalone setup_test.py run passed all 6 tests, including the additional old-jq case added after the export run. git diff --check passed.

Observed red before green: a managed pin losing to PATH (9.9.9 vs 1.55.0); missing jq and Python (old hooks returned 127 or 0, new hooks exit 2 with actionable requirements guidance); jq 1.5 being accepted; a malformed Codex interface accepted by the old checker; unpinned piped downloads; and an unrunnable managed executable raising instead of falling back. Removing version-drift validation from a disposable checker copy also made its regression fail.

The real Codex check uses isolated HOME and CODEX_HOME, a temporary Git repository and URL rewriting to local files. It confirms installed wrapper/skill/requirements/icon bytes, skill listing, a new installed version and marker after marketplace upgrade, and malformed-manifest rejection. No model or account is required. Source hook scripts were tested only through disposable copies, never by mutating a live registered cache.

README and doc-1 document requirements, supported platforms, actual upgrade refresh, the need to restart after cache replacement, hook trust, and accepted workdir/MCP-editor/write_stdin guard limits. One marketplace catalog remains shared because Codex supports it; host manifests and hook registrations remain separate.

Limits: GitHub-hosted CI has been configured, not executed or pushed. Release v0.6.0 has not been published, so its remote installation one-liner is not available until the tag is published. Piped setup was verified against a fake GitHub transport and npm boundary; no fresh interactive hook-trust sessions or native Windows support were claimed.

Final pre-release review tightened piped setup: release tags and optional reviewed branch refs are resolved once to a full commit SHA before fetching any artifact. The installer regression was observed failing before this fix. A disposable mutation removing SHA validation was rejected by the added empty/short/invalid-SHA cases. Focused installer checks and ShellCheck pass. Publication is authorized by the owner; PR CI/review and release readback follow.

First GitHub run exercised the behavioral gate successfully on Ubuntu, then ShellCheck 0.9 reported the indirectly invoked quiet callback (SC2317) and an assertion written as A && B || C (SC2015). Added the callback-specific suppression and rewrote the assertion as an explicit if. Matrix fail-fast is disabled so one platform cannot hide the other platform result. Local installer, ShellCheck and declaration checks pass; updated CI must be green before merge.

Published 0.6.0 after PR #14 merged at 3eb24d6f5871bccea5f1e185b1f7cff5e9bca87e. The remote v0.6.0 tag was read back at that exact commit and the GitHub release is published (not draft or prerelease): https://github.com/hsb3/backlog.md-extras/releases/tag/v0.6.0 . The checked PR tree and merge tree are identical. All macOS/Linux PR checks passed on head 88db136; main CI run 40066990201 and release-tag run 40067174515 also passed.

Published-artifact verification passed using real GitHub and npm transports into disposable directories: terminal setup installed Backlog.md 1.55.0 and the 0.6.0 wrapper/requirements, then wrapper decision creation/view and skill printing worked. Codex installed 0.6.0 from the SSH marketplace at tag v0.6.0, and its installed guard returned a structured deny. Claude installed 0.6.0 through the same SSH marketplace into isolated CLAUDE_CONFIG_DIR. No live plugin registrations were changed and no model was called. A temporary-HOME credential lookup initially returned 404; keeping gh on its authenticated HOME while isolating install state resolved the probe issue without a product change.

CI review fixed both Linux ShellCheck findings and replaced the deprecated Node-20 action pins with verified v6 Node-24 action SHAs. No bot reviews or inline findings were posted; local adversarial review was performed. The pre-existing license decision remains on the public-readiness task; repository visibility remains private.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Merged PR #14 and published backlog-extras v0.6.0 at 3eb24d6. macOS/Linux PR, main and tag CI passed. Real terminal, Codex and Claude installs of the published artifacts passed in disposable environments, including the installed guard denial. Explicit dependency/pin declaration, safe setup, lifecycle checks and Claude compatibility are delivered. Public-directory publication and fresh interactive hook-trust sessions are outside this release proof.
<!-- SECTION:FINAL_SUMMARY:END -->
