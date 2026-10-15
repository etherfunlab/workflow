#!/usr/bin/env bash
# prepare.sh <fixture> <dest>: copy tests/fixtures/<fixture> into <dest> as a fresh git repo.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
src="$root/tests/fixtures/$1"; dest="$2"
[ -d "$src" ] || { echo "no fixture: $1"; exit 2; }
mkdir -p "$dest"
cp -R "$src"/. "$dest"/
git -C "$dest" init -q
git -C "$dest" add -A
git -C "$dest" -c user.email=t@example.com -c user.name=t commit -q -m "fixture: $1"
