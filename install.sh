#!/bin/sh
# Terminal install: backlog.md at the wrapper's pin in ../share/backlog-extras/upstream, plus the wrapper as bl in $BACKLOG_EXTRAS_INSTALL_DIR (default $HOME/.local/bin),
# and the backlog-md skill beside it in ../share/backlog-extras/SKILL.md, which bl prints from init and agents --update-instructions.
# Claude Code sessions get the wrapper (as backlog) and the hooks from the backlog-extras plugin instead. Rerun after a pin bump to upgrade.
# From a checkout: ./install.sh. Without one:
#   gh api -H 'Accept: application/vnd.github.raw' 'repos/hsb3/backlog.md-extras/contents/install.sh?ref=v0.7.2' | sh
set -eu
unset CDPATH  # an exported CDPATH makes cd echo, corrupting $(cd ... && pwd)
release=0.7.2
ref=${BACKLOG_EXTRAS_REF:-v$release}
case "$ref" in '' | -* | *[!a-zA-Z0-9._/-]*) echo 'install.sh: BACKLOG_EXTRAS_REF must be a tag, branch or commit without URL query characters' >&2; exit 1 ;; esac
command -v python3 >/dev/null || { echo 'install.sh: python3 is required; see requirements.json' >&2; exit 1; }
d="${BACKLOG_EXTRAS_INSTALL_DIR:-$HOME/.local/bin}"
rel=bin/backlog
skill_rel=skills/backlog-md/SKILL.md
requirements_rel=requirements.json
checker_rel=bin/check-requirements
mode=install
if [ -f "$0" ] && [ -f "$(dirname "$0")/$rel" ]; then
  checkout=$(cd "$(dirname "$0")" && pwd)
  bl="$checkout/$rel" skill="$checkout/$skill_rel"
  requirements="$checkout/$requirements_rel" checker="$checkout/$checker_rel"
else
  # Every file comes from the same immutable release, including when main has moved on.
  command -v gh >/dev/null || { echo "install.sh: gh not found; clone hsb3/backlog.md-extras and run ./install.sh" >&2; exit 1; }
  t=$(mktemp -d)
  trap 'rm -rf "$t"' EXIT
  mode=remote-install
  bl="$t/bl" skill="$t/SKILL.md" requirements="$t/requirements.json" checker="$t/check-requirements"
  # Resolve once: even a reviewed branch or moved tag must supply one commit's files.
  commit=$(gh api --jq .sha "repos/hsb3/backlog.md-extras/commits/$ref")
  case "$commit" in '' | *[!0-9a-f]*) echo 'install.sh: GitHub did not return a valid commit SHA' >&2; exit 1 ;; esac
  [ "${#commit}" -eq 40 ] || { echo 'install.sh: GitHub did not return a full commit SHA' >&2; exit 1; }
  ref=$commit
  gh api -H 'Accept: application/vnd.github.raw' "repos/hsb3/backlog.md-extras/contents/$rel?ref=$ref" >"$bl"
  gh api -H 'Accept: application/vnd.github.raw' "repos/hsb3/backlog.md-extras/contents/$skill_rel?ref=$ref" >"$skill"
  gh api -H 'Accept: application/vnd.github.raw' "repos/hsb3/backlog.md-extras/contents/$requirements_rel?ref=$ref" >"$requirements"
  gh api -H 'Accept: application/vnd.github.raw' "repos/hsb3/backlog.md-extras/contents/$checker_rel?ref=$ref" >"$checker"
fi
python3 "$checker" "$mode" --requirements "$requirements"
v=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["pins"]["backlog.md"])' "$requirements")
received=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["pluginVersion"])' "$requirements")
[ "$received" = "$release" ] || { echo "install.sh: expected plugin $release, received $received; use the installer from the same release" >&2; exit 1; }
grep -q "^BACKLOG_VERSION = \"$v\"" "$bl" || { echo 'install.sh: wrapper pin differs from requirements.json' >&2; exit 1; }
mkdir -p "$d"
d=$(cd "$d" && pwd)
share="$(dirname "$(cd "$d" && pwd -P)")/share/backlog-extras"
upstream="$share/upstream"

if [ "$("$upstream/bin/backlog" --version 2>/dev/null)" = "$v" ]; then
  echo "backlog.md $v already installed in $upstream"
elif [ -n "${BACKLOG_EXTRAS_SKIP_UPSTREAM:-}" ]; then
  echo "backlog.md install skipped (BACKLOG_EXTRAS_SKIP_UPSTREAM set)"
else
  command -v npm >/dev/null || { echo "install.sh: npm not found; install backlog.md@$v by hand" >&2; exit 1; }
  npm install -g --prefix "$upstream" "backlog.md@$v"
  found=$("$upstream/bin/backlog" --version)
  [ "$found" = "$v" ] || { echo "install.sh: expected backlog.md $v, found $found in $upstream" >&2; exit 1; }
  echo "installed backlog.md $found in $upstream"
fi

install -m 0755 "$bl" "$d/bl"
echo "wrote $d/bl"
# physical parent: the wrapper resolves its own symlinks to find the skill
mkdir -p "$share"
install -m 0644 "$skill" "$share/SKILL.md"
echo "wrote $share/SKILL.md"
install -m 0644 "$requirements" "$share/requirements.json"
install -m 0755 "$checker" "$share/check-requirements"
found=$("$d/bl" --version)
[ "$found" = "$v" ] || { echo "install.sh: installed wrapper must resolve backlog.md $v, found $found" >&2; exit 1; }
case ":$PATH:" in *":$d:"*) ;; *) echo "warning: $d is not on PATH" >&2 ;; esac
