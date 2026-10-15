#!/usr/bin/env bash
# Runs every suite. Pass --require-docs once module READMEs exist.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
status=0
for s in "$root"/tests/*/run.sh; do
  bash "$s" || status=1
done
python3 "$root/tests/lint_modules.py" "$@" && echo "lint_modules: ok" || status=1
exit $status
