---
id: TASK-24
title: >-
  Verify the piped install.sh with real gh, on Linux, and with a root-config
  project
status: Done
assignee: []
created_date: '2026-10-21T09:26:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels:
  - hardening
dependencies: []
priority: low
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Not verified in 0.4.0: the piped install (fake gh only), any Linux run, and projects whose Backlog.md config sits at the root (the wrapper's backlog_dir() shortcut does not find them).

Impact on goal: doc-1 goal 4 (a new machine gets everything from one command).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The piped one-liner installs bl and SKILL.md with real gh on macOS and on a Linux container; a root-config project either works or doc-1 records it as unsupported
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verification (builder-task24, 2026-10-21), logs in (local log) task-24-{macos-piped,linux-piped,root-config}.log.
macOS (Darwin 27.0.0 arm64, gh 2.102.0): literal one-liner 'gh api -H Accept:raw repos/hsb3/backlog.md-extras/contents/install.sh | sh' from empty cwd, BACKLOG_EXTRAS_INSTALL_DIR=<scratch>/mac/bin, SKIP_UPSTREAM=1. bl 0755; bl byte-identical to main wrapper (cmp); share/backlog-extras/SKILL.md identical to main skill; bl --version 1.55.0; 'bl agents --update-instructions </dev/null' in empty dir rc=0, prints skill body, no frontmatter. (Host already had backlog 1.55.0 so npm step reported 'already installed'.)
Linux: docker node:22-bookworm (node@sha256:69a5713e7f4997e96d579aafd78734810e0dac0dd5ee4621d72c27a2891a4088, arm64), Linux 7.0.14-linuxkit aarch64, Debian 12; gh 2.102.1 from cli.github.com apt, GH_TOKEN passed via -e from gh auth token (redacted/absent from log); node v22.23.3. One-liner with INSTALL_DIR=/tmp/x/bin, no SKIP: real 'npm install -g backlog.md@1.55.0' ran, bl+SKILL.md installed, wrapper and skill identical to main, bl/backlog --version 1.55.0, agents --update-instructions prints skill body w/o frontmatter. 'bl init demo --defaults' in fresh git dir: init says 'Created: AGENTS.md' but no AGENTS.md/CLAUDE.md/GEMINI.md exists afterwards, skill printed, rc=0. AC1 verified on both platforms.
Root-config: init --config-location root writes backlog.config.yml + backlog/ (tasks,docs,decisions,drafts,milestones,archive). Wrapper added commands (decision view/update, doctor extras) exit 1 'backlog-extras: no backlog project found (run backlog init)'; stock passthrough works (task list --plain; stock part of doctor). session-doctor hook: silent exit 0 (no briefing, no pin check). backlog-guard: allows Write to backlog/tasks/x.md, backlog.config.yml, backlog/docs/doc-1.md and Bash 'echo hi > backlog/tasks/x.md' (no protection). Cause: find_backlog_dir and both hooks only look for <root>/.backlog|backlog/config.yml. So root-config is unsupported today; doc-1 should record that (or code fix).

Phase 2 (TASK-19 fix, branch followups-0.4.2 head 5a3b208): piped 'gh api ... install.sh?ref=followups-0.4.2 | sh' (install.sh cmp-identical to git show followups-0.4.2:install.sh; it fetches wrapper+skill from main). macOS (gh 2.102.0, SKIP_UPSTREAM=1) and Linux (node:22-bookworm, same image as before, gh 2.102.1, real npm install of backlog.md 1.55.0 in the abs run), each run with an absolute install dir and a relative one (cwd=scratch, BACKLOG_EXTRAS_INSTALL_DIR=rel/bin, abs path on PATH). All four: output names the absolute dir ('wrote <abs>/bl', share beside its parent), no 'not on PATH' warning, bl identical to main wrapper, SKILL.md identical to main skill, bl --version 1.55.0, agents --update-instructions </dev/null prints the skill body without frontmatter. Logs: (local log) task-24-{macos,linux}-piped-branch.log.

Root config is recorded unsupported in doc-1 section 4 (wrapper added commands exit 1 'no backlog project found', config wizard unchanged, guard and session doctor silent). Branch install.sh piped through real gh (absolute and relative dirs): (local log) task-24-macos-piped-branch.log, task-24-linux-piped-branch.log.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
The piped one-liner installs bl and SKILL.md with real gh on macOS (gh 2.102.0) and in a node:22-bookworm arm64 container (gh 2.102.1, real npm install of backlog.md 1.55.0), both byte-identical to main; the branch install.sh piped the same way on both, with absolute and relative dirs. Root-config projects recorded unsupported in doc-1. Not covered: amd64 Linux.
<!-- SECTION:FINAL_SUMMARY:END -->
