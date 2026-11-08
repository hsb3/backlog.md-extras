"""Host CLIs accept and install the plugin. No model use; skipped when a CLI is absent.

Responsibilities: run strict `claude plugin validate` on the repository, its
marketplace and distributions/claude; run strict OpenSpec validation. PLUGIN_LIVE=1
adds one real `codex exec` turn in a temporary Codex home, which uses model quota.
scripts/check_codex.py covers the Codex install, upgrade and rejection checks.

Invariants: Codex installs go to a temporary CODEX_HOME, never the owner's; the live
turn links the existing auth.json instead of copying it, and runs read-only.
"""

import json
import os
from pathlib import Path
import shutil
import subprocess

import pytest

ROOT = Path(__file__).resolve().parents[2]
NAME = json.loads((ROOT / "plugin.json").read_text())["name"]
MARKETPLACE = json.loads((ROOT / ".agents/plugins/marketplace.json").read_text())["name"]
SKILL = sorted(p.parent.name for p in (ROOT / "skills").glob("*/SKILL.md"))[0]
needs_claude = pytest.mark.skipif(not shutil.which("claude"), reason="claude CLI not installed")
needs_openspec = pytest.mark.skipif(not shutil.which("openspec"), reason="openspec CLI not installed")
needs_codex = pytest.mark.skipif(not shutil.which("codex"), reason="codex CLI not installed")


def run(*args: str, env: dict | None = None, timeout: int = 120) -> str:
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout, env=env, cwd=ROOT)
    assert result.returncode == 0, f"{' '.join(args)}\n{result.stdout}\n{result.stderr}"
    return result.stdout


@needs_claude
@pytest.mark.parametrize("target", [".", ".claude-plugin/marketplace.json", "distributions/claude"])
def test_claude_strict_validation(target: str) -> None:
    run("claude", "plugin", "validate", "--strict", str(ROOT / target))


@needs_openspec
def test_openspec_strict_validation() -> None:
    run("openspec", "schema", "validate", "plugin-change")
    run("openspec", "validate", "--all", "--strict")


@pytest.fixture(scope="module")
def codex_home(tmp_path_factory: pytest.TempPathFactory) -> dict:
    """Install into a throwaway CODEX_HOME so the owner's Codex config is never touched."""
    home = tmp_path_factory.mktemp("codex-home")
    env = {**os.environ, "CODEX_HOME": str(home)}
    run("codex", "plugin", "marketplace", "add", str(ROOT), env=env)
    run("codex", "plugin", "add", f"{NAME}@{MARKETPLACE}", env=env)
    return env


@needs_codex
@pytest.mark.skipif(os.environ.get("PLUGIN_LIVE") != "1", reason="set PLUGIN_LIVE=1")
def test_codex_reads_installed_skill(codex_home: dict, tmp_path: Path) -> None:
    auth = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")) / "auth.json"
    assert auth.is_file(), "Log in to Codex first"
    # Symlink, not copy: the credential stays in one place and leaves with the temp home.
    (Path(codex_home["CODEX_HOME"]) / "auth.json").symlink_to(auth)
    skill = ROOT / "skills" / SKILL / "SKILL.md"
    marker = next(line[2:].strip() for line in skill.read_text().splitlines() if line.startswith("- "))
    prompt = (f"Read the installed ${NAME}:{SKILL} skill. Reply with its first bullet, verbatim. "
              "Do not run any command and do not write files.")
    out = run("codex", "exec", "--skip-git-repo-check", "--sandbox", "read-only",
              "-C", str(tmp_path), prompt, env=codex_home, timeout=600)
    assert marker in out
