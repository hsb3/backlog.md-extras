#!/usr/bin/env python3
"""Exercise setup failures against disposable plugin copies, never registered hooks."""
import json
import os
from pathlib import Path
import shutil
import shlex
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
# the shipped runtime, as a marketplace installs it
PLUGIN = Path(os.environ.get("SETUP_TEST_PLUGIN", ROOT / "distributions/openai"))


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.plugin = self.root / "plugin"
        shutil.copytree(PLUGIN, self.plugin)
        self.project = self.root / "project"
        (self.project / ".backlog").mkdir(parents=True)
        (self.project / ".backlog/config.yml").touch()
        self.env = {**os.environ, "HOME": str(self.root / "home"),
                    "CLAUDE_PROJECT_DIR": "", "CLAUDE_PLUGIN_ROOT": "",
                    "BACKLOG_EXTRAS_HARNESS": "codex"}

    def stub(self, path, version):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f'#!/bin/sh\nprintf "%s\\n" "{version}"\n')
        path.chmod(0o755)

    def test_managed_pin_wins_over_conflicting_path(self):
        self.stub(self.root / "path/backlog", "9.9.9")
        self.stub(self.root / "home/.local/share/backlog-extras/upstream/bin/backlog", "1.55.3")
        result = subprocess.run([str(self.plugin / "bin/backlog"), "--version"],
                                env={**self.env, "PATH": str(self.root / "path") + ":" + os.environ["PATH"]},
                                text=True, capture_output=True, cwd=self.project)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "1.55.3")

    def test_unrunnable_managed_install_does_not_hide_path(self):
        self.stub(self.root / "path/backlog", "1.55.3")
        managed = self.root / "home/.local/share/backlog-extras/upstream/bin/backlog"
        managed.parent.mkdir(parents=True)
        managed.write_text("invalid executable\n")
        managed.chmod(0o755)
        result = subprocess.run([str(self.plugin / "bin/backlog"), "--version"],
                                env={**self.env, "PATH": str(self.root / "path") + ":" + os.environ["PATH"]},
                                text=True, capture_output=True, cwd=self.project)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "1.55.3")

    def test_missing_parsers_block_with_actionable_error(self):
        payload = json.dumps({"cwd": str(self.project), "tool_name": "Bash",
                              "tool_input": {"command": "printf probe > .backlog/probe.md"}})
        for missing in ("jq", "python3"):
            minimal = self.root / f"without-{missing}"
            minimal.mkdir()
            for command in ("bash", "cat", "dirname", "sed", "head", "awk", "python3", "jq", "uname"):
                if command != missing:
                    (minimal / command).symlink_to(shutil.which(command))
            for hook in ("session-doctor", "backlog-guard"):
                with self.subTest(hook=hook, missing=missing):
                    result = subprocess.run(["/bin/bash", str(self.plugin / f"hooks/{hook}/hook.sh")],
                                            env={**self.env, "PATH": str(minimal)}, input=payload,
                                            text=True, capture_output=True, cwd=self.project, timeout=10)
                    self.assertEqual(result.returncode, 2, result.stderr)
                    self.assertIn("required", result.stderr)
                    self.assertIn(missing, result.stderr)
                    self.assertIn("requirements.json", result.stderr)

    def test_layout_checker_rejects_invalid_codex_interface(self):
        fixture = self.root / "source"
        for name in ("hooks", "skills", ".claude-plugin", ".codex-plugin"):
            shutil.copytree(ROOT / name, fixture / name)
        manifest = fixture / ".codex-plugin/plugin.json"
        data = json.loads(manifest.read_text())
        data["interface"] = "invalid string"
        manifest.write_text(json.dumps(data))
        result = subprocess.run(["python3", str(ROOT / "scripts/check_hook_layout.py"), str(fixture)],
                                text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0, "invalid interface passed the checker")
        self.assertIn("interface", result.stdout + result.stderr)

    def test_old_jq_blocks_with_required_version(self):
        shadow = self.root / "old-jq"
        shadow.mkdir()
        jq = shadow / "jq"
        jq.write_text('#!/bin/sh\nif [ "$1" = --version ]; then echo jq-1.5; else exec '
                      + shlex.quote(shutil.which("jq")) + ' "$@"; fi\n')
        jq.chmod(0o755)
        payload = json.dumps({"cwd": str(self.project), "tool_name": "Bash",
                              "tool_input": {"command": "printf probe > .backlog/probe.md"}})
        for hook in ("session-doctor", "backlog-guard"):
            with self.subTest(hook=hook):
                result = subprocess.run(["/bin/bash", str(self.plugin / f"hooks/{hook}/hook.sh")],
                                        env={**self.env, "PATH": str(shadow) + ":" + os.environ["PATH"]},
                                        input=payload, text=True, capture_output=True, cwd=self.project)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn("jq must be >=1.6", result.stderr)

    def test_declared_pin_drift_is_rejected(self):
        fixture = self.root / "requirements-fixture"
        for name in ("bin", "assets", ".claude-plugin", ".codex-plugin", ".github"):
            shutil.copytree(ROOT / name, fixture / name)
        shutil.copy2(ROOT / "requirements.json", fixture / "requirements.json")
        (fixture / "scripts").mkdir()
        shutil.copy2(ROOT / "scripts/check_requirements.py", fixture / "scripts/check_requirements.py")
        shutil.copy2(ROOT / "install.sh", fixture / "install.sh")
        command = ["python3", str(fixture / "scripts/check_requirements.py")]
        valid = subprocess.run(command, text=True, capture_output=True)
        self.assertEqual(valid.returncode, 0, valid.stdout + valid.stderr)
        declaration = fixture / "requirements.json"
        data = json.loads(declaration.read_text())
        data["pins"]["backlog.md"] = "9.9.9"
        declaration.write_text(json.dumps(data))
        invalid = subprocess.run(command, text=True, capture_output=True)
        self.assertNotEqual(invalid.returncode, 0)
        self.assertIn("BACKLOG_VERSION", invalid.stdout)


if __name__ == "__main__":
    unittest.main()
