# memory

From the principle: Repo management.

## What it is

Mirrors the agent's memory into the repository. Claude Code keeps its auto-memory on your machine under `~/.claude/projects/<project>/memory/`; this module's two hooks sync it into `.memory/` in the repo, committed with everything else.

## Why

When memory lives only on the maintainer's machine, other agents and teammates cannot read the conventions and judgments the project has accumulated. A Git repository already is a memory and context store: a `.memory/` directory at the root plus the sync hooks is enough, with no separate memory system.

## The rules

- **The local auto-memory is the source of truth.** `MEMORY.md` is its index, one line per memory, loaded every session.
- **`.memory/` is a read-only mirror.** Do not edit files in `.memory/`; the next sync overwrites them. Edit the memory itself and let the hooks sync it. `.memory/README.md` describes the mirror and survives syncs.
- **Two hooks:**
  - PostToolUse hook (optional, Claude Code only): when the agent writes a memory file with Write or Edit, the whole memory directory is synced into `.memory/`.
  - git pre-push hook: syncs once more before a push; when something changed, it commits `chore: sync .memory mirror` on its own (only `.memory/`; anything else you staged stays staged) and stops the push. That is expected: git fixed the commits to push before the hook ran, so the new commit needs a second push.
- **Other agents have no auto-memory.** For them `.memory/` is the repo's agent memory: `.memory/MEMORY.md` is the index, one fact per file and one line per fact in the index, edited directly and committed with the task.

The full rules are in [`agent/rules/memory.md`](agent/rules/memory.md).

## What gets installed

- A `## Memory` section in the main rule file (AGENTS.md, or CLAUDE.md when there is no AGENTS.md), keeping only the half that matches your agent.
- `.memory/README.md`, explaining that the directory is a mirror.
- `memory-lib.sh`, `memory-pre-push.sh` and `pre-push` under `.githooks/`. When you have no pre-push hook and `core.hooksPath` is unset, ADOPT sets it to `.githooks`; when you already have a pre-push hook, ADOPT skips `pre-push` and adds one line to your hook instead.
- Optional (Claude Code only): `.githooks/memory-mirror.sh`, registered as a PostToolUse hook in `.claude/settings.json` after any hooks you already have.

Claude Code names the memory directory after the repository's absolute path with separators replaced by `-`. When comparing, the hooks collapse every run of characters outside ASCII letters and digits (spaces and CJK included) to a single `-`, on both the directory name and the repository path, and also try the repository's physical path from `pwd -P`. Paths with spaces, CJK characters or symlinks therefore still find their directory.

## Dependencies

`rsync`, `jq`, `perl`.
