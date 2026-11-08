# Adapted from google/elephant-goldfish-model tests/unit/test_frontmatter.py (Apache-2.0); modified.
"""Skills and personas carry the frontmatter every host needs to discover them.

Responsibilities: check each SKILL.md names its folder, has a description of 1 to
1024 characters and a boolean `disable-model-invocation` when set; check each
agents/*.md persona names its file stem, has a description, and has a unique name.

Invariants: reads only.
"""

from pathlib import Path

from helpers import ROOT, frontmatter


def test_skills_have_valid_frontmatter(discovered_skills: list[Path]) -> None:
    for skill in discovered_skills:
        meta = frontmatter(skill / "SKILL.md")
        assert meta.get("name") == skill.name, f"{skill}: name must equal folder name"
        assert isinstance(meta.get("description"), str) and meta["description"].strip()
        assert len(meta["description"]) <= 1024, f"{skill}: description over 1024 chars"
        if "disable-model-invocation" in meta:
            assert isinstance(meta["disable-model-invocation"], bool)


def test_personas_have_unique_names() -> None:
    names = []
    for persona in sorted((ROOT / "agents").glob("*.md")):
        meta = frontmatter(persona)
        assert meta.get("name") == persona.stem, f"{persona}: name must equal file stem"
        assert isinstance(meta.get("description"), str) and meta["description"].strip()
        names.append(meta["name"])
    assert len(names) == len(set(names)), "Ambiguous persona name"
