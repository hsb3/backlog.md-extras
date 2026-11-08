#!/usr/bin/env python3
"""backlog.md-extras wrapper: legacy self-only exclusion used by the loop regression."""
import os
import sys
from pathlib import Path

me = Path(__file__).resolve()
for directory in os.environ.get("PATH", "").split(os.pathsep):
    candidate = Path(directory or ".") / "backlog"
    if candidate.is_file() and os.access(candidate, os.X_OK) and candidate.resolve() != me:
        os.execv(str(candidate), ["backlog", *sys.argv[1:]])
raise SystemExit(127)
