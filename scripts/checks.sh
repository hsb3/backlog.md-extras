#!/bin/sh
# Shell and Python checks bin/gate runs before pytest: runs every step, fails if any failed.
cd "$(dirname "$0")/.." || exit 1
rc=0
step() { # name, cmd...
  name=$1; shift
  if "$@"; then echo "PASS: $name"; else echo "FAIL: $name"; rc=1; fi
}
# shellcheck disable=SC2329,SC2317 # called indirectly through step
quiet() { # run quietly; on failure rerun to show FAIL lines
  "$@" >/dev/null 2>&1 || { "$@" 2>&1 | grep -E 'FAIL|rror' ; return 1; }
}
p=.
step "declared prerequisites and pinned hosts" python3 "$p/bin/check-requirements" development
step "requirements and derived versions" python3 scripts/check_requirements.py
pin=$(sed -n 's/^BACKLOG_VERSION = "\(.*\)".*/\1/p' "$p/bin/backlog")
step "backlog.md on PATH is the pin ($pin)" test "$(backlog --version)" = "$pin"
step "wrapper self-test" quiet tests/selftest.sh
step "wrapper self-test on every other tested backlog.md" bash scripts/check_tested.sh
step "setup failure regressions" python3 tests/setup_test.py
for t in "$p"/hooks/*/test.sh; do
  step "hook test $(basename "$(dirname "$t")")" quiet "$t"
done
step "hook layout" python3 scripts/check_hook_layout.py
step "command tables and skill match the wrapper table" python3 scripts/check_commands.py
step "skill reviewed against the pin's workflow guides" sh scripts/check_upstream_guides.sh
step "installer (checkout and piped)" bash scripts/check_install.sh
step "Codex marketplace lifecycle" python3 scripts/check_codex.py
step "shellcheck" shellcheck install.sh bin/gate hooks/*.sh hooks/*/*.sh tests/*.sh scripts/*.sh
exit $rc
