#!/usr/bin/env bash
# Example PostToolUse(Write|Edit) hook: copy rule files that live outside git
# into a git repository, so they have history. Not installed by ADOPT; copy it,
# edit the mapping, and register it yourself. Copy only: the commit belongs to
# the task that made the change.
set -uo pipefail
f=$(jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -z "$f" ] && exit 0
backup_repo="$HOME/path/to/rules-backup"   # edit
case "$f" in
  "$HOME/.claude/CLAUDE.md") cp "$f" "$backup_repo/claude-user.md" ;;
  "$HOME/work/CLAUDE.md")    cp "$f" "$backup_repo/claude-work.md" ;;   # edit
esac
exit 0
