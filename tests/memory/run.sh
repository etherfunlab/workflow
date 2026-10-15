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
printf 'wip\n' > "$repo/staged.txt"; git -C "$repo" add staged.txt
printf 'fact c\n' > "$mem/c.md"
t_exit "pre-push with other staged work still stops" 1 bash -c "cd '$repo' && .githooks/memory-pre-push.sh"
t_no_out "mirror commit leaves other staged files out" "staged\.txt" git -C "$repo" show --name-only --format= HEAD
t_out "other staged file is still staged" "^A\s+staged\.txt" git -C "$repo" status --porcelain


# two repos whose paths differ only in punctuation must not share a mirror
repo2="$tmp/My_Repo 项目"; mkdir -p "$repo2/.githooks"; git -C "$repo2" init -q; cp "$hooks"/* "$repo2/.githooks/"
enc2=$(printf '%s' "$repo2" | perl -CSD -pe 's/[^A-Za-z0-9_]/-/g'); mem2="$HOME/.claude/projects/$enc2/memory"; mkdir -p "$mem2"
printf 'fact z\n' > "$mem2/z.md"
printf '{"tool_input":{"file_path":"%s"}}' "$mem2/z.md" | CLAUDE_PROJECT_DIR="$repo2" "$repo2/.githooks/memory-mirror.sh"
t_true "underscore repo syncs its own memory" test -f "$repo2/.memory/z.md"
t_true "underscore repo does not get the other repo's memory" test ! -e "$repo2/.memory/a.md"
printf 'fact e\n' > "$mem/e.md"; hook "$repo" "$mem/e.md"
t_true "space repo still syncs its own memory" test -f "$repo/.memory/e.md"
t_true "space repo does not get the underscore repo's memory" test ! -e "$repo/.memory/z.md"

# a .memory symlink is never synced through
repo3="$tmp/linked"; mkdir -p "$repo3" "$tmp/outside"; git -C "$repo3" init -q; printf 'keep\n' > "$tmp/outside/keep.txt"
ln -s "$tmp/outside" "$repo3/.memory"
enc3=$(printf '%s' "$repo3" | perl -CSD -pe 's/[^A-Za-z0-9_]/-/g'); mem3="$HOME/.claude/projects/$enc3/memory"; mkdir -p "$mem3"; printf 'm\n' > "$mem3/m.md"
printf '{"tool_input":{"file_path":"%s"}}' "$mem3/m.md" | CLAUDE_PROJECT_DIR="$repo3" "$repo/.githooks/memory-mirror.sh" 2>/dev/null
t_true "symlinked .memory: files outside are untouched" test -f "$tmp/outside/keep.txt"

# a failed mirror commit does not block every push
printf '#!/bin/sh\nexit 1\n' > "$repo/.git/hooks/pre-commit"; chmod +x "$repo/.git/hooks/pre-commit"
git -C "$repo" commit -qm "wip" >/dev/null 2>&1 || true
git -C "$repo" reset -q
printf 'fact d\n' > "$mem/d.md"
t_exit "failed mirror commit lets the push continue" 0 bash -c "cd '$repo' && .githooks/memory-pre-push.sh"
t_out "failed mirror commit is reported" "could not commit" bash -c "cd '$repo' && .githooks/memory-pre-push.sh"
rm -f "$repo/.git/hooks/pre-commit"

t_done memory
