#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
hook="$root/modules/checkup/agent/hooks/checkup-reminder.sh"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
stub="$tmp/claude"
cat > "$stub" <<'EOF'
#!/bin/sh
[ -n "$STUB_SLEEP" ] && exec sleep "$STUB_SLEEP"
echo "$STUB_VER (Claude Code)"
EOF
chmod +x "$stub"
state="$tmp/state.json"
run() { env CLAUDE_BIN="${BIN:-$stub}" WORKFLOW_CHECKUP_STATE="$state" STUB_VER="$1" STUB_SLEEP="${2:-}" bash "$hook"; }

t_no_out "first run is silent" "." run 2.0.0
t_out "first run records version" '"last_version": ?"2\.0\.0"' cat "$state"
t_no_out "same version is silent" "." run 2.0.0
t_out "changed version reminds once" "2\.0\.0 to 2\.1\.0.*rules-checkup" run 2.1.0
t_out "state updated" '"last_version": ?"2\.1\.0"' cat "$state"
t_no_out "no second reminder" "." run 2.1.0
printf '{"last_version":"2.1.0","last_checkup":"2026-10-01"}' > "$state"
run 2.2.0 >/dev/null
t_out "last_checkup preserved" '"last_checkup": ?"2026-10-01"' cat "$state"
BIN="$tmp/missing" t_exit "missing claude exits 0" 0 run 9.9.9
BIN="$tmp/missing" t_no_out "missing claude is silent" "." run 9.9.9
t_true "hanging claude returns within 8s" bash -c "start=\$SECONDS; env CLAUDE_BIN='$stub' WORKFLOW_CHECKUP_STATE='$state' STUB_VER=x STUB_SLEEP=30 bash '$hook' >/dev/null; [ \$((SECONDS-start)) -lt 8 ]"

t_done checkup
