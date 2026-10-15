# Project memory (mirror)

This directory mirrors the maintainer's agent memory for this repo, so other agents and developers can read the accumulated project knowledge.

- Start at `MEMORY.md`: one line per memory, each linking to a file with the detail.
- The source of truth is the maintainer's local memory directory; this mirror is regenerated from it.
- Do not edit files here; the next sync overwrites them. `README.md` is kept across syncs.
- Sync is event-driven: a PostToolUse hook refreshes the mirror on each memory write, and the pre-push hook re-syncs and commits it before each push.
