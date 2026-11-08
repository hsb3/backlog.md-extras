#!/usr/bin/env bash
# Run tests/selftest.sh against every Backlog.md release in requirements.json "tested" (the gate already ran it on the pin).
# Each release is npm-installed once into a cache dir and reused.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/backlog-extras/tested"
read -r pin tested <<<"$(python3 -c 'import json,sys; r = json.load(open(sys.argv[1])); print(r["pins"]["backlog.md"], " ".join(r["tested"]["backlog.md"]))' "$REPO/requirements.json")"
fail=0
for v in $tested; do
  [[ "$v" == "$pin" ]] && continue
  bin="$cache/$v/bin"
  if [[ "$("$bin/backlog" --version 2>/dev/null)" != "$v" ]]; then
    npm install -g --prefix "$cache/$v" "backlog.md@$v" >/dev/null 2>&1 || { echo "FAIL npm install backlog.md@$v"; fail=1; continue; }
  fi
  home=$(mktemp -d)
  # an empty HOME: the wrapper prefers a managed install in ~/.local/share over PATH, which would test the wrong release
  if HOME="$home" PATH="$bin:$PATH" "$REPO/tests/selftest.sh" >"$home.log" 2>&1; then
    echo "ok   selftest on backlog.md $v"
  else
    echo "FAIL selftest on backlog.md $v:"; grep -E '^FAIL' "$home.log" || tail -5 "$home.log"; fail=1
  fi
  rm -rf "$home" "$home.log"
done
exit $fail
