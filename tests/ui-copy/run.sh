#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
skill="$root/modules/publish/agent/skills/ui-copy-gemini/SKILL.md"
t_out "skill calls the script through its placeholder" '\{\{UI_COPY_DRAFT_PATH\}\} draft' cat "$skill"
t_out "skill says the call is paid" '(?i)paid call' cat "$skill"
if command -v node >/dev/null 2>&1; then
  t_exit "draft script passes its tests" 0 node --test "$root/tests/ui-copy/draft.test.mjs"
else
  echo "SKIP ui-copy node tests: node not installed"
fi
t_done ui-copy
