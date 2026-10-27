#!/usr/bin/env bash
# Read-only scan of Claude Code worktrees and Rust target/ dirs under a root.
# Prints a REMOVE/KEEP verdict per worktree and the pinned-toolchain cargo to
# clean each target/ with. Deletes nothing.
set -u
ROOT="${1:?usage: scan.sh <root>}"
ARCH="$(uname -m | sed 's/^arm64$/aarch64/')-apple-darwin"
CACHE_SIG="Signature: 8a477f597d28d172789f06886806bc55"

df -h /System/Volumes/Data | awk 'NR==2 {print "Data volume: " $3 " used, " $4 " free (" $5 ")"}'

# "<command>\t<cwd>" for every process we can see; used to spot dirs in use.
# lsof prints physical paths, so dirs compared against it go through pwd -P.
PROCS="$(lsof -d cwd -Fcn 2>/dev/null | awk '/^c/ {c = substr($0, 2)} /^n/ {print c "\t" substr($0, 2)}')"
if [ -z "$PROCS" ]; then
  echo "lsof listed no process cwds; cannot tell which dirs are in use" >&2
  exit 1
fi

in_use() {  # $1 = physical dir; prints the commands whose cwd is inside it
  printf '%s\n' "$PROCS" | awk -F'\t' -v d="$1" '$2 == d || index($2, d "/") == 1 {print $1}' | sort -u | tr '\n' ' '
}

uncommitted() {  # $1 = worktree; prints status lines that are real work, fails when git status does
  local s l
  s="$(git -C "$1" status --porcelain --untracked-files=normal 2>/dev/null)" || return 1
  printf '%s\n' "$s" | while IFS= read -r l; do
    [ -n "$l" ] || continue
    # Untracked dirs tagged per the Cache Directory Tagging spec are tool caches, not work.
    case "$l" in
      '?? '*/) [ "$(head -c ${#CACHE_SIG} "$1/${l#?? }CACHEDIR.TAG" 2>/dev/null)" = "$CACHE_SIG" ] && continue ;;
    esac
    echo "$l"
  done
}

cargo_for() {  # $1 = crate root; prints the cargo of the toolchain pinned there or in a parent
  local d="$1" ch=""
  while :; do
    if [ -f "$d/rust-toolchain.toml" ]; then
      ch="$(sed -n 's/^[[:space:]]*channel[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$d/rust-toolchain.toml" | head -1)"
      break
    elif [ -f "$d/rust-toolchain" ]; then
      ch="$(head -1 "$d/rust-toolchain" | tr -d '[:space:]')"
      break
    fi
    [ "$d" = / ] && break
    d="$(dirname "$d")"
  done
  local bin="$HOME/.rustup/toolchains/${ch:-stable}-$ARCH/bin/cargo"
  [ -x "$bin" ] || bin="$HOME/.rustup/toolchains/stable-$ARCH/bin/cargo"
  echo "$bin"
}

echo
echo "== Claude worktrees =="
find "$ROOT" -maxdepth 5 \( -name node_modules -o -name target \) -prune -o \
  -type d -path '*/.claude/worktrees' -print -prune 2>/dev/null |
while IFS= read -r wdir; do
  for w in "$wdir"/*/; do
    [ -d "$w" ] || continue
    w="$(cd "$w" && pwd -P)" || continue
    main="$(dirname "$(git -C "$w" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)")"
    size="$(du -sh "$w" 2>/dev/null | cut -f1)"
    head="$(git -C "$w" rev-parse HEAD 2>/dev/null)"
    branch="$(git -C "$w" symbolic-ref --short -q HEAD)"
    if changes="$(uncommitted "$w")"; then dirty="$(printf '%s' "$changes" | grep -c .)"; else dirty=""; fi
    users="$(in_use "$w")"

    if [ -n "$branch" ]; then
      pr="$(cd "$main" && gh pr list --state all --head "$branch" \
        --json number,state,headRefOid --jq '.[0] // empty | "#\(.number) \(.state) \(.headRefOid)"' 2>/dev/null)"
      read -r pr_num pr_state pr_head <<<"${pr:-none none none}"
      ref="branch=$branch pr=$pr_num $pr_state"
      if [ "$pr_state" = MERGED ] && [ "$pr_head" = "$head" ]; then safe=1
      elif [ "$pr_state" = MERGED ]; then safe=0; why="HEAD has commits after the merged PR head"
      else safe=0; why="PR is $pr_state"
      fi
    else
      remote="$(git -C "$w" branch -r --contains HEAD 2>/dev/null | grep -v -- '->' | head -1 | tr -d ' ')"
      ref="detached ${head:0:8} on=${remote:-no-remote}"
      if [ -n "$remote" ]; then safe=1; else safe=0; why="detached HEAD is on no remote branch"; fi
    fi
    if [ -z "$dirty" ]; then safe=0; why="git status failed"
    elif [ "$dirty" != 0 ]; then safe=0; why="$dirty uncommitted change(s)"
    fi
    [ -n "$users" ] && { safe=0; why="in use by: $users"; }

    if [ "$safe" = 1 ]; then verdict=REMOVE; else verdict="KEEP($why)"; fi
    printf '%-6s %-40s %s\n         %s\n         main=%s\n' "$size" "$verdict" "$ref" "$w" "$main"
  done
done

echo
echo "== Rust target/ dirs outside worktrees =="
find "$ROOT" \( -name node_modules -o -path '*/.claude/worktrees' \) -prune -o \
  -type d -name target -prune -print 2>/dev/null |
while IFS= read -r t; do
  root="$(cd "$(dirname "$t")" && pwd -P)" || continue
  [ -f "$root/Cargo.toml" ] || continue
  size="$(du -sh "$t" 2>/dev/null | cut -f1)"
  busy="$(in_use "$root" | tr ' ' '\n' | grep -E '^(cargo|rustc)$' | tr '\n' ' ')"
  printf '%-6s %s%s\n         cargo=%s\n' "$size" "$root" "${busy:+  BUSY($busy)}" "$(cargo_for "$root")"
done
