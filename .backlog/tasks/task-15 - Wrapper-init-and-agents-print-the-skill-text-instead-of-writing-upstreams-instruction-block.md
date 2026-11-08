---
id: TASK-15
title: >-
  Wrapper: init and agents print the skill text instead of writing upstream's
  instruction block
status: Done
assignee: []
created_date: '2026-10-21T05:29:00Z'
updated_date: '2026-11-08T20:39:00Z'
labels: []
milestone: m-2
dependencies:
  - TASK-14
priority: medium
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision 11 in doc-1. Checked on 1.55.0: `init --defaults` writes the block to AGENTS.md unless given `--agent-instructions none`. Without --defaults, init needs a terminal (else exits 1) and shows a file picker with nothing preselected and a 'Skip for now' option. Pitfall: `--agent-instructions none` makes init skip every prompt (folder, config location, prefix, integration mode) and use `backlog/`, so appending it turns interactive init into defaults-only init; and upstream rejects it with `--integration-mode mcp` or `none` (exit 1), modes that write no AGENTS.md anyway. `agents --update-instructions` is interactive (in a terminal it writes the chosen files; without one it writes nothing and exits 0). Markers: `<!-- BACKLOG.MD GUIDELINES START/END -->`, and `BACKLOG.MD MCP GUIDELINES` in MCP mode. Target files: AGENTS.md, CLAUDE.md, GEMINI.md, .github/copilot-instructions.md. `--install-claude-agent` (default false) and possibly the `backlog config` wizard offer a Claude agent install. Projects outside this repo that already carry the block need it removed by hand; the doctor finds them.

Impact on goal: doc-1 goal 1; upstream instruction writes in a plugin project, from every default `init` to none.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `backlog init` in cli mode (the default), with --defaults or interactively, with no `--agent-instructions` or any value but `none`, leaves every instruction file byte-identical to before (none created), keeps upstream's interactive prompts, and prints the skill text to stdout; with `--agent-instructions none` the output is upstream's alone
- [x] #2 `init --integration-mode mcp` and `--integration-mode none` behave exactly as upstream (exit 0, no instruction file)
- [x] #3 `init --install-claude-agent true` installs no agent file and prints the skill text
- [x] #4 `backlog agents --update-instructions`, run in a pseudo-terminal, changes no file, prints the skill text and exits 0
- [x] #5 `backlog doctor` reports each instruction file holding either upstream marker and exits 1 on a hit
- [x] #6 The corrected commands refuse to run off the pin, like the added ones; selftest covers every case above (interactive cases in a pseudo-terminal), each watched failing on the pre-change wrapper; doc-1 section 4 lists each correction with its reason; README updated
- [x] #7 `backlog config` wizard checked: if it writes instructions or installs the Claude agent it is covered the same way, otherwise doc-1 says it does not
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Proof (backlog.md 1.55.0):
- ./gate.sh exit 0 ((local log) task-15-gate.log).
- tests/selftest.sh exit 0, 114 ok ((local log) task-15-selftest-post-change.log); passed 3 times in a row (pseudo-terminal cases stable).
- AC1: selftest 'init --defaults ...' cases (plain, --agent-instructions claude,agents,gemini,copilot, --agent-instructions=none,agents, BACKLOG_CWD, empty dir) and 'interactive init keeps its prompts' (pty, picks CLAUDE.md): seeded AGENTS.md/CLAUDE.md byte-identical, no other file, skill on stdout; 'init --defaults --agent-instructions none is upstream's' (output+rc identical).
- AC2: 'init --defaults --integration-mode mcp' and '--integration-mode=none is upstream's': output and rc 0 identical to upstream, no file.
- AC3: 'init --defaults --install-claude-agent true writes no instructions, prints the skill' (no .claude/).
- AC4: 'agents --update-instructions changes nothing, prints the skill' (pty, in a project).
- AC5: 'doctor reports upstream instruction blocks' (AGENTS.md with GUIDELINES START, .github/copilot-instructions.md with MCP GUIDELINES named, plain CLAUDE.md not; rc 1); 'doctor without blocks exits 0'.
- AC6: 'version gate blocks corrected init/agents --update-instructions/config' (stub 9.9.9), 'off the pin init --integration-mode none passes through'; doc-1 section 4 'Corrections' list; README 'Corrected' section and skill install location; scripts/check_install.sh checks ../share/backlog-extras/SKILL.md in both modes and that installed bl prints it ((local log) task-15-check-install-post-change.log).
- AC7: config wizard walked in a pty and read in upstream's binary: writes no instruction file; its last prompt 'Install Claude Code Backlog.md agent?' installs .claude/agents/project-manager-backlog.md. Covered: bare 'backlog config' undoes it and prints the skill (selftest 'config wizard installs no Claude agent'); doc-1 records the finding.
Watched failing: pre-change wrapper (git show HEAD:plugins/backlog-extras/bin/backlog via SELFTEST_BL): 14 FAIL lines, every new case except the passthrough guards ((local log) task-15-selftest-pre-change.log). Passthrough cases (agent-instructions none, mcp, =none, off-pin passthrough) watched failing on a mutant with the passthrough test removed ((local log) task-15-selftest-mutant-no-passthrough.log). check_install against HEAD's install.sh: 'checkout: skill not installed in ../share/backlog-extras' ((local log) task-15-check-install-pre-change.log).

Correction to the watched-failing summary above (final review): three new checks are harness checks that pass on the pre-change wrapper too, so they were never seen red: 'interactive init showed the file picker', 'config wizard asked about the Claude agent' and 'doctor without blocks exits 0'. They guard the test setup (the pty reaches upstream's prompts; a clean project stays clean), not the change.
Final-review fix: init and the config wizard ignored only SIGINT while upstream ran, so SIGTERM or SIGHUP (terminal closed, harness timeout) killed the wrapper before the restore. Now SIGINT, SIGTERM and SIGHUP are all ignored during the run. Repro with a fake pinned upstream that writes AGENTS.md and .github/copilot-instructions.md then sleeps, signal sent to the process group after 2 s: pre-fix wrapper (HEAD e1096d8) TERM and HUP left AGENTS=BLOCK and .github/; fixed wrapper TERM, HUP and INT left AGENTS=mine and no .github/. Also: --agent-instructions NONE/None now counts as none (upstream treats it case-insensitively).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
init (cli mode), agents --update-instructions and the config wizard no longer leave upstream's instruction block or Claude agent behind: the wrapper runs upstream with its prompts, restores AGENTS.md, CLAUDE.md, GEMINI.md, .github/copilot-instructions.md and .claude/agents/project-manager-backlog.md byte for byte, and prints the backlog-md skill; mcp/none modes and --agent-instructions none pass through unchanged. doctor reports leftover blocks. install.sh installs the skill beside bl. Selftest, check_install, README and doc-1 section 4 updated.
<!-- SECTION:FINAL_SUMMARY:END -->
