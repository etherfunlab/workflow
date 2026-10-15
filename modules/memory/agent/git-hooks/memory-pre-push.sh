#!/usr/bin/env bash
# Re-sync .memory/ and commit any drift. git fixed the refs to push before this
# hook ran, so an in-hook commit is not part of this push: stop and ask for a re-run.
# When the mirror cannot be synced or committed, say so and let the push go on.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/memory-lib.sh"
repo="$(git rev-parse --show-toplevel)"
src=$(memory_src_dir "$repo") || exit 0
memory_sync "$src" "$repo/.memory" || exit 0
if [ -n "$(git -C "$repo" status --porcelain -- .memory)" ]; then
  if git -C "$repo" add .memory && git -C "$repo" commit -q -m "chore: sync .memory mirror" -- .memory; then   # pathspec: leave other staged work out
    echo "[pre-push] committed the .memory mirror; run git push again to include it."
    exit 1
  fi
  echo "[pre-push] could not commit the .memory mirror; pushing without it."
fi
exit 0
