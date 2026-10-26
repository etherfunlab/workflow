#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
skill="$root/skills/ios-keyboard-page-shift/agent/skills/ios-keyboard-page-shift/SKILL.md"
t_out "skill tells the two layers apart" '(?s)Fix A.*Fix B' cat "$skill"
t_out "skill ships the reference implementation" 'keyboard-scroll-restore\.js' cat "$skill"
if command -v node >/dev/null 2>&1; then
  t_exit "reference implementation passes its tests" 0 node --test "$root/tests/ios-keyboard/restore.test.mjs"
else
  echo "SKIP ios-keyboard node tests: node not installed"
fi
t_done ios-keyboard
