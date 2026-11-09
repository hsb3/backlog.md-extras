#!/usr/bin/env bash
# SessionStart: put the plugin's backlog wrapper first on PATH, check the real backlog against its pin, brief the agent.
set -euo pipefail
# shellcheck disable=SC1091 # bundled helper, resolved relative to this hook
source "$(dirname "$0")/../prerequisites.sh"

input=$(cat)
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null || true)
# Codex sets no CLAUDE_PROJECT_DIR and may start in a subdirectory, so walk up from cwd as the wrapper does
root="${CLAUDE_PROJECT_DIR:-}"
if [[ -z "$root" ]]; then
  root="${cwd:-$PWD}"
  while [[ "$root" != / && ! -f "$root/.backlog/config.yml" && ! -f "$root/backlog/config.yml" && ! -f "$root/backlog.config.yml" ]]; do root=$(dirname "$root"); done
fi
if [[ ! -f "$root/.backlog/config.yml" ]]; then
  # upstream's other layouts: warn every session, since the guard and the wrapper's added commands refuse them
  for found in backlog/config.yml backlog.config.yml; do
    [[ -f "$root/$found" ]] || continue
    msg="backlog-extras: this project keeps its Backlog.md config in $found; backlog-extras supports only \`.backlog/config.yml\` at the project root. Until the project uses that layout, the backlog-guard hook and the wrapper's added commands do not work."
    jq -n --arg m "$msg" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $m}, systemMessage: $m}'
    break
  done
  exit 0
fi

plugin="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
wrapper="$plugin/bin/backlog"
pin=$(sed -n 's/^BACKLOG_VERSION = "\([^"]*\)".*/\1/p' "$wrapper")
tested=$(sed -n 's/^BACKLOG_TESTED = (\(.*\))$/\1/p' "$wrapper" | tr -d '"')  # "1.54.0, 1.55.0, ..."
release=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["pluginVersion"])' "$plugin/requirements.json")
install="gh api -H 'Accept: application/vnd.github.raw' 'repos/hsb3/backlog.md-extras/contents/install.sh?ref=v$release' | sh"
warn=()

added() { # added <prefix> <cli>: the wrapper's command table as "`<prefix><usage>` (summary); ...", so this list never drifts from it
  local list
  list=$("$wrapper" --backlog-extras-commands 2>/dev/null | awk -F'\t' -v cli="$1" '{printf "%s`%s%s` (%s)", (NR > 1 ? "; " : ""), cli, $1, $2}' || true)
  # a failed wrapper call leaves the list empty; point at help instead of naming nothing
  printf '%s' "${list:-the commands \`$2 --help\` lists}"
}

cli=backlog
if [[ "${BACKLOG_EXTRAS_HARNESS:-}" == codex ]]; then
  # Codex neither puts plugin bin/ on PATH nor gives hooks an env file, so the agent calls the wrapper by its full path
  cli=$wrapper
# Claude Code appends plugin bin/ to the end of PATH, where npm's backlog wins; the env file is sourced before every Bash call
elif [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  # shellcheck disable=SC2016 # $PATH must expand when the env file is sourced, not now
  printf 'export PATH="%s:$PATH"\n' "$plugin/bin" >>"$CLAUDE_ENV_FILE"
else
  warn+=("backlog-extras: Claude Code gave the hook no CLAUDE_ENV_FILE, so \`backlog\` is npm's and the added commands are missing this session. Run them as \`$wrapper <command>\`: $(added "" "$wrapper").")
fi

# the wrapper skips itself on PATH, so this reports the real backlog's version, or fails when there is none
found=$("$wrapper" --version 2>/dev/null | head -n1 || true)
if [[ -z "$found" || ", $tested, " != *", $found, "* ]]; then
  warn+=("backlog-extras: Backlog.md ${found:-not installed} found, the wrapper is tested against $tested (installs $pin); its added commands refuse to run until fixed. Fix: in a terminal run \`$install\`, or to add a release follow the \"Upgrade Backlog.md\" runbook in the backlog.md-extras spec.")
fi

guide="This project is managed with Backlog.md through its CLI; load the \`backlog-md\` skill (listed as \`backlog-extras:backlog-md\`) before any Backlog.md work; it is the complete workflow. Run it as \`$cli\`, the backlog-extras wrapper: it passes every command to Backlog.md and adds or extends: $(added "$cli " "$cli"). \`$cli --help\` lists them after upstream's help. Direct writes under the backlog folder are blocked by the backlog-guard hook. Run \`$cli doctor\` after \`$cli draft create\` or \`$cli task demote\` in a project with archived drafts, because their IDs get reused."

if ((${#warn[@]})); then
  msg=$(printf '%s\n' "${warn[@]}")
  jq -n --arg c "$msg"$'\n'"$guide" --arg s "$msg" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}, systemMessage: $s}'
else
  jq -n --arg c "$guide" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
fi
