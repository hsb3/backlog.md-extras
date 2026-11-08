#!/usr/bin/env bash
# Run install.sh from a checkout and piped (no checkout, bl and the skill via a fake gh), and check the installed bl works.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
w=$(mktemp -d)
trap 'rm -rf "$w"' EXIT

verify() { # verify <install dir> <mode>
  [[ -x "$1/bl" ]] || { echo "$2: bl not installed"; exit 1; }
  cmp -s "$1/bl" "$here/bin/backlog" || { echo "$2: installed bl differs from the plugin's wrapper"; exit 1; }
  [[ "$("$1/bl" --version)" == "$(backlog --version)" ]] || { echo "$2: installed bl does not pass through"; exit 1; }
  cmp -s "$1/../share/backlog-extras/SKILL.md" "$skill" || { echo "$2: skill not installed in ../share/backlog-extras"; exit 1; }
  cmp -s "$1/../share/backlog-extras/requirements.json" "$here/requirements.json" || { echo "$2: requirements not installed"; exit 1; }
  python3 "$1/../share/backlog-extras/check-requirements" runtime || exit 1
  [[ "$(cd "$w/empty" && "$1/bl" agents --update-instructions </dev/null)" == "$(sed '1,/^---$/d' "$skill")" ]] ||
    { echo "$2: installed bl does not print the installed skill"; exit 1; }
}
skill="$here/skills/backlog-md/SKILL.md"
mkdir -p "$w/empty"

BACKLOG_EXTRAS_INSTALL_DIR="$w/a" BACKLOG_EXTRAS_SKIP_UPSTREAM=1 PATH="$w/a:$PATH" sh "$here/install.sh" >/dev/null
verify "$w/a" checkout

# a relative dir must be named and PATH-checked by its absolute path, even with CDPATH exported (cd then echoes)
(cd "$w" && CDPATH="$w" BACKLOG_EXTRAS_INSTALL_DIR=rel/bin BACKLOG_EXTRAS_SKIP_UPSTREAM=1 PATH="$w/rel/bin:$PATH" sh "$here/install.sh" >"$w/rel.out" 2>&1)
grep -q "wrote $w/rel/bin/bl" "$w/rel.out" || { echo "relative: output does not name the absolute path"; exit 1; }
! grep -q 'not on PATH' "$w/rel.out" || { echo "relative: false not-on-PATH warning"; exit 1; }
verify "$w/rel/bin" relative

# the skill must land beside the link's target, where the installed bl resolves it
mkdir -p "$w/target/x/bin"
ln -s "$w/target/x/bin" "$w/link"
BACKLOG_EXTRAS_INSTALL_DIR="$w/link" BACKLOG_EXTRAS_SKIP_UPSTREAM=1 PATH="$w/link:$PATH" sh "$here/install.sh" >/dev/null
verify "$w/link" symlink

# fake gh: serves repos/hsb3/backlog.md-extras/contents/<path> from this checkout and logs each request
mkdir -p "$w/fake"
cat >"$w/fake/gh" <<EOF
#!/bin/sh
for a; do last=\$a; done
[ "\$last" != --version ] || { echo 'gh version 2.102.0'; exit 0; }
echo "\$last" >>"$w/gh.log"
case "\$last" in repos/hsb3/backlog.md-extras/commits/*) echo "\${FAKE_SHA-0123456789abcdef0123456789abcdef01234567}"; exit 0 ;; esac
last=\${last%%\\?*}
exec cat "$here/\${last#repos/hsb3/backlog.md-extras/contents/}"
EOF
chmod +x "$w/fake/gh"
(cd "$w/empty" && BACKLOG_EXTRAS_INSTALL_DIR="$w/b" BACKLOG_EXTRAS_SKIP_UPSTREAM=1 PATH="$w/fake:$w/b:$PATH" sh <"$here/install.sh" >/dev/null)
verify "$w/b" piped
grep -q 'contents/bin/backlog' "$w/gh.log" || { echo "piped: bl not fetched through gh"; exit 1; }
grep -q 'contents/skills/backlog-md/SKILL.md' "$w/gh.log" || { echo "piped: skill not fetched through gh"; exit 1; }
release=$(python3 -c 'import json,sys; print("v" + json.load(open(sys.argv[1]))["pluginVersion"])' "$here/requirements.json")
grep -q "commits/$release" "$w/gh.log" || { echo 'FAIL piped: release ref was not resolved to a commit'; exit 1; }
if grep 'contents/' "$w/gh.log" | grep -vF '?ref=0123456789abcdef0123456789abcdef01234567'; then
  echo 'FAIL piped: downloads did not all use the resolved commit'; exit 1
fi
(cd "$w/empty" && BACKLOG_EXTRAS_REF=reviewed-branch BACKLOG_EXTRAS_INSTALL_DIR="$w/c" BACKLOG_EXTRAS_SKIP_UPSTREAM=1 PATH="$w/fake:$w/c:$PATH" sh <"$here/install.sh" >/dev/null)
verify "$w/c" reviewed-ref
grep -q 'commits/reviewed-branch' "$w/gh.log" || { echo 'FAIL piped: override ref was not resolved'; exit 1; }
if grep 'contents/' "$w/gh.log" | grep -vF '?ref=0123456789abcdef0123456789abcdef01234567'; then
  echo 'FAIL piped: override downloads did not use the resolved commit'; exit 1
fi
for sha in '' 0123 invalid-sha; do
  if (cd "$w/empty" && FAKE_SHA="$sha" BACKLOG_EXTRAS_INSTALL_DIR="$w/rejected" BACKLOG_EXTRAS_SKIP_UPSTREAM=1 PATH="$w/fake:$PATH" sh <"$here/install.sh" >"$w/rejected.out" 2>&1); then
    echo "FAIL piped: accepted invalid commit SHA [$sha]"; exit 1
  fi
  if ! grep -q 'commit SHA' "$w/rejected.out" || [[ -e "$w/rejected" ]]; then
    echo 'FAIL piped: invalid SHA was not rejected before installation'; exit 1
  fi
done

# npm is the installation boundary; its prefix must survive a different project's Node selection.
pin=$(sed -n 's/^BACKLOG_VERSION = "\([^"]*\)".*/\1/p' "$here/bin/backlog")
mkdir -p "$w/runtime" "$w/shim"
ln -s "$(python3 -c 'import sys; print(sys.executable)')" "$w/runtime/python3"
printf '#!/bin/sh\nexit 1\n' >"$w/shim/mise"
chmod +x "$w/shim/mise"; ln -s mise "$w/shim/backlog"
cat >"$w/fake/npm" <<'EOF'
#!/bin/sh
set -eu
[ "${1:-}" != --version ] || { echo 12.2.0; exit 0; }
prefix=''
for arg; do
  if [ "${previous:-}" = --prefix ]; then prefix=$arg; fi
  previous=$arg
done
[ -n "$prefix" ] || { echo 'npm: missing stable prefix' >&2; exit 1; }
mkdir -p "$prefix/bin"
printf '#!/bin/sh\nprintf "%%s\\n" "%s"\n' "${arg#backlog.md@}" >"$prefix/bin/backlog"
chmod +x "$prefix/bin/backlog"
EOF
chmod +x "$w/fake/npm"
BACKLOG_EXTRAS_INSTALL_DIR="$w/home/.local/bin" PATH="$w/fake:$w/home/.local/bin:$PATH" sh "$here/install.sh" >/dev/null
fail=0
for bl in "$w/home/.local/bin/bl" "$here/bin/backlog"; do
  if got=$(HOME="$w/home" PATH="$w/shim:$w/runtime:/usr/bin:/bin" "$bl" --version 2>&1) && [[ "$got" == "$pin" ]]; then
    echo "ok   $bl finds the stable install behind an unavailable mise shim"
  else
    echo "FAIL stable install: $bl behind an unavailable mise shim: $got"; fail=1
  fi
done
exit "$fail"
