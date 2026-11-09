---
name: rules-checkup
description: Use when the user asks to check up, audit or prune their rule files (CLAUDE.md, AGENTS.md, .claude/rules, memory) — 体检一下, "rules checkup" — or after a reminder that Claude Code changed version. Takes a scope: `global` (only `~/.claude`), `project` (default: everything this session loads) or `repo` (only what the repository commits). Produces a list of candidate deletions and edits; changes nothing until the user approves.
---

# Rules checkup

Rule files are written against the harness of the day. A new harness version can change the system prompt, so a rule that once filled a gap may now repeat the system prompt, fight it, or point at files that no longer exist. This skill lists what to cut. The user decides.

## Three scopes

The scope comes as the skill's argument or in the user's words: `rules-checkup repo`, "rules-checkup:repo", 「仓内体检」. With none given, the scope is `project`.

| Scope | Covers | Whose rules |
|---|---|---|
| `global` | Only `~/.claude` | The user's, in every project they open |
| `project` | Every rule file this session loads, from `~/.claude` down to the working directory, and memory | This user's, working here |
| `repo` | Only what the repository commits, at any depth | Everyone's who clones it |

Recommended order: `global`, then `project`, then `repo`. A checkup can move a rule down a layer, and the next pass then reads that layer in its final form.

Candidates come only from the files in scope. State the scope in the first line of the output.

## Read everything first

In every scope, also read your own current system prompt and tool descriptions, as you see them in this session.

### `global`

1. `~/.claude/CLAUDE.md`, `~/.claude/rules/*.md`, and every file they import with `@`.

A global rule is paid for in every project. One more test applies here: a rule that names a single repository, project or product is a candidate to move down into that project.

### `project`

1. User level: `~/.claude/CLAUDE.md`, `~/.claude/rules/*.md`, and every file they import with `@`.
2. Project: every CLAUDE.md, CLAUDE.local.md and AGENTS.md in the working directory and in each directory above it, and their `@` imports. Do not stop at the repo root; the harness loads the files above it too.
3. The project's `.claude/rules/*.md`.
4. Memory: the index (`~/.claude/projects/<project>/memory/MEMORY.md`, or `.memory/MEMORY.md`) and every memory file it points to.

### `repo`

Work from the repo root (`git rev-parse --show-toplevel`) and read only tracked files (`git ls-files`):

1. Every CLAUDE.md and AGENTS.md at any depth, including directories this session has not loaded, and their `@` imports.
2. `.claude/rules/*.md`.
3. `.memory/`, when the repo tracks one: the index and every memory file it points to.

Do not read `~/.claude`, the directories above the repo, or untracked files: a clone has none of them. Two tests change accordingly:

- Duplicate counts only inside the repo. A rule that repeats one living outside the repo stays, because the repo's rules must hold on their own.
- Stale fact also covers anything that exists only on this machine: an `@` import, path or script outside the repo that a rule depends on.

## Six kinds of candidate

| Kind | Test |
|---|---|
| Redundant | The system prompt already says the same thing, in the same direction |
| Conflicting | The rule pushes against the system prompt or against another rule |
| Stale fact | A path, command, file, flag or name in the rule no longer exists. Check each one with a command (`ls`, `command -v`, `git ls-files`, `--help`); never judge from memory |
| Duplicate | The same rule lives in memory and in a rule file, in two rule files, or twice in one file. For a memory: the repo or its git history already records the same thing |
| Hidden brake | A stop-or-ask rule fires only after the agent first classifies the situation ("if this is a side task, ..."). The moment it is needed is the moment the classification gets skipped |
| Incident residue | Dates, PR or issue numbers, line numbers, measured figures, post-mortems or tombstones inside a rule |

## Output

One numbered list grouped by kind. Each item: `file:line`, the rule (quoted, shortened), why it is a candidate, and the proposed change (delete / shorten to "..." / move to ...). End with "Which items should I apply?" and stop.

## Rules

- Change nothing until the user approves. Approval is per item unless the user says "all".
- A checkup only removes, shortens or moves rules. It never adds one.
- After applying approved changes in the `project` scope, record the date: set `last_checkup` (YYYY-MM-DD) in `~/.claude/workflow-checkup.json`, creating the file if needed, with `jq`.

## Red flags

- "These are obviously stale, I'll just delete them." → List first, then wait.
- "While I'm here I'll add a rule for X." → Not in a checkup.
- "I remember this path exists." → Run the check.
- "The user is in a hurry, so I'll apply everything." → Hurry is not approval.
