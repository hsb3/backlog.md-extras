#!/usr/bin/env bash
# Run the session-doctor hook against stub backlog installs and assert the PATH prepend, warning, guidance or silence.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/hook.sh"
PLUGIN_BIN="$(cd "$HERE/../../bin" && pwd)"
PIN=$(sed -n 's/^BACKLOG_VERSION = "\([^"]*\)".*/\1/p' "$PLUGIN_BIN/backlog")
OLDEST=$(sed -n 's/^BACKLOG_TESTED = ("\([^"]*\)".*/\1/p' "$PLUGIN_BIN/backlog")  # a tested release other than the pin
[[ -n "$OLDEST" && "$OLDEST" != "$PIN" ]] || { echo "FAIL tested list needs a release besides the pin $PIN"; exit 1; }
# resolve tool dirs before narrowing PATH so the real backlog never leaks in
BASE="/usr/bin:/bin:$(dirname "$(command -v jq)"):$(dirname "$(python3 -c 'import sys; print(sys.executable)')")"
if PATH="$BASE" command -v backlog >/dev/null; then
  echo "FAIL base PATH already has backlog: $BASE"
  exit 1
fi
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME="$T/home"
mkdir -p "$T/proj/.backlog" "$T/plain" "$T/proj2/backlog" "$T/proj3/backlog/sub" "$T/empty"
: >"$T/proj/.backlog/config.yml"
: >"$T/proj2/backlog/config.yml"
: >"$T/proj3/backlog.config.yml"
fail=0

stub() { # stub <dir> <version>: a backlog that reports <version>
  mkdir -p "$1"
  printf '#!/bin/sh\necho %s\n' "$2" >"$1/backlog"
  chmod +x "$1/backlog"
}
stub "$T/wrong" 9.9.9
stub "$T/pinned" "$PIN"
stub "$T/oldest" "$OLDEST"

out='' rc=0 envf=''
hook() { # hook <path-prefix> <project-dir or ""> <stdin cwd> [noenv|codex]
  rc=0
  envf="$T/env.$RANDOM"
  : >"$envf"
  local e=(CLAUDE_ENV_FILE="$envf")
  [[ "${4:-}" == noenv ]] && e=()  # read as ${e[@]+...}: bash 3.2 calls an empty array unbound under set -u
  [[ "${4:-}" == codex ]] && e=(BACKLOG_EXTRAS_HARNESS=codex)
  out=$(jq -n --arg c "$3" '{hook_event_name: "SessionStart", cwd: $c}' |
    env -u CLAUDE_PLUGIN_ROOT -u CLAUDE_PROJECT_DIR -u CLAUDE_ENV_FILE ${2:+CLAUDE_PROJECT_DIR="$2"} ${e[@]+"${e[@]}"} PATH="$1:$BASE" "$HOOK") || rc=$?
}
check() { # check <name> <0 if the assertions held>
  if [[ "$2" == 0 && "$rc" == 0 ]]; then echo "ok   $1"; else echo "FAIL $1 (rc=$rc) out: $out env: $(cat "$envf")"; fail=1; fi
}
has() { jq -e --arg s "$2" "$1 // \"\" | contains(\$s)" <<<"${out:-null}" >/dev/null 2>&1; }
skill() { has .hookSpecificOutput.additionalContext "load the \`backlog-md\` skill" && has .hookSpecificOutput.additionalContext "before any Backlog.md work"; }
nosys() { jq -e 'has("systemMessage") | not' <<<"${out:-null}" >/dev/null 2>&1; }
prepends() { # sourcing the env file puts the plugin's bin/ first
  # shellcheck disable=SC1090,SC2123
  [[ "$(PATH=/sentinel; . "$envf"; echo "$PATH")" == "$PLUGIN_BIN:/sentinel" ]]
}

hook "$T/empty" "$T/plain" "$T/plain"
r=1; [[ -z "$out" && ! -s "$envf" ]] && r=0
check "silent outside a backlog project, env file untouched" "$r"

hook "$T/empty" "$T/proj" "$T/proj"
r=1; has .systemMessage "not installed" && has .systemMessage "$PIN" && has .systemMessage install.sh &&
  has .hookSpecificOutput.additionalContext "not installed" && has .hookSpecificOutput.additionalContext "$PIN" && r=0
check "backlog missing: warns with pin and fix" "$r"

hook "$T/wrong" "$T/proj" "$T/proj"
r=1; has .systemMessage 9.9.9 && has .systemMessage "$PIN" && has .systemMessage "Upgrade Backlog.md" &&
  has .hookSpecificOutput.additionalContext 9.9.9 && prepends && r=0
check "wrong version: warns with both versions, still prepends" "$r"

hook "$T/pinned" "$T/proj" "$T/proj"
r=1; nosys && prepends && has .hookSpecificOutput.additionalContext "Run it as \`backlog\`" &&
  ! has .hookSpecificOutput.additionalContext "bl " && ! has .hookSpecificOutput.additionalContext "decision view" && skill &&
  [[ "$(jq -r .hookSpecificOutput.hookEventName <<<"$out")" == SessionStart ]] && r=0
check "pinned: prepends plugin bin/, guidance names backlog and the skill, leaves the commands to the skill" "$r"

hook "$T/oldest" "$T/proj" "$T/proj"
r=1; nosys && prepends && r=0
check "tested release other than the pin: no warning" "$r"

hook "$T/pinned" "$T/proj" "$T/proj" noenv
r=1; has .systemMessage CLAUDE_ENV_FILE && has .hookSpecificOutput.additionalContext CLAUDE_ENV_FILE && has .systemMessage "as \`$PLUGIN_BIN/backlog\` instead" && r=0
check "no CLAUDE_ENV_FILE: warns loudly, naming the wrapper path" "$r"

hook "$T/pinned" "" "$T/proj" codex
r=1; nosys && has .hookSpecificOutput.additionalContext "Run it as \`$PLUGIN_BIN/backlog\`" &&
  skill && r=0
check "codex: no env file needed, guidance names the wrapper path and the skill" "$r"

mkdir -p "$T/proj/sub/deep"
hook "$T/pinned" "" "$T/proj/sub/deep" codex
r=1; nosys && has .hookSpecificOutput.additionalContext "Run it as" && r=0
check "codex: started in a subdirectory, still finds the project" "$r"

hook "$T/wrong" "" "$T/proj" codex
r=1; has .systemMessage 9.9.9 && ! has .systemMessage CLAUDE_ENV_FILE && r=0
check "codex: pin warning only" "$r"

unsupported() { # unsupported <found config>: one warning as systemMessage and context naming both layouts; no prepend, no guidance
  has .systemMessage "$1" && has .systemMessage "\`.backlog/config.yml\` at the project root" && ! skill &&
    [[ "$(jq -r .systemMessage <<<"$out")" == "$(jq -r .hookSpecificOutput.additionalContext <<<"$out")" && ! -s "$envf" ]]
}
hook "$T/pinned" "$T/proj2" "$T/proj2"
r=1; unsupported backlog/config.yml && r=0
check "backlog/config.yml project: warns naming .backlog/config.yml, no PATH prepend" "$r"
hook "$T/pinned" "$T/proj3" "$T/proj3"
r=1; unsupported backlog.config.yml && r=0
check "backlog.config.yml project: warns naming .backlog/config.yml, no PATH prepend" "$r"
hook "$T/pinned" "" "$T/proj3/backlog/sub"
r=1; unsupported backlog.config.yml && r=0
check "backlog.config.yml project found via stdin cwd" "$r"

exit "$fail"
