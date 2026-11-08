"""Every skill has behavioral eval cases that `claude plugin eval` can run.

Responsibilities: check each skill has evals/<skill>/<case>/prompt.md with an integer
`max_turns` and at least one grader with a `type`, and that every folder in evals/
other than results/ names a skill.

Invariants: reads only.
"""

from pathlib import Path

from helpers import ROOT, frontmatter


def test_each_skill_has_eval_cases(discovered_skills: list[Path]) -> None:
    for skill in discovered_skills:
        cases = sorted((ROOT / "evals" / skill.name).glob("*/prompt.md"))
        assert cases, f"Add evals/{skill.name}/<case>/prompt.md for {skill.name}"
        for prompt in cases:
            assert isinstance(frontmatter(prompt).get("max_turns"), int), prompt
            graders = sorted((prompt.parent / "graders").glob("*.md"))
            assert graders, f"{prompt.parent}: add graders/*.md"
            for grader in graders:
                assert frontmatter(grader).get("type"), f"{grader}: grader needs a type"


def test_no_orphan_eval_folders(discovered_skills: list[Path]) -> None:
    names = {skill.name for skill in discovered_skills}
    for folder in (ROOT / "evals").iterdir():
        if folder.is_dir() and folder.name != "results":
            assert folder.name in names, f"evals/{folder.name} matches no skill"
