# Adapted from google/elephant-goldfish-model tests/unit/test_skill_load_limits.py (Apache-2.0).
"""Keep skill bodies within Antigravity's load limit.

Responsibilities: check each SKILL.md body after its frontmatter is at most 24,000
UTF-8 bytes.

Invariants: reads only.
"""

from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]


@pytest.mark.parametrize("skill", sorted((ROOT / "skills").glob("*/SKILL.md")),
                         ids=lambda skill: skill.parent.name)
def test_skill_body_fits_antigravity(skill: Path) -> None:
    body = skill.read_text(encoding="utf-8").split("---", 2)[2].strip()
    size = len(body.encode("utf-8"))
    assert size <= 24_000, (
        f"{skill.parent.name}: {size} bytes exceeds Antigravity's 24,000-byte "
        "skill body limit; move details into an explicitly read reference")
