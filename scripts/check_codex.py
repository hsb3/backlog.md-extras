#!/usr/bin/env python3
"""Install and upgrade the actual plugin with Codex, isolated from live accounts and config."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
a = p.parse_args()
root = a.root.resolve()
codex = shutil.which("codex")
if not codex:
    p.error("codex is required; see requirements.json")

with tempfile.TemporaryDirectory() as temp:
    scratch = Path(temp)
    source, home = scratch / "source", scratch / "home"
    shutil.copytree(root / ".agents", source / ".agents")
    shutil.copytree(root / "distributions/openai", source / "distributions/openai")
    runtime = source / "distributions/openai"
    (home / ".codex").mkdir(parents=True)
    env = {**os.environ, "HOME": str(home), "CODEX_HOME": str(home / ".codex"),
           "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull,
           "GIT_CONFIG_COUNT": "1", "GIT_CONFIG_KEY_0": f"url.{source.as_uri()}.insteadOf",
           "GIT_CONFIG_VALUE_0": "git@github.com:hsb3/backlog.md-extras.git"}

    def run(*args, cwd=scratch, ok=True):
        result = subprocess.run(args, cwd=cwd, env=env, capture_output=True, text=True, timeout=60)
        if ok and result.returncode:
            raise SystemExit(f"FAIL {' '.join(map(str, args))}:\n{result.stdout}{result.stderr}")
        return result

    def commit():
        run("git", "add", ".", cwd=source)
        run("git", "-c", "user.name=Marketplace check", "-c", "user.email=check@example.invalid",
            "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false",
            "commit", "-qm", "Marketplace fixture", cwd=source)

    run("git", "init", "-q", cwd=source)
    run("git", "symbolic-ref", "HEAD", "refs/heads/main", cwd=source)
    commit()
    marketplace = json.loads((source / ".agents/plugins/marketplace.json").read_text())["name"]
    manifest = runtime / ".codex-plugin/plugin.json"
    version = json.loads(manifest.read_text())["version"]
    selector = f"backlog-extras@{marketplace}"
    run(codex, "plugin", "marketplace", "add", "git@github.com:hsb3/backlog.md-extras.git", "--json")
    installed = json.loads(run(codex, "plugin", "add", selector, "--json").stdout)
    assert installed["version"] == version, installed
    cached = Path(installed["installedPath"])
    def files(folder):
        return {f.relative_to(folder).as_posix(): f.read_bytes() for f in folder.rglob("*") if f.is_file()}
    assert files(cached) == files(runtime), "installed files differ from distributions/openai"
    prompt = run(codex, "debug", "prompt-input", "-c", "features.remote_plugin=false",
                 "-c", "features.apps=false", "Check plugin discovery only").stdout
    assert "backlog-extras:backlog-md" in prompt, "installed skill missing from Codex prompt input"

    next_version = version.rsplit(".", 1)[0] + "." + str(int(version.rsplit(".", 1)[1]) + 1)
    data = json.loads(manifest.read_text())
    data["version"] = next_version
    manifest.write_text(json.dumps(data))
    marker = runtime / "upgrade-check.txt"
    marker.write_text("installed upgrade fixture\n")
    commit()
    run(codex, "plugin", "marketplace", "upgrade", marketplace, "--json")
    updated = json.loads(run(codex, "plugin", "list", "--marketplace", marketplace, "--json").stdout)
    assert updated["installed"][0]["version"] == next_version, updated
    assert (cached.parent / next_version / marker.name).read_text() == marker.read_text()

    invalid = scratch / "invalid"
    shutil.copytree(source, invalid, ignore=shutil.ignore_patterns(".git"))
    catalog = invalid / ".agents/plugins/marketplace.json"
    data = json.loads(catalog.read_text())
    data["name"] = "invalid-fixture"
    catalog.write_text(json.dumps(data))
    file = invalid / "distributions/openai/.codex-plugin/plugin.json"
    data = json.loads(file.read_text())
    data["interface"] = "invalid string"
    file.write_text(json.dumps(data))
    run(codex, "plugin", "marketplace", "add", str(invalid), "--json")
    rejected = run(codex, "plugin", "add", "backlog-extras@invalid-fixture", "--json", ok=False)
    assert rejected.returncode and "plugin.json" in rejected.stderr, rejected
    print("PASS: isolated Codex install, skill discovery, Git upgrade and invalid-manifest rejection")
