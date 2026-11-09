#!/usr/bin/env bash
# Claude Code SessionStart: once after Claude Code changes version, remind that
# rule files were written against the previous harness. Never runs the checkup.
# Silent while last_checkup is less than WORKFLOW_CHECKUP_MIN_DAYS old; the
# recorded version is left alone then, so the reminder comes once that passes.
set -uo pipefail
state="${WORKFLOW_CHECKUP_STATE:-$HOME/.claude/workflow-checkup.json}"
min_days="${WORKFLOW_CHECKUP_MIN_DAYS:-14}"
bin="${CLAUDE_BIN:-claude}"
ver=$(perl -e 'alarm 5; exec @ARGV' "$bin" --version 2>/dev/null </dev/null | head -n1 | awk '{print $1}') || true
[ -z "$ver" ] && exit 0

write_state() {
  mkdir -p "$(dirname "$state")"
  local tmp; tmp=$(mktemp)
  if [ -f "$state" ] && jq --arg v "$1" '.last_version = $v' "$state" > "$tmp" 2>/dev/null; then :
  else jq -n --arg v "$1" '{last_version: $v}' > "$tmp"; fi
  mv "$tmp" "$state"
}

last=""
[ -f "$state" ] && last=$(jq -r '.last_version // empty' "$state" 2>/dev/null)
if [ -z "$last" ]; then write_state "$ver"; exit 0; fi
checked_recently() {
  local day; day=$(jq -r '.last_checkup // empty' "$state" 2>/dev/null)
  [ -n "$day" ] || return 1
  perl -MTime::Local -e '
    my ($y, $m, $d) = $ARGV[0] =~ /^(\d{4})-(\d\d)-(\d\d)$/ or exit 1;
    exit 1 if $y < 1970;
    my $age = time - timegm(0, 0, 0, $d, $m - 1, $y);
    # A date more than a day ahead is a broken record, not a recent checkup.
    exit($age > -86400 && $age < $ARGV[1] * 86400 ? 0 : 1)' "$day" "$min_days" 2>/dev/null
}

if [ "$last" != "$ver" ]; then
  checked_recently && exit 0
  echo "Claude Code changed from $last to $ver. Rule files were written against the previous harness; suggest to the user that they run the rules-checkup skill. Do not run it unprompted."
  write_state "$ver"
fi
exit 0
