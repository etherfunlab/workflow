#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
pc="$root/modules/publish/agent/skills/doc-publish/precheck.sh"
c="$root/tests/precheck/cases"

t_exit "half-width comma and en-dash in zh fail" 1 "$pc" "$c/zh-bad.md"
t_out "comma line reported" "3: 这里用了半角逗号" "$pc" "$c/zh-bad.md"
t_out "en-dash line reported" "4: 时间范围" "$pc" "$c/zh-bad.md"
t_exit "code fences and inline code are skipped" 0 "$pc" "$c/zh-good.md"
t_exit "en-dash allowed in English-only docs" 0 "$pc" "$c/en-dash.md"
t_exit "contrast construction warns but passes" 0 "$pc" "$c/contrast.md"
t_out "contrast construction located" "⚠ contrast construction" "$pc" "$c/contrast.md"
t_exit "missing file fails" 1 "$pc" "$c/nope.md"
t_exit "no args is usage error" 2 "$pc"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp "$pc" "$tmp/precheck.sh"
printf 'FRONTMATTER_CMD="false"\n' > "$tmp/precheck.conf"
t_exit "failing frontmatter command fails" 1 "$tmp/precheck.sh" "$c/en-dash.md"
printf 'FRONTMATTER_CMD="true"\nZH_CHECKS=0\n' > "$tmp/precheck.conf"
t_exit "ZH_CHECKS=0 disables zh checks" 0 "$tmp/precheck.sh" "$c/zh-bad.md"

t_done precheck
