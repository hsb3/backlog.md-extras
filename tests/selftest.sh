#!/usr/bin/env bash
# Exercise every wrapper extension command in a scratch project; checks use stock backlog reads.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
BL="${SELFTEST_BL:-$REPO/bin/backlog}"  # SELFTEST_BL: run these tests against another wrapper copy
WRAP_DIR="$(dirname "$BL")"
REAL=$(command -v backlog)
[[ "$REAL" -ef "$BL" ]] && { echo "FAIL run selftest without the plugin bin/ first on PATH"; exit 1; }
D=$(mktemp -d) I=$(mktemp -d)  # I: scratch projects for init, outside D's project so init never finds that one
# bash 3.2 can abort on an error with exit 0 (e.g. a bad substitution); finished proves the last check ran
trap 'rm -rf "$D" "$I"; [[ -n "${finished:-}" ]] || { echo "FAIL selftest stopped before its last check"; exit 1; }' EXIT
cd "$D"
git init -q
backlog init scratch --defaults --backlog-dir .backlog --integration-mode none --auto-open-browser false </dev/null >/dev/null

fail=0
check() { # check <label> <haystack> <needle>
  if grep -qF -- "$3" <<<"$2"; then echo "ok   $1"; else echo "FAIL $1: missing '$3'"; fail=1; fi
}
gone() { # gone <label> <haystack> <needle>
  if grep -qF -- "$3" <<<"$2"; then echo "FAIL $1: still has '$3'"; fail=1; else echo "ok   $1"; fi
}

# passthrough keeps output and exit code
check "passthrough output" "$("$BL" --version)" "$(backlog --version)"
set +e; "$BL" task view task-999 --plain </dev/null >/dev/null 2>&1; rc=$?; backlog task view task-999 --plain </dev/null >/dev/null 2>&1; want=$?; set -e
if [[ "$rc" == "$want" ]]; then echo "ok   passthrough exit code ($rc)"; else echo "FAIL passthrough exit code $rc != $want"; fail=1; fi

# the wrapper is named backlog and sits first on PATH in agent sessions: it must find the real one, not itself
# a self-exec loop never ends and its forks hold the output pipe, so kill the whole process group after <secs>
limit() { # limit <secs> <cmd...>
  perl -e '$s = shift; $p = fork; if (!$p) { setpgrp(0, 0); exec @ARGV } $SIG{ALRM} = sub { kill "KILL", -$p; exit 124 }; alarm $s; waitpid $p, 0; exit($? >> 8)' "$@"
}
set +e; out=$(PATH="$WRAP_DIR:$PATH" limit 20 backlog --version 2>&1); rc=$?; set -e
if [[ "$rc" == 0 && "$out" == "$(backlog --version)" ]]; then echo "ok   wrapper first on PATH passes through"; else echo "FAIL wrapper first on PATH (rc=$rc): $out"; fail=1; fi
set +e; out=$(PATH="$WRAP_DIR:$PATH" limit 20 backlog doctor 2>&1); rc=$?; set -e
if [[ "$rc" == 0 ]]; then echo "ok   wrapper first on PATH runs an added command"; else echo "FAIL wrapper first on PATH doctor (rc=$rc): $out"; fail=1; fi
# an executable backlog without read permission cannot be checked for a wrapper or run, so it is skipped
noread="$I/noread"; mkdir "$noread"; printf '#!/bin/sh\necho stub\n' >"$noread/backlog"; chmod 111 "$noread/backlog"
set +e; out=$(PATH="$noread:$PATH" limit 20 "$BL" --version 2>&1); rc=$?; set -e
if [[ "$rc" == 0 && "$out" == "$(backlog --version)" ]]; then echo "ok   unreadable backlog on PATH is skipped"; else echo "FAIL unreadable backlog on PATH (rc=$rc): $out"; fail=1; fi
nobacklog="$WRAP_DIR:$(dirname "$(python3 -c 'import sys; print(sys.executable)')"):/usr/bin:/bin"
set +e; out=$(HOME="$I/no-home" PATH="$nobacklog" limit 20 "$BL" --version 2>&1); rc=$?; set -e
if [[ "$rc" == 127 && "$out" == *"no real backlog"* ]]; then echo "ok   no real backlog exits 127"; else echo "FAIL no real backlog (rc=$rc): $out"; fail=1; fi

# A mise shim can exist even when the project's Node version has no backlog installed.
shim="$I/shim"; mkdir "$shim"
printf '#!/bin/sh\necho "mise: backlog is unavailable" >&2\nexit 1\n' >"$shim/mise"
chmod +x "$shim/mise"; ln -s mise "$shim/backlog"
set +e; out=$(PATH="$shim:$PATH" limit 20 "$BL" --version 2>&1); rc=$?; set -e
if [[ "$rc" == 0 && "$out" == "$(backlog --version)" ]]; then echo "ok   unavailable mise shim does not hide a working backlog"; else echo "FAIL unavailable mise shim (rc=$rc): $out"; fail=1; fi

# help: groups the wrapper does not extend are upstream's, byte for byte
rows=$("$BL" --backlog-extras-commands </dev/null || true)
[[ -n "$rows" ]] || { echo "FAIL --backlog-extras-commands printed nothing"; fail=1; }
extended=$(cut -f1 <<<"$rows" | cut -d' ' -f1 | sort -u)
for g in $(backlog --help </dev/null | sed -n '/^Commands:/,$s/^  \([a-z]*\).*/\1/p'); do
  # commander's own help command is the top-level help, which the wrapper extends
  [[ "$g" == help ]] && continue
  grep -qx "$g" <<<"$extended" && continue
  for form in "help $g" "$g --help"; do
    # shellcheck disable=SC2086 # form is two words on purpose
    if cmp -s <("$BL" $form </dev/null 2>&1; echo "rc=$?") <(backlog $form </dev/null 2>&1; echo "rc=$?"); then
      echo "ok   help unchanged: $form"; else echo "FAIL help differs from upstream: $form"; fail=1; fi
  done
done
# upstream's version flag wins anywhere in argv, help requests and added commands included
for form in "help -v" "help --version" "--help -v" "-h --version" "help decision -v" "decision --help -v" "doctor --help -v" "decision view -v"; do
  # shellcheck disable=SC2086 # form is several words on purpose
  if cmp -s <("$BL" $form </dev/null 2>&1; echo "rc=$?") <(backlog $form </dev/null 2>&1; echo "rc=$?"); then
    echo "ok   version flag is upstream's: $form"; else echo "FAIL version flag differs from upstream: $form"; fail=1; fi
done
helpcheck() { # helpcheck <scope words or ""> <argv...>: upstream's stdout unchanged, then exactly the rows under scope; exit 0
  local scope=$1 n rc want got; shift
  set +e; "$BL" "$@" </dev/null >"$D/.wrap-help" 2>/dev/null; rc=$?; set -e
  backlog "$@" </dev/null >"$D/.up-help" 2>/dev/null || true
  n=$(wc -c <"$D/.up-help")
  want=$(cut -f1 <<<"$rows" | awk -v s="$scope" 's == "" || index($0 " ", s " ") == 1')
  got=$(tail -c +$((n + 1)) "$D/.wrap-help" | sed -n '3,$s/^  \(.*[^ ]\)  .*/\1/p')
  if [[ "$rc" == 0 ]] && head -c "$n" "$D/.wrap-help" | cmp -s - "$D/.up-help" &&
    [[ "$(tail -c +$((n + 1)) "$D/.wrap-help" | sed -n 1,2p)" == $'\nAdded by backlog-extras:' && "$got" == "$want" ]]; then
    echo "ok   help adds the ${scope:-top-level} rows: $*"
  else echo "FAIL help for $* (rc=$rc), added rows: [$got] want [$want]"; fail=1; fi
}
helpcheck "" --help
helpcheck "" -h
helpcheck "" help
helpcheck milestone milestones --help
for g in $extended; do
  helpcheck "$g" help "$g"
  helpcheck "$g" "$g" --help
done
while IFS= read -r usage; do
  read -ra w <<<"$(sed -E 's/ [<[-].*//' <<<"$usage")"
  # upstream has this command itself when its help names it; otherwise it is the wrapper's own
  if backlog ${w[@]+"${w[@]}"} --help </dev/null 2>/dev/null | head -1 | grep -q "^Usage: backlog ${w[*]} "; then
    helpcheck "${w[*]}" ${w[@]+"${w[@]}"} --help
  else
    set +e; out=$("$BL" ${w[@]+"${w[@]}"} --help </dev/null 2>&1); rc=$?; set -e
    if [[ "$rc" == 0 && "$out" == "usage: backlog ${w[*]} "* ]]; then echo "ok   added command help: ${w[*]} --help"
    else echo "FAIL added command help ${w[*]} --help (rc=$rc): $out"; fail=1; fi
  fi
done < <(cut -f1 <<<"$rows")

# decision view / update / remove
backlog decision create "Use shim" </dev/null >/dev/null
check "decision view" "$("$BL" decision view decision-1)" "title: Use shim"

# two plugin copies on PATH (two plugin cache versions in one session) must not pick each other as the real backlog
copies=$(mktemp -d)
mkdir -p "$copies/a" "$copies/b" "$copies/old"
cp "$BL" "$copies/a/backlog"; cp "$BL" "$copies/b/backlog"
cp "$REPO/tests/fixtures/legacy-wrapper.py" "$copies/old/backlog"
chmod +x "$copies"/*/backlog
for order in "a:b" "b:a" "old:a"; do
  first="$copies/${order%%:*}" second="$copies/${order##*:}"
  set +e; out=$(PATH="$first:$second:$PATH" limit 5 backlog --version 2>&1); rc=$?; set -e
  if [[ "$rc" == 0 && "$out" == "$(backlog --version)" ]]; then echo "ok   two wrappers ($order) --version"; else echo "FAIL two wrappers ($order) --version (rc=$rc): $out"; fail=1; fi
  set +e; out=$(PATH="$first:$second:$PATH" limit 5 backlog decision view decision-1 2>&1); rc=$?; set -e
  if [[ "$rc" == 0 && "$out" == *"title: Use shim"* ]]; then echo "ok   two wrappers ($order) decision view"; else echo "FAIL two wrappers ($order) decision view (rc=$rc): $out"; fail=1; fi
done
rm -rf "$copies"
"$BL" decision update decision-1 --status "accepted: final" \
  --content $'## Context\n\nzebracontext\n\n## Decision\n\nUse it\n\n## Consequences\n\nNone' >/dev/null
check "decision search sees body" "$(backlog search zebracontext --plain </dev/null)" "decision-1"
check "decision status" "$("$BL" decision view decision-1)" "status: 'accepted: final'"
check "decision list reads it" "$(backlog decision list --plain </dev/null)" "Use shim"
# -h as an option value is a usage error, not a help request that exits 0
set +e; out=$("$BL" decision update decision-1 --content -h </dev/null 2>&1); rc=$?; set -e
if [[ "$rc" == 2 ]]; then echo "ok   --content -h is a usage error"; else echo "FAIL --content -h (rc=$rc): $out"; fail=1; fi
check "--content -h writes nothing" "$("$BL" decision view decision-1)" "zebracontext"
set +e; out=$("$BL" help decision view </dev/null 2>&1); rc=$?; set -e
if [[ "$rc" == 0 && "$out" == "usage: backlog decision view "* ]]; then echo "ok   help <added command> prints its usage"; else echo "FAIL help decision view (rc=$rc): $out"; fail=1; fi
"$BL" decision remove decision-1 >/dev/null
gone "decision remove" "$(backlog decision list --plain </dev/null)" "Use shim"

# milestone update by id and by title
backlog milestone add "Beta" --due-date 2026-12-01 </dev/null >/dev/null
"$BL" milestone update m-0 --description $'New scope\nsecond line' >/dev/null
check "milestone view shows description" "$("$BL" milestone view m-0)" $'New scope'
check "milestone due date kept" "$(backlog milestone list --plain </dev/null)" "due 2026-12-01"
"$BL" milestone update beta --description "by title" >/dev/null
check "milestone update by title" "$("$BL" milestone view Beta)" "by title"

# doc remove
backlog doc create "Scratch doc" </dev/null >/dev/null
"$BL" doc remove doc-1 >/dev/null
gone "doc remove" "$(backlog doc list --plain </dev/null)" "Scratch doc"
nested=$(backlog doc create "Nested doc" -p guides/api </dev/null | sed -n 's/^Created document //p')
"$BL" doc remove "$nested" >/dev/null
gone "doc remove in subfolder" "$(backlog doc list --plain </dev/null)" "Nested doc"

# doctor: stock checks plus archived draft IDs reused by live drafts
if "$BL" doctor >/dev/null 2>&1; then echo "ok   doctor clean project exits 0"; else echo "FAIL doctor clean project"; fail=1; fi
# since 1.54.0 an archived task keeps its ID reserved; an archived draft's ID is still reused
backlog task create "Needs old" -d "Follows on from TASK-2 and DRAFT-1" </dev/null >/dev/null
backlog task create "Old" </dev/null >/dev/null
backlog task archive TASK-2 </dev/null >/dev/null
check "archived task ID not reused" "$(backlog task create "New" </dev/null)" "TASK-3"
backlog draft create "Old draft" </dev/null >/dev/null
backlog draft archive DRAFT-1 </dev/null >/dev/null
backlog draft create "New draft" </dev/null >/dev/null
set +e; out=$("$BL" doctor 2>&1); rc=$?; set -e
if [[ "$rc" != 0 ]]; then echo "ok   doctor collision exits non-zero"; else echo "FAIL doctor collision exited 0"; fail=1; fi
check "doctor names draft collision" "$out" "DRAFT-1"
gone "doctor reports no task collision" "$out" "TASK-2"
check "doctor lists text referrer" "$out" "Needs-old"

# unknown id fails loudly
if "$BL" decision view decision-42 2>/dev/null; then echo "FAIL missing id exits 0"; fail=1; else echo "ok   missing id fails"; fi

# task edit --add-dep / --remove-dep merge with the current dependencies; plain --dep warns about what it drops
deps_of() { # deps_of <id>: direct dependencies from stock `task view --plain` (sorted there), comma-joined
  backlog task view "$1" --plain </dev/null | awk '/^Depends on/ {on = 1; next} on && /^[├└]─ / {print $2; next} {on = 0}' | paste -sd, -
}
newtask() { backlog task create "$@" </dev/null | sed -n 's/^Created task //p'; }
t1=$(newtask "Dep one") t2=$(newtask "Dep two") t3=$(newtask "Dep three") tx=$(newtask "Dependent" --dep "$t1")
"$BL" task edit "$tx" --add-dep "$t2,$(tr "[:upper:]" "[:lower:]" <<<"$t1")" --add-dep="$t3" --add-dep "${t2/-/-00}" -s "In Progress" </dev/null >/dev/null 2>&1 || true
if [[ "$(deps_of "$tx")" == "$t1,$t2,$t3" ]]; then echo "ok   --add-dep keeps, adds, dedupes"; else echo "FAIL --add-dep deps: $(deps_of "$tx")"; fail=1; fi
check "--add-dep passes other flags" "$(backlog task view "$tx" --plain </dev/null)" "Status: ◒ In Progress"
"$BL" task edit "$tx" --remove-dep "$t2" </dev/null >/dev/null 2>&1 || true
if [[ "$(deps_of "$tx")" == "$t1,$t3" ]]; then echo "ok   --remove-dep removes only that one"; else echo "FAIL --remove-dep deps: $(deps_of "$tx")"; fail=1; fi
"$BL" task edit "$tx" --remove-dep "$t1,$t3" </dev/null >/dev/null 2>&1 || true
if [[ -z "$(deps_of "$tx")" ]]; then echo "ok   --remove-dep of the last ones clears"; else echo "FAIL --remove-dep all: $(deps_of "$tx")"; fail=1; fi
for bad in "--dep $t1" "--depends-on $t1" "--clear-deps" ""; do
  read -ra extra <<<"$bad"
  if [[ -n "$bad" ]]; then args=("$tx" --add-dep "$t2" ${extra[@]+"${extra[@]}"}); else args=(--add-dep "$t2"); fi
  set +e; out=$("$BL" task edit ${args[@]+"${args[@]}"} </dev/null 2>&1); rc=$?; set -e
  if [[ "$rc" == 2 && -z "$(deps_of "$tx")" ]]; then echo "ok   usage error: --add-dep ${bad:-without a task id}"; else echo "FAIL --add-dep ${bad:-without a task id} (rc=$rc): $out"; fail=1; fi
done
backlog task edit "$tx" --dep "$t1,$t2" </dev/null >/dev/null
set +e; err=$("$BL" task edit "$tx" --dep "$t3" </dev/null 2>&1 >/dev/null); rc=$?; set -e
if [[ "$rc" == 0 && "$(deps_of "$tx")" == "$t3" && "$err" != *$'\n'* && "$err" == *"$t1"*"$t2"* ]]; then echo "ok   plain --dep replaces and names what it dropped"
else echo "FAIL plain --dep (rc=$rc) deps $(deps_of "$tx"), stderr: $err"; fail=1; fi
set +e; err=$("$BL" task edit "$tx" --depends-on "$t3,$t1" </dev/null 2>&1 >/dev/null); set -e
if [[ -z "$err" && "$(deps_of "$tx")" == "$t1,$t3" ]]; then echo "ok   --depends-on that drops nothing is silent"; else echo "FAIL --depends-on warned: $err"; fail=1; fi

# corrections: init, agents --update-instructions and the config wizard print the skill instead of writing upstream's block
skill=$(sed '1,/^---$/d' "$REPO/skills/backlog-md/SKILL.md")
PTY='
import fcntl, os, pty, select, struct, sys, termios
keys, fresh = [k for k in sys.argv[1].split("|") if k], False
pid, fd = pty.fork()
if pid == 0:
    fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 50, 200, 0, 0))  # at width 0 the prompts wrap every character
    os.execvp(sys.argv[2], sys.argv[2:])
while True:
    if select.select([fd], [], [], 1)[0]:
        try:
            data = os.read(fd, 4096)
        except OSError:  # the child closed the terminal (Linux)
            break
        if not data:  # the same on macOS
            break
        sys.stdout.buffer.write(data.replace(b"\r", b"")); fresh = True
    elif keys and fresh:  # output went quiet after a prompt: type the next answer
        os.write(fd, keys.pop(0).encode().decode("unicode_escape").encode()); fresh = False
    elif not keys:
        os.kill(pid, 9)
sys.exit(os.waitstatus_to_exitcode(os.waitpid(pid, 0)[1]))
'
ptyrun() { # ptyrun <keys, |-separated, escapes allowed> <cmd...>: run in a pseudo-terminal, typing each key when output goes quiet
  limit 90 python3 -c "$PTY" "$@"
}
fresh() { # fresh <name>: cd into a new git dir under I, optionally seeded with AGENTS.md and CLAUDE.md of known content
  mkdir "$I/$1" && cd "$I/$1" && git init -q
  [[ "${2:-}" == seeded ]] && printf 'own agents text\n' >AGENTS.md && printf 'own claude text\n' >CLAUDE.md
  return 0
}
untouched() { # untouched <label> <rc> <out>: rc 0, seeds intact, no other instruction file or agent dir, skill in out
  local extra; extra=$(find . -path ./.git -prune -o -path ./.backlog -prune -o -type f -print | grep -vx './AGENTS.md\|./CLAUDE.md' || true)
  if [[ "$2" == 0 && "$(cat AGENTS.md 2>/dev/null)" == "own agents text" && "$(cat CLAUDE.md 2>/dev/null)" == "own claude text" &&
        -z "$extra" && ! -e .github && ! -e .claude && "$3" == *"$skill"* ]]; then echo "ok   $1"
  else echo "FAIL $1 (rc=$2) extra files [$extra]: $(head -c 400 <<<"$3")"; fail=1; fi
}
reverted() { # reverted <label> <out> <files, comma-separated, or "">: exactly one revert line naming them, none for ""
  local got want=""; got=$(grep "^backlog-extras: reverted" <<<"$2" || true)
  [[ -n "$3" ]] && want="backlog-extras: reverted upstream's writes to $3; the backlog-md skill replaces its instructions"
  if [[ "$got" == "$want" ]]; then echo "ok   $1"; else echo "FAIL $1: revert line [$got] want [$want]"; fail=1; fi
}
for args in "--defaults" "--defaults --agent-instructions claude,agents,gemini,copilot" "--defaults --agent-instructions=none,agents" \
            "--defaults --install-claude-agent true" "--defaults --backlog-dir=./.backlog/"; do
  fresh "init-$((n = ${n:-0} + 1))" seeded
  read -ra a <<<"$args"
  set +e; out=$(limit 60 "$BL" init demo ${a[@]+"${a[@]}"} </dev/null 2>/dev/null); rc=$?; set -e
  untouched "init $args writes no instructions, prints the skill" "$rc" "$out"
  if [[ "$args" == *copilot ]]; then
    reverted "init $args names the reverted files" "$out" "AGENTS.md, CLAUDE.md, GEMINI.md, .github/copilot-instructions.md"
  fi
done
fresh init-new
set +e; out=$(limit 60 "$BL" init demo --defaults </dev/null 2>/dev/null); rc=$?; set -e
made=$(find . -path ./.git -prune -o -path ./.backlog -prune -o -print)
if [[ "$rc" == 0 && "$made" == . && -f .backlog/config.yml && ! -e backlog.config.yml && "$out" == *"$skill"* ]]; then
  echo "ok   init --defaults makes .backlog/config.yml and no instruction file"
else echo "FAIL init --defaults in an empty dir (rc=$rc) made: ${made//$'\n'/ }"; fail=1; fi
reverted "init --defaults names the AGENTS.md it removed" "$out" "AGENTS.md"
fresh init-cwd seeded
mkdir elsewhere
set +e; out=$(cd elsewhere && BACKLOG_CWD="$I/init-cwd" limit 60 "$BL" init demo --defaults </dev/null 2>/dev/null); rc=$?; set -e
rmdir elsewhere
untouched "init with BACKLOG_CWD restores there" "$rc" "$out"
fresh init-tty seeded
set +e; out=$(ptyrun 'demo\r|\r|\r|\r|\r| |\r|\r' "$BL" init); rc=$?; set -e
untouched "interactive init makes .backlog, writes no instructions" "$rc" "$out"
check "interactive init asked the project name" "$out" "Project name:"
# Ctrl-C at the first prompt: upstream exits 0 having written nothing, so there is no project to print the skill for
fresh init-cancel seeded
set +e; out=$(ptyrun '\x03' "$BL" init); rc=$?; set -e
if [[ "$rc" == 0 && ! -e .backlog && "$(cat AGENTS.md)" == "own agents text" && "$(cat CLAUDE.md)" == "own claude text" &&
      "$out" != *"$skill"* ]]; then echo "ok   cancelled interactive init prints no skill"
else echo "FAIL cancelled interactive init (rc=$rc): $(tail -c 400 <<<"$out")"; fail=1; fi
reverted "cancelled interactive init reports no revert" "$out" ""
# upstream writes no instructions here: the wrapper only adds the backlog dir and leaves the output alone
for args in "--defaults --agent-instructions none" "--defaults --integration-mode mcp" "--defaults --integration-mode=none"; do
  fresh "same-$((n = n + 1))"
  read -ra a <<<"$args"
  set +e; up=$(limit 60 backlog init demo ${a[@]+"${a[@]}"} --backlog-dir .backlog </dev/null 2>&1; echo "rc=$?"); rm -rf .backlog
  got=$(limit 60 "$BL" init demo ${a[@]+"${a[@]}"} </dev/null 2>&1; echo "rc=$?"); set -e
  made=$(find . -path ./.git -prune -o -path ./.backlog -prune -o -print)
  if [[ "$got" == "$up" && "$got" == *rc=0 && "$made" == . ]]; then echo "ok   init $args is upstream's"
  else echo "FAIL init $args differs from upstream or wrote [${made//$'\n'/ }]: $(diff <(echo "$up") <(echo "$got") | head -5)"; fail=1; fi
done
# only .backlog/config.yml is supported: init refuses any other layout before upstream runs
for args in "--backlog-dir backlog" "--backlog-dir=work" "--backlog-dir .BACKLOG" "--config-location root" "--integration-mode none --config-location=root"; do
  fresh "refuse-$((n = n + 1))"
  read -ra a <<<"$args"
  set +e; out=$(limit 60 "$BL" init demo --defaults ${a[@]+"${a[@]}"} </dev/null 2>&1); rc=$?; set -e
  if [[ "$rc" == 2 && "$out" == *".backlog/config.yml"* && "$(find . -path ./.git -prune -o -print)" == . ]]; then echo "ok   init $args refused"
  else echo "FAIL init $args not refused (rc=$rc): $out"; fail=1; fi
done
# re-init: upstream rejects --backlog-dir once the init directory has a project, so the wrapper must not add it
for args in "--defaults" "--defaults --integration-mode none"; do
  fresh "reinit-$((n = n + 1))"
  read -ra a <<<"$args"
  limit 60 "$BL" init demo ${a[@]+"${a[@]}"} </dev/null >/dev/null 2>&1 || true
  set +e; out=$(limit 60 "$BL" init demo ${a[@]+"${a[@]}"} </dev/null 2>&1); rc=$?; set -e
  if [[ "$rc" == 0 && -f .backlog/config.yml && ! -e backlog && ! -e backlog.config.yml ]]; then echo "ok   re-init $args keeps .backlog"
  else echo "FAIL re-init $args (rc=$rc): $(tail -c 400 <<<"$out")"; fail=1; fi
done
ran="$I/ran-stub"; mkdir "$ran"; printf '#!/bin/sh\ntouch "%s"\n' "$ran/backlog.ran" >"$ran/backlog"; chmod +x "$ran/backlog"  # leaves backlog.ran if run
# a project upstream made in another layout: init and the added commands fail naming the supported one
for args in "" "--config-location root"; do
  fresh "layout-$((n = n + 1))"
  read -ra a <<<"$args"
  backlog init demo --defaults --integration-mode none ${a[@]+"${a[@]}"} </dev/null >/dev/null 2>&1
  backlog task create one </dev/null >/dev/null; backlog task create two </dev/null >/dev/null
  for mode in "" "--integration-mode none"; do
    read -ra m <<<"$mode"
    set +e; out=$(PATH="$ran:$PATH" limit 20 "$BL" init demo --defaults ${m[@]+"${m[@]}"} </dev/null 2>&1); rc=$?; set -e
    if [[ "$rc" == 2 && "$out" == *".backlog/config.yml"* && ! -e "$ran/backlog.ran" ]]; then echo "ok   init${mode:+ $mode} in a ${args:-backlog/} project refused before upstream"
    else echo "FAIL init${mode:+ $mode} in a ${args:-backlog/} project (rc=$rc, upstream ran: $([[ -e "$ran/backlog.ran" ]] && echo yes || echo no)): $out"; fail=1; fi
    rm -f "$ran/backlog.ran"
  done
  for cmd in "decision view x" "doctor" "task edit 1 --add-dep 2"; do
    read -ra c <<<"$cmd"
    set +e; out=$("$BL" ${c[@]+"${c[@]}"} </dev/null 2>&1); rc=$?; set -e
    if [[ "$rc" == 1 && "$out" == "backlog-extras: "*".backlog/config.yml"* && "$out" != *$'\n'* ]]; then echo "ok   $cmd in a ${args:-backlog/} project names .backlog/config.yml"
    else echo "FAIL $cmd in a ${args:-backlog/} project (rc=$rc): $out"; fail=1; fi
  done
done
fresh agents-tty seeded
backlog init demo --defaults --backlog-dir .backlog --integration-mode none </dev/null >/dev/null 2>&1  # upstream offers its picker only in a project
set +e; out=$(ptyrun ' |\r' "$BL" agents --update-instructions); rc=$?; set -e
untouched "agents --update-instructions changes nothing, prints the skill" "$rc" "$out"
fresh config-tty seeded
backlog init demo --defaults --backlog-dir .backlog --integration-mode none </dev/null >/dev/null 2>&1
# answers: no shell completions, defaults, keep the Definition of Done (last choice), no web UI, then yes to the Claude agent
set +e; out=$(HOME="$I/config-tty/home" ptyrun 'n|\r|\r|\r|\r|\r|\r|\r|\x1b[A\r|\r|y' "$BL" config); rc=$?; set -e
rm -rf home
untouched "config wizard installs no Claude agent, prints the skill" "$rc" "$out"
check "config wizard asked about the Claude agent" "$out" "Install Claude Code Backlog.md agent?"
reverted "config wizard names the reverted Claude agent" "$out" ".claude/agents/project-manager-backlog.md"
lone=$(mktemp -d)
cp "$BL" "$lone/backlog"
set +e; err=$("$lone/backlog" agents --update-instructions </dev/null 2>&1 >/dev/null); rc=$?; set -e
rm -rf "$lone"
if [[ "$rc" == 0 && "$err" == *"github.com/hsb3/backlog.md-extras/blob/main/skills/backlog-md/SKILL.md"* ]]; then
  echo "ok   no skill file: one stderr line with its URL"; else echo "FAIL no skill file (rc=$rc): $err"; fail=1; fi

# doctor: a leftover upstream block in any instruction file is a hit
fresh doctor-blocks
backlog init demo --defaults --backlog-dir .backlog --integration-mode none </dev/null >/dev/null 2>&1
printf 'x\n<!-- BACKLOG.MD GUIDELINES START -->\n' >AGENTS.md
mkdir .github && printf '<!-- BACKLOG.MD MCP GUIDELINES START -->\n' >.github/copilot-instructions.md
printf 'mentions backlog only\n' >CLAUDE.md
set +e; out=$("$BL" doctor </dev/null 2>&1); rc=$?; set -e
if [[ "$rc" == 1 && "$out" == *AGENTS.md* && "$out" == *.github/copilot-instructions.md* && "$out" != *CLAUDE.md* ]]; then
  echo "ok   doctor reports upstream instruction blocks"; else echo "FAIL doctor instruction blocks (rc=$rc): $out"; fail=1; fi
rm AGENTS.md .github/copilot-instructions.md
set +e; "$BL" doctor </dev/null >/dev/null 2>&1; rc=$?; set -e
if [[ "$rc" == 0 ]]; then echo "ok   doctor without blocks exits 0"; else echo "FAIL doctor without blocks (rc=$rc)"; fail=1; fi
# GitHub #3: a config.yml that does not parse is refused before upstream reads it as empty settings and rewrites it
cp .backlog/config.yml config.good
printf '%s\n' 'definition_of_done: ["make check passes"]' "  - 'orphan item'" >>.backlog/config.yml
cp .backlog/config.yml config.bad
set +e; err=$("$BL" config set remoteOperations false </dev/null 2>&1); rc=$?; set -e
if [[ "$rc" == 1 && "$err" == *"does not parse (line "* ]] && cmp -s .backlog/config.yml config.bad; then
  echo "ok   malformed config: config set refused, file unchanged"; else echo "FAIL malformed config set (rc=$rc): $err"; fail=1; fi
set +e; out=$("$BL" doctor </dev/null 2>&1); rc=$?; set -e
if [[ "$rc" == 1 && "$out" == *"config.yml does not parse (line "*"indented line"* ]]; then
  echo "ok   doctor names the malformed config line"; else echo "FAIL doctor malformed config (rc=$rc): $out"; fail=1; fi
cp config.good .backlog/config.yml
if "$BL" config get projectName </dev/null >/dev/null 2>&1; then echo "ok   repaired config runs again"; else echo "FAIL repaired config"; fail=1; fi
cd "$D"

# version gate: extension commands refuse an untested backlog; passthrough does not
stub=$(mktemp -d)
cat >"$stub/backlog" <<'EOF'
#!/bin/sh
[ "$1" = --version ] && echo 9.9.9
exit 0
EOF
chmod +x "$stub/backlog"
set +e; out=$(HOME="$I/no-home" PATH="$stub:$PATH" "$BL" decision list 2>&1); rc=$?; gated=$(HOME="$I/no-home" PATH="$stub:$PATH" "$BL" milestone view m-0 2>&1); grc=$?; set -e
set +e; dgated=$(HOME="$I/no-home" PATH="$stub:$PATH" "$BL" task edit "$tx" --add-dep "$t2" 2>&1); drc=$?
dpass=$(HOME="$I/no-home" PATH="$stub:$PATH" "$BL" task edit "$tx" --dep "$t2" 2>&1); prc=$?; set -e
if [[ "$drc" != 0 && "$dgated" == *9.9.9* ]]; then echo "ok   version gate blocks --add-dep"; else echo "FAIL version gate let --add-dep run (rc=$drc): $dgated"; fail=1; fi
if [[ "$prc" == 0 && -z "$dpass" ]]; then echo "ok   off the pin plain --dep passes through without warning"; else echo "FAIL off-pin --dep (rc=$prc): $dpass"; fail=1; fi
for cmd in "init demo --defaults" "agents --update-instructions" "config"; do
  fresh "gate-$((n = n + 1))"; backlog init demo --defaults --backlog-dir .backlog --integration-mode none </dev/null >/dev/null 2>&1
  read -ra a <<<"$cmd"
  set +e; cout=$(HOME="$I/no-home" PATH="$stub:$PATH" limit 20 "$BL" ${a[@]+"${a[@]}"} </dev/null 2>&1); crc=$?; set -e
  if [[ "$crc" != 0 && "$cout" == *9.9.9* && "$cout" != *"$skill"* ]]; then echo "ok   version gate blocks corrected $cmd"
  else echo "FAIL version gate let corrected $cmd run (rc=$crc): $cout"; fail=1; fi
done
set +e; cout=$(HOME="$I/no-home" PATH="$stub:$PATH" "$BL" init demo --integration-mode none </dev/null 2>&1); crc=$?; set -e
if [[ "$crc" == 0 && -z "$cout" ]]; then echo "ok   off the pin init --integration-mode none passes through"; else echo "FAIL off-pin init passthrough (rc=$crc): $cout"; fail=1; fi
cd "$D"
rm -rf "$stub"
if [[ "$grc" != 0 ]]; then echo "ok   version gate blocks extension command"; else echo "FAIL version gate let milestone view run"; fail=1; fi
check "version gate names both versions" "$gated" "9.9.9"
if [[ "$rc" == 0 ]]; then echo "ok   passthrough not gated"; else echo "FAIL passthrough gated: $out"; fail=1; fi

finished=1
exit $fail
