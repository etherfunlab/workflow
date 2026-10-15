---
paths:
  - "**/CLAUDE.md"
  - "**/AGENTS.md"
  - ".claude/rules/**"
---

# Writing rule files

Applies whenever you edit a file that is loaded as instructions: CLAUDE.md, AGENTS.md, `.claude/rules/*.md`, or similar.

1. **Write the rule, not the incident.** Keep the rule and compress its reason to one sentence. No dates, PR or issue numbers, line numbers, measured figures or post-mortems; evidence goes in the commit message.
2. **Delete cleanly.** No tombstones such as "X is deprecated, don't use it". The only exception: an implementation that was actually added back after removal keeps one line, "Do not re-add X: reason Y".
3. **Two layers.** Cross-repo posture goes in the upper-level file. Rules for one repo stay in that repo. Rules that matter only for certain paths go in `.claude/rules/` with a `paths:` list, so they load only when those files are touched.
4. **AGENTS.md is an index, not a rulebook.** It says where each rule lives, in reading order. CLAUDE.md is one line: `@AGENTS.md`.
5. **"Final, do not change" is reserved for constraints the user stated verbatim.** A rule inferred from being corrected several times is written as "the current implementation is X because Y". Repeated corrections on one point mean the agent misunderstood; they do not mean the conclusion should be frozen.
6. **A memory that has become a rule is deleted from memory.** Keep one copy.
7. **One authoritative copy per rule file.** When the file is not in git, a hook mirrors it into a git repository for history. Never edit the mirror.
