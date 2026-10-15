# Shared by memory-mirror.sh and memory-pre-push.sh.
# Claude Code names a project's memory dir after the repo's absolute path with
# separators replaced by '-'; which characters it keeps varies, so both sides
# are compared after collapsing every run of non-alphanumerics to one '-'.
memory_norm() { printf '%s' "$1" | perl -CSD -pe 's/[^A-Za-z0-9]+/-/g'; }

memory_src_dir() {
  local want1 want2 d n
  want1=$(memory_norm "$1")
  want2=$(memory_norm "$(cd "$1" 2>/dev/null && pwd -P)")   # the repo may be reached through a symlink
  for d in "$HOME"/.claude/projects/*/; do
    [ -d "${d}memory" ] || continue
    n=$(memory_norm "$(basename "$d")")
    if [ "$n" = "$want1" ] || [ "$n" = "$want2" ]; then
      printf '%s\n' "${d}memory"
      return 0
    fi
  done
  return 1
}

memory_sync() {
  mkdir -p "$2"
  rsync -a --delete --exclude='README.md' "$1/" "$2/"
}
