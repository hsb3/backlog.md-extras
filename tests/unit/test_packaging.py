# Adapted from google/elephant-goldfish-model tests/unit/test_packaging.py (Apache-2.0); modified.
"""Runtime packages hold exactly the shipped files, safely and reproducibly.

Responsibilities: check pack_plugin ships only allowlisted files, byte-identically
across builds and with fixed timestamps and modes; that it rejects symlinks,
escaping or missing manifest references and hook scripts, hooks declared in
plugin.json, MCP and app dependencies,
incomplete sources, and existing or concurrently claimed outputs; and that the
checked-in distributions/ equal a fresh build.

Invariants: builds into and edits only copies under pytest's temporary directory;
never modifies the repository.
"""

import json
from pathlib import Path
import re
import runpy
import shutil
import zipfile

import pytest

ROOT = Path(__file__).resolve().parents[2]
PACK = runpy.run_path(str(ROOT / "scripts/pack_plugin.py"))
build = PACK["build"]
NAME = json.loads((ROOT / "plugin.json").read_text())["name"]
SKILL = sorted(p.parent.name for p in (ROOT / "skills").glob("*/SKILL.md"))[0]
SOURCE_ITEMS = ("plugin.json", "LICENSE", "README.md", "AGENTS.md", "TESTING.md", "skills", "agents", "resources",
                "docs", "assets", "evals", "openspec", ".claude-plugin", ".codex-plugin", ".agents",
                "requirements.json", "bin", "hooks")
RUNTIME = {"requirements.json", "bin/backlog", "bin/check-requirements", "hooks/hooks.json",
           "hooks/codex-hooks.json", "hooks/prerequisites.sh", "hooks/backlog-guard/hook.sh",
           "hooks/session-doctor/hook.sh"}


@pytest.fixture
def source(tmp_path: Path) -> Path:
    root = tmp_path / "source"
    root.mkdir()
    for name in SOURCE_ITEMS:
        if (ROOT / name).is_dir():
            shutil.copytree(ROOT / name, root / name,
                            ignore=shutil.ignore_patterns("__pycache__", "results"))
        elif (ROOT / name).exists():
            shutil.copyfile(ROOT / name, root / name)
    return root


def contents(folder: Path) -> dict[str, bytes]:
    return {p.relative_to(folder).as_posix(): p.read_bytes()
            for p in folder.rglob("*") if p.is_file()}


@pytest.mark.parametrize("target", ["claude", "openai"])
def test_runtime_is_complete_reproducible_and_lean(
    source: Path, tmp_path: Path, target: str,
) -> None:
    for name in ("tests/secret.txt", ".github/workflows/a.yml", "hooks/run.sh",
                 "assets/private.txt", "docs/designs/idea.md", "bin/gate", "openspec/specs/x/spec.md",
                 f"skills/{SKILL}/references/.env", f"skills/{SKILL}/scripts/.DS_Store"):
        file = source / name
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text("must not ship")
    nested = source / f"skills/{SKILL}/references/nested/deep.md"
    nested.parent.mkdir(parents=True)
    nested.write_text("# Deep\n")
    script = source / f"skills/{SKILL}/scripts/run.sh"
    script.parent.mkdir(parents=True, exist_ok=True)
    script.write_text("#!/bin/sh\n")
    script.chmod(0o755)
    first, archive = build(source, target, tmp_path / "first")
    _, repeated = build(source, target, tmp_path / "second")
    assert archive.read_bytes() == repeated.read_bytes()
    with zipfile.ZipFile(archive) as bundle:
        assert bundle.testzip() is None
        names = set(bundle.namelist())
        skills = {p.parent.name for p in source.glob("skills/*/SKILL.md")}
        assert {n.split("/")[1] for n in names if n.endswith("/SKILL.md")} == skills
        for image in re.findall(r'<img\b[^>]*\bsrc="([^"]+)"', bundle.read("README.md").decode()):
            assert image in names, f"Unbundled README image: {image}"
        assert not any(n.startswith(("tests/", ".github/", ".agents/", "evals/",
                                     "docs/designs/", "distributions/", "openspec/"))
                       or n.endswith("marketplace.json") for n in names)
        # the wrapper and hooks ship; the dev gate, hook tests and hook configs do not
        assert {n for n in names if n.startswith(("bin/", "hooks/")) or n == "requirements.json"} == RUNTIME
        assert not names & {"AGENTS.md", "TESTING.md", "assets/private.txt"}
        assert (".claude-plugin/plugin.json" in names) == (target == "claude")
        assert ("plugin.json" in names) == (target == "claude"), "Codex would read it instead of .codex-plugin"
        assert {n for n in names if n.startswith("agents/")} == {
            p.relative_to(source).as_posix() for p in source.glob("agents/*.md")}
        assert (".codex-plugin/plugin.json" in names) == (target == "openai")
        for info in bundle.infolist():
            assert info.date_time == (1980, 1, 1, 0, 0, 0)
            executable = (source / info.filename).stat().st_mode & 0o111
            assert info.external_attr >> 16 == (0o100755 if executable else 0o100644)
            assert bundle.read(info) == (first / info.filename).read_bytes()
        assert f"skills/{SKILL}/references/nested/deep.md" in names
        assert bundle.getinfo(f"skills/{SKILL}/scripts/run.sh").external_attr >> 16 == 0o100755
        assert not any(Path(n).name in (".env", ".DS_Store") for n in names)
    check_links = runpy.run_path(str(ROOT / "tests/unit/test_link_integrity.py"))[
        "test_relative_markdown_links_resolve_on_disk"]
    check_links(first)


@pytest.mark.parametrize("directory", [False, True])
def test_rejects_symlinked_runtime_paths(source: Path, tmp_path: Path, directory: bool) -> None:
    victim = source / ("docs" if directory else "assets/icon.svg")
    outside = tmp_path / "outside"
    shutil.move(str(victim), outside)
    victim.symlink_to(outside, target_is_directory=directory)
    with pytest.raises(ValueError, match="Symlink"):
        build(source, "openai", tmp_path / "output")


@pytest.mark.parametrize("reference", ["../escape.svg", "/tmp/icon.svg", "./assets/missing.svg"])
def test_rejects_escaping_or_missing_manifest_assets(
    source: Path, tmp_path: Path, reference: str,
) -> None:
    path = source / "plugin.json"
    manifest = json.loads(path.read_text())
    manifest["extensions"]["com.openai"]["interface"]["logo"] = reference
    path.write_text(json.dumps(manifest))
    with pytest.raises(ValueError, match="Unbundled"):
        build(source, "openai", tmp_path / "output")


def test_refuses_overwrites_and_misplaced_or_unbundled_hooks(source: Path, tmp_path: Path) -> None:
    output = tmp_path / "output"
    build(source, "claude", output)
    with pytest.raises(ValueError, match="already exists"):
        build(source, "claude", output)
    path = source / "plugin.json"
    manifest = json.loads(path.read_text())
    path.write_text(json.dumps({**manifest, "hooks": "./hooks/hooks.json"}))
    with pytest.raises(ValueError, match="hooks"):
        build(source, "claude", tmp_path / "other")
    path.write_text(json.dumps(manifest))
    (source / "hooks/session-doctor/hook.sh").unlink()
    with pytest.raises(ValueError, match="Unbundled.*session-doctor"):
        build(source, "openai", tmp_path / "third")


@pytest.mark.parametrize("field", ["apps", "mcpServers"])
def test_refuses_unbundled_services(source: Path, tmp_path: Path, field: str) -> None:
    path = source / "plugin.json"
    manifest = json.loads(path.read_text())
    manifest["extensions"]["com.openai"][field] = "./missing.json"
    path.write_text(json.dumps(manifest))
    with pytest.raises(ValueError, match="dependencies"):
        build(source, "openai", tmp_path / "output")


@pytest.mark.parametrize("target", ["claude", "openai"])
@pytest.mark.parametrize("missing", [
    "skills", f"skills/{SKILL}/SKILL.md", f"skills/{SKILL}/agents/openai.yaml",
    f"skills/{SKILL}/assets/icon.svg", "LICENSE", "docs/claude.md", "docs/codex.md", "assets/icon.svg",
    "requirements.json", "bin/backlog", "hooks/hooks.json", "hooks/codex-hooks.json",
])
def test_incomplete_source_fails_before_output(
    source: Path, tmp_path: Path, target: str, missing: str,
) -> None:
    path = source / missing
    if path.is_dir():
        shutil.rmtree(path)
        path.mkdir()
    else:
        path.unlink()
    output = tmp_path / "output"
    with pytest.raises(ValueError, match="Missing required file"):
        build(source, target, output)
    assert not output.exists()


@pytest.mark.parametrize("target", ["claude", "openai"])
@pytest.mark.parametrize("suffix", ["", ".zip"])
def test_rejects_dangling_output_symlinks(
    source: Path, tmp_path: Path, target: str, suffix: str,
) -> None:
    output = tmp_path / "output"
    output.mkdir()
    outside = tmp_path / "outside"
    link = output / f"{NAME}-{target}{suffix}"
    link.symlink_to(outside, target_is_directory=not suffix)
    with pytest.raises(ValueError, match="already exists"):
        build(source, target, output)
    assert not outside.exists()
    assert list(output.iterdir()) == [link]


@pytest.mark.parametrize("target", ["claude", "openai"])
@pytest.mark.parametrize("claim", ["file", "dangling-symlink", "symlink"])
def test_archive_claimed_after_preflight_is_not_overwritten(
    source: Path, tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
    target: str, claim: str,
) -> None:
    output = tmp_path / "output"
    archive = output / f"{NAME}-{target}.zip"
    outside = tmp_path / "outside.zip"
    if claim == "symlink":
        outside.write_bytes(b"outside file must not change")
    original_zipfile = zipfile.ZipFile

    def claim_archive(*args, **kwargs):
        if claim == "file":
            archive.write_bytes(b"another build owns this file")
        else:
            archive.symlink_to(outside)
        return original_zipfile(*args, **kwargs)

    monkeypatch.setattr(zipfile, "ZipFile", claim_archive)
    with pytest.raises(FileExistsError):
        build(source, target, output)
    if claim == "file":
        assert archive.read_bytes() == b"another build owns this file"
    else:
        assert archive.is_symlink()
        if claim == "symlink":
            assert outside.read_bytes() == b"outside file must not change"
        else:
            assert not outside.exists()
    assert not list(output.glob(".pack-*"))


@pytest.mark.parametrize("target", ["claude", "openai"])
def test_published_runtime_is_current(tmp_path: Path, target: str) -> None:
    """Marketplaces install distributions/<target>; it must equal a fresh build."""
    generated, _ = build(ROOT, target, tmp_path)
    published = ROOT / "distributions" / target
    assert contents(published) == contents(generated), (
        "Run python3 scripts/pack_plugin.py --sync")
