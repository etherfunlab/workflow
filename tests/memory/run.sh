#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
hooks="$root/modules/memory/agent/git-hooks"
tmp=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$tmp"' EXIT   # physical path: on macOS /var is a symlink and git reports /private/var
export HOME="$tmp/home"; mkdir -p "$HOME"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

repo="$tmp/My Repo 项目"
mkdir -p "$repo/.githooks" "$repo/.memory"
git -C "$repo" init -q
cp "$hooks"/* "$repo/.githooks/"; chmod +x "$repo/.githooks/"*
printf 'mirror readme\n' > "$repo/.memory/README.md"
enc=$(printf '%s' "$repo" | perl -CSD -pe 's/[^A-Za-z0-9_]/-/g')   # one Claude Code-style encoding
mem="$HOME/.claude/projects/$enc/memory"; mkdir -p "$mem"
printf '# Memory\n- [a](a.md) — fact a\n' > "$mem/MEMORY.md"
printf 'fact a\n' > "$mem/a.md"

hook() { printf '{"tool_input":{"file_path":"%s"}}' "$2" | CLAUDE_PROJECT_DIR="$1" "$repo/.githooks/memory-mirror.sh"; }

hook "$repo" "$repo/src/x.ts"
t_true "write outside memory is ignored" test ! -e "$repo/.memory/a.md"
hook "$repo" "$mem/a.md"
t_true "memory write syncs (path with space and CJK)" test -f "$repo/.memory/a.md"
t_true "MEMORY.md synced" test -f "$repo/.memory/MEMORY.md"
t_out "mirror README preserved" "mirror readme" cat "$repo/.memory/README.md"
rm "$mem/a.md"; hook "$repo" "$mem/MEMORY.md"
t_true "deleted memory is pruned" test ! -e "$repo/.memory/a.md"
t_exit "garbage stdin still exits 0" 0 bash -c "echo notjson | CLAUDE_PROJECT_DIR='$repo' '$repo/.githooks/memory-mirror.sh'"

other="$tmp/other"; mkdir -p "$other"; git -C "$other" init -q
hook "$other" "$mem/MEMORY.md"
t_true "repo without memory dir gets no .memory" test ! -e "$other/.memory"

git -C "$repo" add -A && git -C "$repo" commit -qm init
printf 'fact b\n' > "$mem/b.md"
t_exit "pre-push commits drift and stops the push" 1 bash -c "cd '$repo' && .githooks/memory-pre-push.sh"
t_out "drift commit message" "chore: sync .memory mirror" git -C "$repo" log -1 --format=%s
t_exit "pre-push without drift passes" 0 bash -c "cd '$repo' && .githooks/pre-push"

t_done memory
