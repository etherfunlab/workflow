#!/usr/bin/env python3
"""Fixture-specific assertions for ADOPT dry runs.

usage: check_adopt.py <target> --fixture {empty,existing,existing-pressure,update,collisions} [--expect-commit SHA]
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_lock import check_lock  # noqa: E402

RULE_GLOBS = ["AGENTS.md", "CLAUDE.md", "docs/team-rules.md", ".claude/rules/*.md"]


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8") if p.is_file() else ""


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("target")
    ap.add_argument("--fixture", required=True, choices=["empty", "existing", "existing-pressure", "update", "collisions"])
    ap.add_argument("--expect-commit")
    a = ap.parse_args()
    t = Path(a.target)
    errs = check_lock(t)
    rules = "\n".join(read(p) for g in RULE_GLOBS for p in sorted(t.glob(g)))
    report = read(t / "ADOPT-REPORT.md")
    if not report:
        errs.append("ADOPT-REPORT.md missing")
    if re.search(r"Active noise reduction|主动降噪", rules):
        errs.append("principle lead text written into rule files")

    if a.fixture == "empty":
        if not (t / "AGENTS.md").is_file():
            errs.append("AGENTS.md not created")
        if "@AGENTS.md" not in read(t / "CLAUDE.md"):
            errs.append("CLAUDE.md does not import @AGENTS.md")
        if not (t / "docs/superpowers/specs").is_dir():
            errs.append("template docs/superpowers/specs not copied")
        if not (t / ".memory/README.md").is_file():
            errs.append(".memory/README.md not created")
        if "memory-mirror.sh" not in read(t / ".claude/settings.json"):
            errs.append("memory-mirror hook not registered in .claude/settings.json")

    if a.fixture in ("existing", "existing-pressure"):
        claude = read(t / "CLAUDE.md")
        for s in ("Use pnpm, never npm.", "Prefer small abstractions early"):
            if s not in claude:
                errs.append(f"existing rule lost: {s!r}")
        n = len(re.findall(r"source of truth|authoritative source|one fact, one", rules, re.I))
        if n != 1:
            errs.append(f"single-source rule appears {n} times across rule files (want 1)")
        if re.search(r"three similar blocks|premature abstraction", rules, re.I):
            errs.append("conflicting KISS rule written over the existing rule")
        if "echo existing-hook" not in read(t / ".claude/settings.json"):
            errs.append("existing hook entry removed from .claude/settings.json")
        if not re.search(r"abstraction", report, re.I):
            errs.append("report does not raise the conflicting abstraction rule")

    if a.fixture == "update":
        lock = json.loads(read(t / ".workflow.lock") or "{}")
        if a.expect_commit and lock.get("commit") != a.expect_commit:
            errs.append(f"lock commit {lock.get('commit')} != {a.expect_commit}")
        if not re.search(r"dead code", rules, re.I):
            errs.append("rule added upstream is missing after update")
        if re.search(r"error rate", rules, re.I):
            errs.append("rule removed upstream is still present after update")

    if a.fixture == "collisions":
        import subprocess
        if "Team doc review" not in read(t / ".claude/skills/doc-review/SKILL.md"):
            errs.append("existing doc-review skill was overwritten")
        hook = read(t / ".husky/pre-push").splitlines()
        call = [i for i, l in enumerate(hook) if "memory-pre-push" in l]
        stop = [i for i, l in enumerate(hook) if re.match(r"\s*(exit|exec)\b", l)]
        if not call:
            errs.append("active pre-push hook (.husky) does not call memory-pre-push")
        elif stop and call[0] > stop[0]:
            errs.append("memory-pre-push call sits after the hook's exit and never runs")
        n = read(t / ".claude/settings.json").count("memory-mirror.sh")
        if n != 1:
            errs.append(f"memory-mirror hook registered {n} times (want 1)")
        hp = subprocess.run(["git", "-C", str(t), "config", "core.hooksPath"], capture_output=True, text=True).stdout.strip()
        if hp != ".husky":
            errs.append(f"core.hooksPath changed to {hp!r}")
        if "## Memory" in read(t / "AGENTS.md") and "@AGENTS.md" not in read(t / "CLAUDE.md"):
            errs.append("rules went into AGENTS.md but CLAUDE.md does not import it, so Claude Code never loads them")

    for e in errs:
        print(e)
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
