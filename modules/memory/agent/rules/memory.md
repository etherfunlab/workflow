# Memory

## Claude Code

- The auto-memory under `~/.claude/projects/<project>/memory/` is the source of truth. `MEMORY.md` is its index: one line per memory, loaded every session.
- `.memory/` in this repo is a read-only mirror, committed so other agents and teammates can read it without the maintainer's machine. Never edit `.memory/`; edit the memory and let the hooks sync it.
- When the PostToolUse hook is installed, it syncs `.memory/` whenever a memory file is written. The pre-push hook syncs and commits it before each push; when it commits, the push stops once and must be run again.

## Other agents

- There is no auto-memory. `.memory/` is this repo's agent memory: `.memory/MEMORY.md` is the index, one fact per file, one line per fact in the index. Edit it directly and commit it with the task that changed it.
