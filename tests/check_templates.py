#!/usr/bin/env python3
"""Check templates/*/ against the repo layout and resolve every FILE.md §N cross-reference."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

BASE = {"AGENTS.md", "CLAUDE.md"}
REF = re.compile(r"(?:`?([A-Z]+\.md)`?\s+)?§(\d+(?:\.\d+)*)")
GROUPED = re.compile(r"[A-Z]+\.md`?\s+§[\d.]+\s*(?:,|and|or|/)\s*§")
PH = re.compile(r"\{\{[A-Z0-9_]+\}\}")


def sections(text: str) -> list[str]:
    return re.findall(r"^#{2,}\s+(\d+(?:\.\d+)*)[.\s]", text, re.M)


def check(root: Path) -> list[str]:
    errs: list[str] = []
    tdir = root / "templates"
    if not tdir.is_dir():
        return ["templates/ missing"]
    base = tdir / "base"
    for f in sorted(BASE):
        if not (base / f).is_file():
            errs.append(f"templates/base: {f} missing")
    if "@AGENTS.md" not in ((base / "CLAUDE.md").read_text(encoding="utf-8") if (base / "CLAUDE.md").is_file() else ""):
        errs.append("templates/base: CLAUDE.md does not import @AGENTS.md")
    for d in sorted(p for p in tdir.iterdir() if p.is_dir()):
        rel = d.relative_to(root)
        if d.name != "base":
            zh, en = d / "README.zh.md", d / "README.en.md"
            if not (zh.is_file() and en.is_file()):
                errs.append(f"{rel}: README.zh.md and README.en.md required")
            else:
                hz = len(re.findall(r"^## ", zh.read_text(encoding="utf-8"), re.M))
                he = len(re.findall(r"^## ", en.read_text(encoding="utf-8"), re.M))
                if hz != he:
                    errs.append(f"{rel}: README heading count zh={hz} en={he}")
        if not any(p.is_file() and not p.name.startswith("README") for p in d.rglob("*")):
            errs.append(f"{rel}: no files to install")
        docs = {p.name: p.read_text(encoding="utf-8") for p in d.glob("*.md") if not p.name.startswith("README")}
        for name, text in docs.items():
            if GROUPED.search(text):
                errs.append(f"{rel}/{name}: name the file on each cross-file reference; a bare § means {name}")
            nums = sections(text)
            dup = sorted({n for n in nums if nums.count(n) > 1})
            if dup:
                errs.append(f"{rel}/{name}: section numbers used twice: {dup}")
            if PH.search(text):
                errs.append(f"{rel}/{name}: {{{{PLACEHOLDER}}}} found; template blanks are written TODO:")
            for target, num in REF.findall(text):
                target = target or name
                if target not in docs:
                    errs.append(f"{rel}/{name}: §{num} points at {target}, which this template lacks")
                elif num not in sections(docs[target]):
                    errs.append(f"{rel}/{name}: {target} §{num} not found")
    return errs


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent))
    a = ap.parse_args()
    errs = check(Path(a.root))
    for e in errs:
        print(e)
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
