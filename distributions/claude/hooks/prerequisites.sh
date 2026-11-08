#!/usr/bin/env bash
# Sourced before parsing hook input, so a missing parser never bypasses a write check.
if ! command -v python3 >/dev/null 2>&1; then
  echo 'backlog-extras: missing required dependency python3; install the runtime dependencies in requirements.json before using this plugin.' >&2
  exit 2
fi
if ! python3 "$(dirname "${BASH_SOURCE[0]}")/../bin/check-requirements" runtime; then
  exit 2
fi
