#!/usr/bin/env python3
"""Validate <repo>/.workflow.lock. Prints one error per line; exit 1 on errors."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

KEYS = ("upstream", "commit", "adopted_at", "language", "agent", "modules")
SKILL_PATH = re.compile(r"(^|/)skills/")


def check_lock(repo: Path) -> list[str]:
    p = repo / ".workflow.lock"
    if not p.is_file():
        return [".workflow.lock missing"]
    try:
        lock = json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return [f".workflow.lock is not valid JSON: {e}"]
    errs = [f"missing key: {k}" for k in KEYS if k not in lock]
    if errs:
        return errs
    if not re.fullmatch(r"[0-9a-f]{40}", str(lock["commit"])):
        errs.append("commit must be a 40-char lowercase hex sha")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(lock["adopted_at"])):
        errs.append("adopted_at must be YYYY-MM-DD")
    if lock["language"] not in ("zh", "en"):
        errs.append("language must be zh or en")
    if "skills_scope" in lock and lock["skills_scope"] not in ("project", "user"):
        errs.append("skills_scope must be project or user")
    mods = lock["modules"]
    if not isinstance(mods, dict) or not mods:
        return errs + ["modules must be a non-empty object"]
    has_skills = False
    for name, m in mods.items():
        if isinstance(m, dict) and "commit" in m and not re.fullmatch(r"[0-9a-f]{40}", str(m["commit"])):
            errs.append(f"modules.{name}.commit must be a 40-char lowercase hex sha")
        files = m.get("files") if isinstance(m, dict) else None
        if not isinstance(files, list) or not files:
            errs.append(f"modules.{name}.files must be a non-empty list")
            continue
        for entry in files:
            path, _, heading = str(entry).partition("#")
            has_skills = has_skills or bool(SKILL_PATH.search(path))
            fp = Path(path).expanduser() if path.startswith("~") else repo / path
            if not fp.exists():
                errs.append(f"modules.{name}: {path} does not exist")
                continue
            if heading and not re.search(rf"^#+\s+{re.escape(heading)}\s*$", fp.read_text(encoding="utf-8"), re.M):
                errs.append(f"modules.{name}: heading '{heading}' not found in {path}")
    if has_skills and "skills_scope" not in lock:
        errs.append("skills_scope missing while skills are installed")
    return errs


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: check_lock.py <repo>")
    errs = check_lock(Path(sys.argv[1]))
    for e in errs:
        print(e)
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
