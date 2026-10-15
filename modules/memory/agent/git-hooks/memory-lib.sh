# Shared by memory-mirror.sh and memory-pre-push.sh.
# Claude Code names a project's memory dir after the repo's absolute path with
# separators replaced by '-'. An exact match on that encoding wins. Only when
# none exists are names compared with every run of non-alphanumerics collapsed
# to one '-', and only a single match is accepted, so two repos whose paths
# differ only in punctuation (a_b, a-b) never share a mirror.
memory_norm() { printf '%s' "$1" | perl -CSD -pe 's/[^A-Za-z0-9]+/-/g'; }

memory_src_dir() {
  [ -n "$1" ] || return 1
  local phys p e d n want1 want2 hits=()
  phys=$(cd "$1" 2>/dev/null && pwd -P) || phys=""
  for p in "$1" "$phys"; do
    [ -n "$p" ] || continue
    for e in "$(printf '%s' "$p" | perl -CSD -pe 's/[^A-Za-z0-9_-]/-/g')" \
             "$(printf '%s' "$p" | perl -CSD -pe 's/[^A-Za-z0-9]/-/g')"; do
      if [ -d "$HOME/.claude/projects/$e/memory" ]; then
        printf '%s\n' "$HOME/.claude/projects/$e/memory"
        return 0
      fi
    done
  done
  want1=$(memory_norm "$1")
  want2=$(memory_norm "$phys")
  for d in "$HOME"/.claude/projects/*/; do
    [ -d "${d}memory" ] || continue
    n=$(memory_norm "$(basename "$d")")
    if [ "$n" = "$want1" ] || { [ -n "$phys" ] && [ "$n" = "$want2" ]; }; then
      hits+=("${d}memory")
    fi
  done
  [ "${#hits[@]}" -eq 1 ] || return 1
  printf '%s\n' "${hits[0]}"
}

memory_sync() {
  if [ -L "$2" ]; then
    echo "[memory] $2 is a symlink; not syncing through it" >&2
    return 1
  fi
  mkdir -p "$2"
  rsync -a --delete --exclude='README.md' "$1/" "$2/"
}
