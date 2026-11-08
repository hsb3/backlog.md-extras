---
id: TASK-28
title: Resolve Backlog independently of the project Node version
status: Done
assignee:
  - '@codex'
created_date: '2026-10-24T02:27:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels: []
dependencies: []
priority: high
type: bug
ordinal: 28000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A consumer project selects Node 22.18.0 through mise, while Backlog.md 1.55.0 is installed under Node 26.10.0. The wrapper accepts the unavailable mise shim as the real CLI, and npm global installation follows the active Node version. The owner is handling the separate board layout migration.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The installer provides a pinned upstream CLI outside version-managed Node installations.
- [x] #2 The wrapper skips an unavailable mise shim and uses the installed fallback without changing project Node configuration.
- [x] #3 Working PATH installs, version gates, and missing-install failures retain their behavior.
- [x] #4 Regression checks fail before the fix; the full gate and live commands in the consumer project pass after it.
- [x] #5 Plugin 0.5.1 is published on origin/main and a clean marketplace install runs the fixed wrapper in the consumer project without a Node override.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add regression checks for an unavailable mise shim and the stable upstream installation.
2. Install upstream in the existing share/backlog-extras directory and add wrapper fallback discovery.
3. Run the full gate and verify the fixed wrapper in the consumer project with no Node override; update the local installed wrapper after validation.

4. Publish version 0.5.1 through a reviewed PR, verify remote manifests, and test a clean marketplace install.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verification: new unavailable-mise regression fails against a clean clone of pre-fix HEAD; both new terminal/plugin stable-install regressions fail against that clone. Updated tests pass with the fix. Full ./gate.sh passes before and after local installation, including wrapper, both hooks, installer, manifests, and ShellCheck. Independent read-only review found one stale README statement, now corrected. Real npm install into a scratch prefix succeeded. In the consumer project, node --version remains v22.18.0, installed Codex wrapper --version returns 1.55.0, and bl task list --count returns 1, without a Node override. Installed Codex wrapper and ~/.local/bin/bl match the source byte-for-byte. Logs and original wrappers: (local log) 20261024-node-version-fix/. The consumer project's board/config files were not changed. Temporary tool activation was removed after setup; global profiles were unchanged.

The owner explicitly authorized publication. Release checks: both manifests at 0.5.1, full gate, PR review, mergeability, remote main readback, and isolated marketplace install. No GitHub Actions workflow or existing release tags are configured.

Release candidate 0.5.1: both manifests match, full gate exited 0, independent review has no blocking findings, and the specification now records stable runtime discovery. An isolated Codex profile has the published 0.5.0 installed to verify the marketplace update after merge.

Published plugin 0.5.1 through PR #13 (https://github.com/hsb3/backlog.md-extras/pull/13), merge commit 1717a419fc152e0a203e22d367716de791084a8e. Fresh git ls-remote confirms origin/main at that commit, whose tree matches tested candidate 8ddc5bc. Both remote manifests are 0.5.1. Isolated Codex profile: installed old 0.5.0, refreshed marketplace, then ran plugin add; installed cache is 0.5.1 and its wrapper is byte-identical to published source (SHA256 493bba65579db6cabfe0c0ba8c865cdccad16f3942b6b11449c415a52c1b5124). That clean marketplace wrapper runs in the consumer project without a Node override: node v22.18.0, backlog 1.55.0, task count 1. Full local gate exited 0; GitHub has no configured checks. PR mergeability was CLEAN/MERGEABLE, both comment surfaces and reviews were empty, and independent local adversarial review had no blocking findings.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Released backlog-extras 0.5.1 on origin/main via PR #13. The installer uses a stable npm prefix and the wrapper skips unavailable Unix mise shims, preserving working PATH precedence and version gates. New regressions fail before the fix and pass after it; the full local gate passes. A clean marketplace update/install matches published source and reads the consumer project's board data under its unchanged Node 22.18.0 pin. The local terminal/Codex wrappers already contain the fix. GitHub Actions CI and a fresh interactive Codex hook-trust check were not run; publication was verified through remote readback and actual CLI execution.
<!-- SECTION:FINAL_SUMMARY:END -->
