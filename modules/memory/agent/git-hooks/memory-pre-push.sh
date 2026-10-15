#!/usr/bin/env bash
# Re-sync .memory/ and commit any drift. git fixed the refs to push before this
# hook ran, so an in-hook commit is not part of this push: stop and ask for a re-run.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/memory-lib.sh"
repo="$(git rev-parse --show-toplevel)"
src=$(memory_src_dir "$repo") || exit 0
memory_sync "$src" "$repo/.memory"
if [ -n "$(git -C "$repo" status --porcelain -- .memory)" ]; then
  git -C "$repo" add .memory
  git -C "$repo" commit -q -m "chore: sync .memory mirror"
  echo "[pre-push] committed the .memory mirror; run git push again to include it."
  exit 1
fi
exit 0
