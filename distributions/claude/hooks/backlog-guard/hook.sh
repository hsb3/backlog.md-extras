#!/usr/bin/env bash
# PreToolUse: deny direct writes under .backlog/ so the backlog CLI stays the only writer.
set -euo pipefail
# shellcheck disable=SC1091 # bundled helper, resolved relative to this hook
source "$(dirname "$0")/../prerequisites.sh"

input=$(cat)
tool=$(jq -r '.tool_name' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
# Codex sets no CLAUDE_PROJECT_DIR and may start in a subdirectory, so walk up from cwd as the wrapper does
root="${CLAUDE_PROJECT_DIR:-}"
if [[ -z "$root" ]]; then
  root="${cwd:-$PWD}"
  while [[ "$root" != / && ! -f "$root/.backlog/config.yml" ]]; do root=$(dirname "$root"); done
fi
# .backlog/config.yml is the one supported layout; the session doctor is the loud failure for any other
[[ -f "$root/.backlog/config.yml" ]] || exit 0
dir="$root/.backlog"
# a case-insensitive disk (macOS default) lets .BACKLOG/ reach .backlog/, so the path compares and patterns below ignore case there (not the bypass prefix)
[[ "$root/.BACKLOG" -ef "$dir" ]] && shopt -s nocasematch
wrapper="$(cd "$(dirname "$0")/../.." && pwd)/bin/backlog"
cli=backlog
# Codex puts no plugin bin/ on PATH, so there the wrapper is reached by its full path
[[ "${BACKLOG_EXTRAS_HARNESS:-}" == codex ]] && cli=$wrapper
log="${XDG_STATE_HOME:-$HOME/.local/state}/backlog-extras/bypass.log"

deny() { # deny [prefix]: the prefix says why a bypass was refused
  # the wrapper's command table, read only here so allowed calls stay cheap
  local added msg
  added=$("$wrapper" --backlog-extras-commands 2>/dev/null | cut -f1 | awk -v cli="$cli" '{printf "%s`%s %s`", (NR > 1 ? ", " : ""), cli, $0}' || true)
  # a failed wrapper call leaves the list empty; point at help instead of naming nothing
  [[ -n "$added" ]] || added="those \`$cli --help\` lists"
  msg="${1:-}Backlog files are CLI-only. Use \`$cli\`, the backlog-extras wrapper, which adds or extends these Backlog.md commands: $added. Flags: \`$cli <cmd> --help\`. For a legitimate direct operation (repair, migration, a test on a copy), prefix that one Bash command with \`BACKLOG_GUARD_BYPASS=\"<reason>\"\`; the reason is logged to $log."
  jq -n --arg r "$msg" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

deny_inside() { # deny_inside <path>: deny when the path is in the backlog folder
  local path=$1
  [[ "$path" != /* ]] && path="${cwd:-$PWD}/$path"
  # normalise ./ and ../ segments without requiring the file to exist
  path=$(python3 -c 'import os,sys; print(os.path.normpath(sys.argv[1]))' "$path")
  if [[ "$path" == "$dir" || "$path" == "$dir"/* ]]; then deny; fi
}

deny_patch() { # deny_patch <text>: deny_inside every file a Codex patch names in its headers, both sides of a move included
  local path
  while IFS= read -r path; do deny_inside "$path"; done < <(sed -nE 's/^[[:space:]]*\*\*\* (Add File|Update File|Delete File|Move to): (.*[^[:space:]])[[:space:]]*$/\2/p' <<<"$1")
}

case "$tool" in
  Edit | Write | MultiEdit | NotebookEdit)
    path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
    [[ -z "$path" ]] && exit 0
    deny_inside "$path"
    ;;
  apply_patch)
    # every string in tool_input, so a patch sent as an argv array or under another key is still read
    deny_patch "$(jq -r '[.tool_input | .. | strings] | join("\n")' <<<"$input")"
    ;;
  Bash)
    cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
    [[ "$cmd" != *.backlog* ]] && exit 0
    # per-command bypass, read from the command text and never from the environment, so it cannot switch the guard off for a session
    bypass='^[[:space:]]*BACKLOG_GUARD_BYPASS=("([^"]*)"|'\''([^'\'']*)'\''|([^[:space:]"'\'']*))[[:space:]]'
    # the variable name is exact-case, so match it with case folding off
    nocase=$(shopt -p nocasematch || true); shopt -u nocasematch
    if [[ "$cmd" =~ $bypass ]]; then
      reason="${BASH_REMATCH[2]}${BASH_REMATCH[3]}${BASH_REMATCH[4]}"
      [[ -z "${reason//[[:space:]]/}" ]] && deny
      # an unrecorded bypass is not allowed
      { mkdir -p "$(dirname "$log")" && jq -nc --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg p "$root" --arg r "$reason" --arg c "$cmd" \
        '{time: $t, project: $p, reason: $r, command: $c}' >>"$log"; } 2>/dev/null || deny "The bypass could not be logged to $log, so it was refused. "
      exit 0
    fi
    $nocase
    # Codex also accepts apply_patch as a shell heredoc
    deny_patch "$cmd"
    # shortcut: pattern match, not a shell parser; obfuscated writes (variables, eval, base64) slip through, as do prefixed copies (sudo cp, env cp), cp/rsync options naming a file they write (--backup-dir, --log-file) and a second heredoc on one line. Upgrade to a sandbox write-deny rule if agents start evading it.
    # heredoc bodies are data (except to an interpreter, below): drop them; one that never closes is printed after all (fail safe)
    text=$(awk '
      skip { t = $0; if (tabs) sub(/^\t+/, "", t); if (t == delim) skip = 0; else if (index(t, delim ")") == 1) { skip = 0; print substr(t, length(delim) + 1) } else body = body $0 "\n"; next }
      { print }
      match($0, /(^|[^<])<<-?[ \t]*["'\''\\]?[A-Za-z_][A-Za-z0-9_.-]*/) {
        d = substr($0, RSTART, RLENGTH); sub(/^[^<]?<</, "", d); tabs = sub(/^-/, "", d); gsub(/^[ \t"'\''\\]+/, "", d); delim = d; skip = 1; body = "" }
      END { if (skip) printf "%s", body }
    ' <<<"$cmd")
    redirect='>>?[[:space:]]*["'\'']?[^[:space:]]*\.backlog'
    [[ "$text" =~ $redirect ]] && deny
    # quoted strings: a path to the board stays, as one word; other text is prose and becomes _; "$(...)" is code, so it is rescanned unquoted
    quoted='^([^"'\'']*)(["'\''])(.*)$' path='(^|/)\.backlog(/|$)' rest=$text masked=''
    while [[ "$rest" =~ $quoted ]]; do
      masked+=${BASH_REMATCH[1]} q=${BASH_REMATCH[2]} rest=${BASH_REMATCH[3]}
      # a quote that never closes (an apostrophe in a comment, don\'t) masks nothing after it (fail safe)
      [[ "$rest" == *"$q"* ]] || break
      str=${rest%%"$q"*} rest=${rest#*"$q"}
      if [[ "$q" == '"' && ( "$str" == *"\$("* || "$str" == *"\`"* ) ]]; then rest=$str$rest
      elif [[ "$str" =~ $path ]]; then masked+=${str//[[:space:]]/_}
      else masked+=_; fi
    done
    masked+=$rest
    # an interpreter or nested shell may write anywhere its text names; quoting would otherwise hide `bash -c "rm .backlog/x"`
    interp='(^|[;&|(`[:space:]])(python3?|node|ruby|bun|deno|sh|bash|zsh|eval)([[:space:]]|$)'
    [[ "$masked" =~ $interp ]] && deny
    # a cp/rsync writes only its destination, the last word that is not an option, unless -t (alone or in a cluster like -vt) names the target first
    # redirections (none names the board, checked above) go first, so their & does not split a segment and their target is not a destination
    plain=$(sed -E 's/[0-9]*(&>>?|>>?&?)[[:space:]]*[^[:space:];&|]*/ /g' <<<"$masked")
    final=''
    while IFS= read -r seg; do
      read -ra w <<<"${seg%%[[:space:]]#*}" # a trailing comment holds no operand
      if [[ "${w[0]:-}" == cp || "${w[0]:-}" == rsync ]]; then
        dest='' whole=''
        for x in "${w[@]:1}"; do
          # cp's -t names the target; rsync's -t keeps times
          case $x in --target-directory* | -t* | -[!-]*t*) [[ "${w[0]}" == rsync ]] || whole=1 ;; -*) ;; *) dest=$x ;; esac
        done
        [[ -n "$whole" ]] || seg="${w[0]} $dest"
      fi
      final+=$seg$'\n'
    done <<<"${plain//[;&|]/$'\n'}"
    [[ "$final" != *.backlog* ]] && exit 0
    verbs='(^|[;&|(`[:space:]])(rm|rmdir|mv|cp|rsync|tee|touch|truncate|ln|dd|install|mkdir|chmod)([[:space:]]|$)'
    # -i only as a short-flag cluster after whitespace, so slugs like Write-findings don't match
    inplace='(^|[;&|([:space:]])(sed|perl|gsed)[[:space:]]([^|;&]*[[:space:]])?(-[a-zA-Z]*i|--in-place)'
    gitw='git[[:space:]]+(checkout|restore|rm|mv|clean|reset|stash)'
    if [[ "$final" =~ $verbs || "$final" =~ $inplace || "$final" =~ $gitw ]]; then
      deny
    fi
    ;;
esac
exit 0
