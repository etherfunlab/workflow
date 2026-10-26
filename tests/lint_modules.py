#!/usr/bin/env python3
"""Lint modules/*/module.json and skills/*/module.json against the repo layout."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REQUIRED = {"name", "principles", "role", "depends_on", "rules", "skills", "hooks",
            "git_hooks", "requires", "upstream_skills", "placeholders"}
ROLES = {"tool", "rules", "skills", "extra"}
ALLOWED_PRINCIPLES = {2, 3, 4, 5, 6, 7, 8, 10}
PH = re.compile(r"\{\{([A-Z0-9_]+)\}\}")


def frontmatter(p: Path) -> dict[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n", p.read_text(encoding="utf-8"), re.S)
    out: dict[str, str] = {}
    if m:
        for line in m.group(1).splitlines():
            if ":" in line and not line.startswith(" "):
                k, v = line.split(":", 1)
                out[k.strip()] = v.strip()
    return out


def lint(root: Path, require_docs: bool) -> list[str]:
    errs: list[str] = []
    manifests = sorted(root.glob("modules/*/module.json")) + sorted(root.glob("skills/*/module.json"))
    data: dict[Path, dict] = {}
    for mj in manifests:
        try:
            data[mj.parent] = json.loads(mj.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errs.append(f"{mj.relative_to(root)}: invalid JSON: {e}")
    names = {m.get("name") for m in data.values()}
    for d, m in data.items():
        rel = d.relative_to(root)
        missing = REQUIRED - m.keys()
        if missing:
            errs.append(f"{rel}: missing keys {sorted(missing)}")
            continue
        if m["name"] != d.name:
            errs.append(f"{rel}: name {m['name']!r} != directory {d.name!r}")
        if m["role"] not in ROLES:
            errs.append(f"{rel}: role {m['role']!r} not in {sorted(ROLES)}")
        if d.parent.name == "skills":
            if m["principles"] != [] or m["role"] != "extra":
                errs.append(f"{rel}: supplementary skills have principles [] and role 'extra'")
        elif not m["principles"] or not set(m["principles"]) <= ALLOWED_PRINCIPLES:
            errs.append(f"{rel}: principles must be a non-empty subset of {sorted(ALLOWED_PRINCIPLES)}")
        for dep in m["depends_on"]:
            if dep not in names:
                errs.append(f"{rel}: depends_on unknown module {dep!r}")
        files = list(m["rules"]) + list(m["git_hooks"]) + [h["file"] for h in m["hooks"]]
        files += [c["from"] for c in m.get("copies", [])]
        files += [f"agent/skills/{s}/SKILL.md" for s in m["skills"]]
        for f in files:
            if not (d / f).is_file():
                errs.append(f"{rel}: listed file missing: {f}")
        for s in m["skills"]:
            p = d / "agent" / "skills" / s / "SKILL.md"
            if p.is_file():
                fm = frontmatter(p)
                if fm.get("name") != s:
                    errs.append(f"{rel}: {s}/SKILL.md name {fm.get('name')!r} != {s!r}")
                if not fm.get("description", "").startswith("Use when"):
                    errs.append(f"{rel}: {s}/SKILL.md description must start with 'Use when'")
        used: set[str] = set()
        for p in (d / "agent").rglob("*"):
            if p.is_file():
                used |= set(PH.findall(p.read_text(encoding="utf-8", errors="ignore")))
        declared = set(m["placeholders"].keys())
        if used - declared:
            errs.append(f"{rel}: undeclared placeholders {sorted(used - declared)}")
        if declared - used:
            errs.append(f"{rel}: unused placeholders {sorted(declared - used)}")
        if require_docs:
            zh, en = d / "README.zh.md", d / "README.en.md"
            if not (zh.is_file() and en.is_file()):
                errs.append(f"{rel}: README.zh.md and README.en.md required")
            else:
                hz = len(re.findall(r"^## ", zh.read_text(encoding="utf-8"), re.M))
                he = len(re.findall(r"^## ", en.read_text(encoding="utf-8"), re.M))
                if hz != he:
                    errs.append(f"{rel}: README heading count zh={hz} en={he}")
    return errs


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent))
    ap.add_argument("--require-docs", action="store_true")
    a = ap.parse_args()
    errs = lint(Path(a.root), a.require_docs)
    for e in errs:
        print(e)
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
