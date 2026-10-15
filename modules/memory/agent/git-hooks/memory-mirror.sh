#!/usr/bin/env bash
# Claude Code PostToolUse(Write|Edit): mirror the project's auto-memory into
# <repo>/.memory/. The auto-memory is the source of truth; .memory/ is a copy.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/memory-lib.sh"
f=$(jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -z "$f" ] && exit 0
repo="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -z "$repo" ] && exit 0
src=$(memory_src_dir "$repo") || exit 0
case "$f" in
  "$src"/*) memory_sync "$src" "$repo/.memory" ;;
esac
exit 0
