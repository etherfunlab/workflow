#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
py="$root/modules/review/agent/skills/codex-review/openrouter_review.py"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
t_true "script compiles" python3 -m py_compile "$py"
t_exit "missing key exits 1" 1 env -u OPENROUTER_API_KEY python3 "$py" --prompt "$tmp/p" --out "$tmp/o"
t_out "missing key message" "OPENROUTER_API_KEY not set" env -u OPENROUTER_API_KEY python3 "$py" --prompt "$tmp/p" --out "$tmp/o"
t_exit "missing prompt file fails before any request" 1 env OPENROUTER_API_KEY=x python3 "$py" --prompt "$tmp/nope" --out "$tmp/o"
t_true "no output written on failure" test ! -e "$tmp/o"
t_done review
