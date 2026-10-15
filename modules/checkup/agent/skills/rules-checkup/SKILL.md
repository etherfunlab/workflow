---
name: rules-checkup
description: Use when the user asks to check up, audit or prune their rule files (CLAUDE.md, AGENTS.md, .claude/rules, memory) — 体检一下, "rules checkup" — or after a reminder that Claude Code changed version. Produces a list of candidate deletions and edits; changes nothing until the user approves.
---

# Rules checkup

Rule files are written against the harness of the day. A new harness version can change the system prompt, so a rule that once filled a gap may now repeat the system prompt, fight it, or point at files that no longer exist. This skill lists what to cut. The user decides.

## Read everything first

1. User level: `~/.claude/CLAUDE.md` and every file it imports with `@`.
2. Project: every CLAUDE.md and AGENTS.md from the repo root down to the working directory, and their `@` imports.
3. `.claude/rules/*.md`.
4. The memory index: `~/.claude/projects/<project>/memory/MEMORY.md`, or `.memory/MEMORY.md`.
5. Your own current system prompt and tool descriptions, as you see them in this session.

## Six kinds of candidate

| Kind | Test |
|---|---|
| Redundant | The system prompt already says the same thing, in the same direction |
| Conflicting | The rule pushes against the system prompt or against another rule |
| Stale fact | A path, command, file, flag or name in the rule no longer exists. Check each one with a command (`ls`, `command -v`, `git ls-files`, `--help`); never judge from memory |
| Duplicate | The same rule lives in memory and in a rule file, or in two rule files |
| Hidden brake | A stop-or-ask rule fires only after the agent first classifies the situation ("if this is a side task, ..."). The moment it is needed is the moment the classification gets skipped |
| Incident residue | Dates, PR or issue numbers, line numbers, measured figures, post-mortems or tombstones inside a rule |

## Output

One numbered list grouped by kind. Each item: `file:line`, the rule (quoted, shortened), why it is a candidate, and the proposed change (delete / shorten to "..." / move to ...). End with "Which items should I apply?" and stop.

## Rules

- Change nothing until the user approves. Approval is per item unless the user says "all".
- A checkup only removes, shortens or moves rules. It never adds one.
- After applying approved changes, record the date: set `last_checkup` (YYYY-MM-DD) in `~/.claude/workflow-checkup.json`, creating the file if needed, with `jq`.

## Red flags

- "These are obviously stale, I'll just delete them." → List first, then wait.
- "While I'm here I'll add a rule for X." → Not in a checkup.
- "I remember this path exists." → Run the check.
- "The user is in a hurry, so I'll apply everything." → Hurry is not approval.
