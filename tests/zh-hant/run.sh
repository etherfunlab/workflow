#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
c="$root/tests/zh-hant/cases"
skill="$root/skills/zh-hant-converter/agent/skills/zh-hant-converter/SKILL.md"
t_out "skill names the internal command" 'opencc -c s2hk' cat "$skill"
t_out "skill has both modes" '(?s)Internal.*External' cat "$skill"
if command -v opencc >/dev/null 2>&1; then
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  opencc -c s2hk -i "$c/internal.zh-Hans.txt" -o "$tmp/out.txt"
  t_true "internal mode: glyphs only, technical terms kept" cmp -s "$tmp/out.txt" "$c/internal.zh-Hant.txt"
else
  echo "SKIP zh-hant opencc case: opencc not installed (brew install opencc)"
fi
t_done zh-hant
