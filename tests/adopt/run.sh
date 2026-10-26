#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
cl="$root/tests/adopt/check_lock.py"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
sha=$(printf '%040d' 0 | tr 0 a)

mkrepo() { mkdir -p "$1"; printf '# Rules\n\n## Engineering\n\n- x\n' > "$1/AGENTS.md"; }
lock() { printf '%s' "$2" > "$1/.workflow.lock"; }
good='{"upstream":"https://github.com/etherfunlab/workflow","commit":"'"$sha"'","adopted_at":"2026-10-15","language":"en","agent":"claude-code","skills_scope":"project","modules":{"engineering":{"files":["AGENTS.md#Engineering"]}}}'

r=$tmp/ok; mkrepo $r; lock $r "$good"
t_exit "valid lock passes" 0 python3 "$cl" "$r"
r=$tmp/nolock; mkrepo $r
t_out "missing lock reported" "\.workflow\.lock missing" python3 "$cl" "$r"
r=$tmp/badjson; mkrepo $r; lock $r '{'
t_out "invalid JSON reported" "not valid JSON" python3 "$cl" "$r"
r=$tmp/sha; mkrepo $r; lock $r "${good/$sha/abc}"
t_out "short sha reported" "40-char" python3 "$cl" "$r"
r=$tmp/file; mkrepo $r; lock $r "${good/AGENTS.md#Engineering/NOPE.md}"
t_out "missing file reported" "NOPE\.md does not exist" python3 "$cl" "$r"
r=$tmp/head; mkrepo $r; lock $r "${good/AGENTS.md#Engineering/AGENTS.md#Writing}"
t_out "missing heading reported" "heading 'Writing' not found" python3 "$cl" "$r"

r=$tmp/modcommit; mkrepo $r; lock $r "${good/\"files\":/\"commit\":\"xyz\",\"files\":}"
t_out "per-module commit is validated" "modules.engineering.commit must be" python3 "$cl" "$r"
r=$tmp/modcommitok; mkrepo $r; lock $r "${good/\"files\":/\"commit\":\"$sha\",\"files\":}"
t_exit "valid per-module commit passes" 0 python3 "$cl" "$r"

noscope="${good/\"skills_scope\":\"project\",/}"
r=$tmp/noscope; mkrepo $r; lock $r "$noscope"
t_exit "skills_scope may be omitted when no skills are installed" 0 python3 "$cl" "$r"
r=$tmp/skillnoscope; mkrepo $r; mkdir -p "$r/.claude/skills/s"
lock $r "${noscope/\"AGENTS.md#Engineering\"/\"AGENTS.md#Engineering\",\".claude/skills/s/\"}"
t_out "skills_scope required when skills are installed" "skills_scope missing" python3 "$cl" "$r"
r=$tmp/badscope; mkrepo $r; lock $r "${good/\"project\"/\"team\"}"
t_out "skills_scope value is validated" "skills_scope must be project or user" python3 "$cl" "$r"

d=$tmp/prep; "$root/tests/adopt/prepare.sh" existing "$d" >/dev/null
t_true "prepare copies fixture" test -f "$d/docs/team-rules.md"
t_out "prepare makes a clean repo" "^$" git -C "$d" status --porcelain

t_done adopt-checkers
