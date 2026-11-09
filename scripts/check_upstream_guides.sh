#!/bin/sh
# The backlog-md skill restates upstream's workflow guides (decision 20). Fail when the pinned release's guides
# differ from the snapshot the skill was last reviewed against; after reviewing the skill, refresh it with --update.
cd "$(dirname "$0")/.." || exit 1
snap=tests/fixtures/upstream-instructions.md
guides() { for g in overview task-creation task-execution task-finalization; do backlog instructions "$g" || return 1; done; }
if [ "${1:-}" = --update ]; then guides >"$snap"; exit; fi
guides | diff -u "$snap" - || { echo "FAIL upstream guides changed: review skills/backlog-md/SKILL.md, then $0 --update"; exit 1; }
