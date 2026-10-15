#!/usr/bin/env bash
# Claude Code SessionStart: once after Claude Code changes version, remind that
# rule files were written against the previous harness. Never runs the checkup.
set -uo pipefail
state="${WORKFLOW_CHECKUP_STATE:-$HOME/.claude/workflow-checkup.json}"
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
if [ "$last" != "$ver" ]; then
  echo "Claude Code changed from $last to $ver since the last reminder. Rule files were written against the previous harness; suggest to the user that they run the rules-checkup skill. Do not run it unprompted."
  write_state "$ver"
fi
exit 0
