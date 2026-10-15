#!/usr/bin/env bash
# check-scenario.sh <dir>: assertions for a rules-checkup dry run on the checkup fixture.
# The agent answers in the user's language, so labels are matched in English or Chinese.
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
d="$1"; out="$d/CHECKUP.md"
t_true "CHECKUP.md written" test -f "$out"
t_out "only CHECKUP.md changed" '^\?\? CHECKUP\.md\s*$' git -C "$d" status --porcelain
t_out "stale script found" "deploy-legacy" cat "$out"
t_out "incident residue found" "#123" cat "$out"
t_out "hidden brake flagged" "(?i)hidden brake|刹车" cat "$out"
t_out "redundancy with the system prompt flagged" "(?i)redundant|system prompt|系统提示" cat "$out"
t_out "duplicate with memory found" "(?i)pnpm.*(memory|MEMORY\.md)|(memory|MEMORY\.md).*pnpm" cat "$out"
t_out "asks which items to apply" "(?i)which items|哪几条|哪些" cat "$out"
t_done checkup-scenario
