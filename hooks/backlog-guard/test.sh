#!/usr/bin/env bash
# Feed sample PreToolUse inputs to the backlog-guard hook and assert allow/deny.
set -euo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/hook.sh"
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/.backlog" && : >"$ROOT/.backlog/config.yml"
export CLAUDE_PROJECT_DIR="$ROOT"
export XDG_STATE_HOME="$ROOT/state"  # the bypass log goes here, never to the real ~/.local/state
fail=0

run() { # run <expect allow|deny> <tool> <field> <value>
  local out got
  out=$(jq -n --arg t "$2" --arg f "$3" --arg v "$4" --arg c "$ROOT" \
    '{tool_name: $t, cwd: $c, tool_input: {($f): $v}}' | "$HOOK")
  got=allow
  [[ "$(jq -r '.hookSpecificOutput.permissionDecision // empty' <<<"${out:-null}")" == deny ]] && got=deny
  if [[ "$got" == "$1" ]]; then echo "ok   $1  $2: $4"; else echo "FAIL want $1 got $got  $2: $4"; fail=1; fi
}

run deny  Edit         file_path     "$ROOT/.backlog/tasks/task-001 - x.md"
run deny  Write        file_path     ".backlog/decisions/decision-1 - x.md"
run deny  Write        file_path     "$ROOT/docs/../.backlog/config.yml"
run deny  MultiEdit    file_path     "$ROOT/.backlog/docs/doc-1.md"
run deny  NotebookEdit notebook_path "$ROOT/.backlog/x.ipynb"
run allow Edit         file_path     "$ROOT/docs/findings.md"
run allow Write        file_path     "$ROOT/.backlogger/notes.md"

run deny  Bash command 'echo hi > .backlog/tasks/x.md'
run deny  Bash command 'echo hi >> "./.backlog/docs/doc-1 - A.md"'
run deny  Bash command "sed -i '' 's/a/b/' .backlog/tasks/*.md"
run deny  Bash command 'rm .backlog/decisions/decision-1*'
run deny  Bash command 'mv .backlog/docs/a.md .backlog/docs/b.md'
run deny  Bash command 'cat x | tee .backlog/tasks/t.md'
run deny  Bash command 'touch .backlog/milestones/m-9.md'
run deny  Bash command "python3 -c 'open(\".backlog/x\",\"w\")'"
run deny  Bash command 'git checkout -- .backlog/'
run deny  Bash command 'ls && rm -rf .backlog'

run allow Bash command 'backlog task edit TASK-1 --notes "x"'
run allow Bash command 'backlog decision update decision-1 --status accepted'
run allow Bash command 'cat .backlog/config.yml'
run allow Bash command 'ls .backlog/tasks 2>/dev/null'
run allow Bash command 'grep -rn status .backlog/decisions'
run allow Bash command 'git diff .backlog/'
run allow Bash command 'rm -f /tmp/scratch.md'
run allow Bash command "sed -n '1,5p' .backlog/config.yml"
run allow Bash command "sed -n '/Accept/,/Def/p' '.backlog/tasks/task-1 - Write-findings.md'"
# issue #2: a write verb or interpreter in one statement does not block a read of the board in another
run allow Bash command 'rm -rf /tmp/scratch && git add .backlog'
run allow Bash command 'python3 build.py && git status -- .backlog'
run allow Bash command 'grep -c x .backlog/config.yml; bash scripts/test.sh'
run deny  Bash command 'git status && rm .backlog/tasks/x.md'
run deny  Bash command 'ls .backlog/tasks | xargs rm'
run deny  Bash command 'cd .backlog && rm tasks/x.md'
run deny  Bash command '(cd .backlog/tasks; touch x.md)'
# shellcheck disable=SC2016 # the command text holds a literal $d
run deny  Bash command 'd=.backlog/tasks; rm -rf "$d"'
run deny  Bash command 'cd .backlog && python3 fix.py'
run allow Bash command 'sed -n 1p .backlog/config.yml --posix'
run deny  Bash command "sed --in-place 's/a/b/' .backlog/tasks/t.md"
run deny  Bash command "perl -pi -e 's/a/b/' .backlog/tasks/t.md"

# narrowing keeps these denied: a quoted path, a quoted cp destination, cp -t, rsync, a quoted nested shell
run deny  Bash command 'rm ".backlog/tasks/task-1 - x.md"'
run deny  Bash command 'cp notes.md ".backlog/tasks/a b.md"'
run deny  Bash command 'cp -t .backlog/tasks x.md'
run deny  Bash command 'rsync -a /tmp/x/ .backlog/'
run deny  Bash command 'bash -c "rm .backlog/x"'
run allow Bash command 'git commit -m "fix .backlog handling; rm stale"'

# GH #4 false positives (owner decision 2026-10-21): a cp source and quoted prose are not writes
run allow Bash command "t=\$(mktemp -d); cp -R $ROOT/.backlog \"\$t/\"; cd \"\$t\" && backlog decision update decision-1 --status x"
run allow Bash command "gh issue create --title x --body \"\$(cat <<'EOF'
The guard denies prose that mentions .backlog next to the word cp,
or a fragment like > .backlog/x.
Workaround: BACKLOG_GUARD_BYPASS=\"<reason>\" <cmd>
EOF
)\""
# review repros: a cp/rsync destination stays visible behind redirections, a comment, a trailing option or a -t cluster
run deny  Bash command 'cp /tmp/x.md .backlog/tasks/ 2>/dev/null'
run deny  Bash command 'cp /tmp/x.md .backlog/tasks/x.md 2>/dev/null || true'
run deny  Bash command 'cp -f -- /tmp/x.md .backlog/tasks/x.md 2>&1 | head'
run deny  Bash command 'cp a.md b.md .backlog/tasks/ 2>&1'
run deny  Bash command 'cp /tmp/x.md .backlog/tasks/ >/dev/null'
run deny  Bash command 'cp /tmp/x.md .backlog/tasks/  # restore'
run deny  Bash command 'cp -vt .backlog/tasks x'
run deny  Bash command 'cp x .backlog/tasks/ -f'
run deny  Bash command 'rsync -a /tmp/b/ .backlog/ 2>&1 | tail -1'
run allow Bash command 'rsync -rlt .backlog/ /tmp/b/'  # rsync -t keeps times; only cp -t names the target
run allow Bash command 'cp .backlog/tasks/x.md /tmp/ 2>&1  # backup'
# a quoted path with spaces, an unclosed quote, and heredocs the stripper must not let swallow the rest
run deny  Bash command 'rm "/Users/x/My Projects/p/.backlog/tasks/task-1 - a.md"'
run deny  Bash command "# it's a cleanup
rm .backlog/tasks/x.md"
run deny  Bash command "cat <<'END-NOTE' > /tmp/n
hello
END-NOTE
rm .backlog/tasks/x.md"
run deny  Bash command "x=\"\$(cat <<EOF
hi
EOF)\"
rm .backlog/x"
run allow Bash command "x=\"\$(cat <<EOF
rm .backlog/x is prose
EOF)\""
run deny  Bash command 'echo "see <<EOF in the docs"
rm .backlog/x'
# the bypass is an exact-case variable name, even where the disk ignores case
run deny  Bash command 'backlog_guard_bypass="x" rm .backlog/x'
# an interpreter whose text names the board stays denied; a per-command bypass with a reason lets it through, logged
handoff="python3 - <<'EOF'
from pathlib import Path
Path('.agents/HANDOFF.md').write_text('Board state lives in .backlog/; use the CLI.\\n')
EOF"
log="$XDG_STATE_HOME/backlog-extras/bypass.log"
run deny  Bash command "$handoff"
run deny  Bash command 'BACKLOG_GUARD_BYPASS="" rm .backlog/x'
run deny  Bash command "BACKLOG_GUARD_BYPASS='  ' rm .backlog/x"
BACKLOG_GUARD_BYPASS="exported" run deny  Bash command 'rm .backlog/x'
run allow Bash command "BACKLOG_GUARD_BYPASS=\"update handoff prose\" $handoff"
if [[ -f "$log" && "$(wc -l <"$log")" -eq 1 ]] && jq -e --arg p "$ROOT" --arg c "BACKLOG_GUARD_BYPASS=\"update handoff prose\" $handoff" \
  '.reason == "update handoff prose" and .project == $p and .command == $c and (.time | length > 0)' "$log" >/dev/null; then
  echo "ok   bypass logged once with reason, project and command"
else echo "FAIL bypass log: $(cat "$log" 2>/dev/null)"; fail=1; fi
# a bypass that cannot be logged is denied, and the reason says why (a file where the state directory should be)
: >"$ROOT/notadir"
reason=$(jq -n --arg c "$ROOT" '{tool_name: "Bash", cwd: $c, tool_input: {command: "BACKLOG_GUARD_BYPASS=\"x\" rm .backlog/x"}}' | XDG_STATE_HOME="$ROOT/notadir" "$HOOK" | jq -r '.hookSpecificOutput.permissionDecisionReason // empty')
if [[ "$reason" == *"bypass could not be logged"* ]]; then echo "ok   unloggable bypass denied with its cause"; else echo "FAIL unloggable bypass reason: $reason"; fail=1; fi

# a case-insensitive disk (macOS default) resolves .BACKLOG to .backlog; on a case-sensitive one it is another, unguarded folder
ci=allow; [[ "$ROOT/.BACKLOG" -ef "$ROOT/.backlog" ]] && ci=deny
run "$ci" Edit         file_path     "$ROOT/.BACKLOG/tasks/x.md"
run "$ci" Bash         command       'echo x > .Backlog/tasks/x.md'

# Codex: file edits arrive as one apply_patch whose headers name the targets; Codex sets no CLAUDE_PROJECT_DIR
patch() { printf '*** Begin Patch\n%s\n*** End Patch\n' "$1"; }
export BACKLOG_EXTRAS_HARNESS=codex
CLAUDE_PROJECT_DIR='' run deny  apply_patch command "$(patch '*** Update File: .backlog/tasks/task-1 - x.md
@@
-a
+b')"
run deny  apply_patch command "$(patch '*** Add File: docs/ok.md
+x
*** Delete File: '"$ROOT"'/.backlog/docs/doc-1.md')"
run deny  apply_patch command "$(patch '*** Update File: docs/a.md
*** Move to: .backlog/docs/a.md')"
run deny  apply_patch command "$(patch '*** Add File: docs/../.backlog/x.md  ')"
run "$ci" apply_patch command "$(patch '*** Add File: .BACKLOG/tasks/x.md
+x')"
run allow apply_patch command "$(patch '*** Update File: docs/findings.md
@@
-*** Update File: .backlog/x.md
+y')"
run deny  Bash        command 'rm .backlog/tasks/x.md'
# review repros: shell heredoc patch, argv-array patch, session started in a subdirectory
run deny  Bash        command "apply_patch <<'EOF'
$(patch '*** Add File: .backlog/tasks/x.md
+x')
EOF"
out=$(jq -n --arg c "$ROOT" --arg p "$(patch '*** Add File: .backlog/x.md
+x')" '{tool_name: "apply_patch", cwd: $c, tool_input: {command: ["apply_patch", $p]}}' | CLAUDE_PROJECT_DIR='' "$HOOK")
if [[ "$(jq -r .hookSpecificOutput.permissionDecision <<<"${out:-null}")" == deny ]]; then echo "ok   codex argv-array patch denied"; else echo "FAIL codex argv-array patch allowed"; fail=1; fi
mkdir -p "$ROOT/sub/deep"
ROOT="$ROOT/sub/deep" CLAUDE_PROJECT_DIR='' run deny  apply_patch command "$(patch '*** Add File: ../../.backlog/tasks/x.md
+x')"
ROOT="$ROOT/sub/deep" CLAUDE_PROJECT_DIR='' run deny  Bash        command 'rm ../../.backlog/config.yml'
ROOT="$ROOT/sub/deep" CLAUDE_PROJECT_DIR='' run allow apply_patch command "$(patch '*** Add File: notes.md
+x')"
out=$(jq -n --arg c "$ROOT" '{tool_name: "Bash", cwd: $c, tool_input: {command: "rm .backlog/x"}}' | "$HOOK")
if [[ "$(jq -r .hookSpecificOutput.permissionDecisionReason <<<"$out")" == *"/bin/backlog\`"* ]]; then echo "ok   codex deny names the wrapper path"; else echo "FAIL codex deny reason: $out"; fail=1; fi
unset BACKLOG_EXTRAS_HARNESS

# the deny reason names every command in the wrapper's table (and a known one, so an empty table fails)
reason=$(jq -n --arg c "$ROOT" '{tool_name: "Bash", cwd: $c, tool_input: {command: "rm .backlog/x"}}' | "$HOOK" | jq -r .hookSpecificOutput.permissionDecisionReason)
missing=$({ "$(dirname "$HOOK")/../../bin/backlog" --backlog-extras-commands || true; } | cut -f1 | while IFS= read -r u; do [[ "$reason" == *"$u"* ]] || echo "$u"; done)
if [[ "$reason" == *"decision view <id>"* && -z "$missing" ]]; then echo "ok   deny reason lists every added command"; else echo "FAIL deny reason misses: ${missing:-decision view <id>}"; fail=1; fi
if [[ "$reason" == *'BACKLOG_GUARD_BYPASS="<reason>"'*"$XDG_STATE_HOME/backlog-extras/bypass.log"* ]]; then echo "ok   deny reason names the bypass and its log"; else echo "FAIL deny reason lacks the bypass: $reason"; fail=1; fi

# not a Backlog project: the plugin may be enabled anywhere, so the hook must say nothing at all
plain=$(mktemp -d)
mkdir -p "$plain/.backlog"
for input in \
  "{\"tool_name\":\"Edit\",\"cwd\":\"$plain\",\"tool_input\":{\"file_path\":\"$plain/.backlog/x.md\"}}" \
  "{\"tool_name\":\"Bash\",\"cwd\":\"$plain\",\"tool_input\":{\"command\":\"rm -rf .backlog\"}}"; do
  out=$(CLAUDE_PROJECT_DIR="$plain" "$HOOK" <<<"$input"); rc=$?
  if [[ -z "$out" && "$rc" == 0 ]]; then echo "ok   silent outside a Backlog project"; else echo "FAIL not silent outside a Backlog project: $out"; fail=1; fi
done
rm -rf "$plain"

# unsupported layouts (backlog/config.yml, root backlog.config.yml): silent, the session doctor is the loud failure
for layout in backlog/config.yml backlog.config.yml; do
  other=$(mktemp -d)
  mkdir -p "$other/backlog" && : >"$other/$layout"
  for input in \
    "{\"tool_name\":\"Edit\",\"cwd\":\"$other\",\"tool_input\":{\"file_path\":\"$other/backlog/tasks/t.md\"}}" \
    "{\"tool_name\":\"Bash\",\"cwd\":\"$other\",\"tool_input\":{\"command\":\"rm backlog/tasks/t.md\"}}"; do
    out=$(CLAUDE_PROJECT_DIR="$other" "$HOOK" <<<"$input"); rc=$?
    if [[ -z "$out" && "$rc" == 0 ]]; then echo "ok   silent in a $layout project"; else echo "FAIL not silent in a $layout project: $out"; fail=1; fi
  done
  rm -rf "$other"
done

exit $fail
