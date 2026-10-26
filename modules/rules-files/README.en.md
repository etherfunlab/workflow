# rules-files

From the principle: One source of truth.

## What it is

How to write the files an agent loads as instructions: CLAUDE.md, AGENTS.md, `.claude/rules/*.md`. Once installed, your agent reads these rules whenever it edits one of those files.

## Why

Rule files enter the context in full every session, and every word in them competes with the real task for attention. Incident details, stale tombstones and the same rule written in two places are all noise. When each rule has one authoritative place, the agent knows which copy to trust and where to look.

## The rules

1. **Write the rule, not the incident.** Keep the rule and compress its reason to one sentence. No dates, PR or issue numbers, line numbers, measured figures or post-mortems; evidence goes in the commit message.
2. **Delete cleanly.** No tombstones such as "X is deprecated, don't use it". The one exception: an implementation that was really added back after removal keeps one line, "Do not re-add X: reason Y".
3. **Two layers.** Cross-repo posture goes in the upper-level file; rules for one repo stay in that repo; rules that matter only for certain paths go in `.claude/rules/` with a `paths:` list and load only when those files are touched.
4. **AGENTS.md starts with an index.** The index says where each rule lives, in reading order. Rules for the whole repo follow it as sections; rules for certain paths go where rule 3 puts them and get a row in the index. CLAUDE.md is one line: `@AGENTS.md`.
5. **"Final, do not change" is for constraints the user stated verbatim.** A rule inferred from repeated corrections is written as "the current implementation is X because Y". Being corrected on the same point again and again means the agent misunderstood; it does not mean the conclusion should be frozen.
6. **A memory that became a rule leaves memory.** Keep one copy.
7. **One authoritative copy per rule file.** When the file lives outside git, a hook mirrors it into a git repository for history; never edit the mirror.

The full rules are in [`agent/rules/rules-files.md`](agent/rules/rules-files.md).

## What gets installed

- Claude Code: `.claude/rules/rules-files.md` with `paths` `**/CLAUDE.md`, `**/AGENTS.md`, `.claude/rules/**`, loaded only when a rule file is edited.
- Other agents: a section in AGENTS.md, "When editing `**/CLAUDE.md`, `**/AGENTS.md`, `.claude/rules/**`".
- The example script for rule 7, [`agent/scripts/mirror-rules-backup.example.sh`](agent/scripts/mirror-rules-backup.example.sh), is not installed by ADOPT. You need it only when your rule files live outside git (the user-level `~/.claude/CLAUDE.md`, for example): copy it, edit the path mapping, and register it as a PostToolUse hook yourself.

## Dependencies

None. The example script uses `jq`.
