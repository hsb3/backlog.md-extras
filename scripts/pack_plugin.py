#!/usr/bin/env python3
# Adapted from google/elephant-goldfish-model scripts/pack_plugin.py (Apache-2.0); modified.
"""Build runtime folders and reproducible ZIPs without development files.

How it works:
    1. Collects the files matched by the shared and per-host allowlists, refusing
       symlinks and paths outside the source, and skipping hidden files and __pycache__.
    2. Checks every required file is present, refuses MCP servers and apps, and
       checks every manifest reference and hook command points at a bundled file.
    3. Writes the runtime folder and a ZIP with fixed timestamps and file modes,
       claiming the ZIP name by hard link so an existing file is never overwritten.
    4. With --sync, builds every target in a temporary folder, then replaces each
       distributions/<target>.

Usage:
    python3 scripts/pack_plugin.py --sync
    python3 scripts/pack_plugin.py --target {claude,openai} --output DIR

Reads:
    The repository holding this script: plugin.json, the host manifest, and the
    files matched by SHARED and HOST.

Writes:
    --target: DIR/<name>-<target>/ and DIR/<name>-<target>.zip, and both paths to stdout.
    --sync: replaces distributions/claude and distributions/openai, and prints the
    synced path.

Exit codes:
    0: the runtime was built or synced.
    1: the source failed a check or the output already exists, with a traceback.
    2: bad arguments.

Limits:
    Does not validate manifests against host schemas or run host CLIs. --sync
    builds every target before replacing any, but a failure while replacing can
    leave one target updated and the other not.
"""

import argparse
import json
from pathlib import Path
import re
import shutil
import tempfile
import zipfile

SHARED = (
    "LICENSE", "README.md",
    "skills/*/SKILL.md", "skills/*/agents/openai.yaml",
    "skills/*/assets/*.svg", "skills/*/assets/*.png",
    "skills/*/references/**/*", "skills/*/scripts/**/*",
    "agents/*.md", "resources/**/*", "docs/*.md", "docs/assets/*.svg", "docs/assets/*.png",
    "assets/*.svg", "assets/*.png",
    # the backlog wrapper and both hooks, with the requirements they check at run time
    "requirements.json", "bin/backlog", "bin/check-requirements",
    "hooks/hooks.json", "hooks/codex-hooks.json", "hooks/prerequisites.sh", "hooks/*/hook.sh",
)
HOST = {
    "claude": (".claude-plugin/plugin.json", ".claude-plugin/icon.png", "plugin.json"),
    # no portable plugin.json: Codex 0.163.0 reads it in place of .codex-plugin/plugin.json,
    # which alone declares the hooks
    "openai": (".codex-plugin/plugin.json",),
}
REQUIRED_SHARED = ("LICENSE", "README.md", "assets/icon.svg", "docs/claude.md", "docs/codex.md",
                   "requirements.json", "bin/backlog", "bin/check-requirements",
                   "hooks/hooks.json", "hooks/codex-hooks.json", "hooks/prerequisites.sh")
HOOK_SCRIPT = re.compile(r"\$\{(?:CLAUDE_PLUGIN_ROOT|PLUGIN_ROOT)\}/([^\"\\\s]+)")
REQUIRED_PER_SKILL = ("SKILL.md", "agents/openai.yaml", "assets/icon.svg")
DISTRIBUTIONS = "distributions"


def build(root: Path, target: str, output: Path) -> tuple[Path, Path]:
    """Write a new runtime folder and ZIP; refuse unsafe inputs or overwrites."""
    root = root.resolve()
    name = json.loads((root / "plugin.json").read_text())["name"]
    folder = output.resolve() / f"{name}-{target}"
    archive = folder.with_suffix(".zip")
    if any(path.exists() or path.is_symlink() for path in (folder, archive)):
        raise ValueError("Output folder or ZIP already exists")
    if folder == root or root.is_relative_to(folder):
        raise ValueError("Output must not contain the source tree")
    files = set()
    for pattern in SHARED + HOST[target]:
        for path in root.glob(pattern):
            relative = path.relative_to(root)
            if any((root / Path(*relative.parts[:i])).is_symlink()
                   for i in range(1, len(relative.parts) + 1)):
                raise ValueError(f"Symlink in runtime path: {relative}")
            if not path.resolve().is_relative_to(root):
                raise ValueError(f"Path outside source: {relative}")
            hidden = any(part.startswith(".") for part in relative.parts[1:])
            if path.is_file() and not hidden and "__pycache__" not in relative.parts:
                files.add(relative)
    skills = sorted(p.name for p in (root / "skills").glob("*")
                    if p.is_dir() and not p.name.startswith((".", "_")))
    required = REQUIRED_SHARED + (HOST[target][0],) + tuple(
        f"skills/{skill}/{item}" for skill in skills for item in REQUIRED_PER_SKILL)
    if not skills:
        raise ValueError("Missing required file: skills/*/SKILL.md")
    for required_name in required:
        if Path(required_name) not in files:
            raise ValueError(f"Missing required file: {required_name}")
    manifest = json.loads((root / HOST[target][0]).read_text())
    portable = json.loads((root / "plugin.json").read_text())
    openai = portable.get("extensions", {}).get("com.openai", {})
    if portable.get("hooks") or openai.get("hooks"):
        raise ValueError("Declare hooks in the host manifest or hooks/hooks.json, not plugin.json")
    for metadata in (manifest, portable, openai):
        if any(metadata.get(key) for key in ("mcpServers", "mcp", "apps")):
            raise ValueError("This runtime builder does not package MCP or app dependencies")
    references = list(manifest.get("agents", []))
    if "hooks" in manifest:
        if not isinstance(manifest["hooks"], str):
            raise ValueError("Host manifest hooks must name a bundled file")
        references.append(manifest["hooks"])
    for hooks_file in ("hooks/hooks.json", "hooks/codex-hooks.json"):
        references += HOOK_SCRIPT.findall((root / hooks_file).read_text())
    if target == "openai":
        interface = openai.get("interface") or manifest.get("interface", {})
        references += [interface[key] for key in ("composerIcon", "logo") if key in interface]
    elif "icon" in manifest:
        references.append(manifest["icon"])
    for reference in references:
        path = Path(reference)
        if path.is_absolute() or ".." in path.parts or path not in files:
            raise ValueError(f"Unbundled manifest reference: {reference}")
    output.mkdir(parents=True, exist_ok=True)
    folder.mkdir()
    with tempfile.TemporaryDirectory(prefix=".pack-", dir=output) as temporary:
        staged = Path(temporary) / archive.name
        with zipfile.ZipFile(staged, "x", zipfile.ZIP_DEFLATED) as bundle:
            for relative in sorted(files):
                data = (root / relative).read_bytes()
                # Keep the execute bit so bundled scripts still run after install.
                mode = 0o755 if (root / relative).stat().st_mode & 0o111 else 0o644
                destination = folder / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(data)
                destination.chmod(mode)
                info = zipfile.ZipInfo(relative.as_posix(), (1980, 1, 1, 0, 0, 0))
                info.create_system = 3
                info.external_attr = (0o100000 | mode) << 16
                info.compress_type = zipfile.ZIP_DEFLATED
                bundle.writestr(info, data)
        # Linking the finished ZIP claims the final name without following a dangling symlink.
        archive.hardlink_to(staged)
    return folder, archive


def sync(root: Path) -> None:
    """Replace every checked-in distributions/<target> with a fresh build."""
    with tempfile.TemporaryDirectory() as temporary:
        # Build every target before replacing any, so a failure leaves distributions untouched.
        built = {target: build(root, target, Path(temporary))[0] for target in HOST}
        for target, folder in built.items():
            published = root / DISTRIBUTIONS / target
            if published.exists():
                shutil.rmtree(published)
            shutil.copytree(folder, published)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--target", choices=HOST)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--sync", action="store_true",
                        help="Regenerate distributions/claude and distributions/openai")
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1]
    if args.sync:
        sync(source)
        print(f"Synced {source / DISTRIBUTIONS}")
    elif args.target and args.output:
        runtime, bundle = build(source, args.target, args.output)
        print(f"Runtime: {runtime}\nZIP: {bundle}")
    else:
        parser.error("use --sync, or --target with --output")
