#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
lint="$root/tests/lint_modules.py"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

mk() { # mk <root> <dir> <json>
  mkdir -p "$1/$2/agent/rules"; printf '%s' "$3" > "$1/$2/module.json"
}
ok='{"name":"good","principles":[5],"role":"tool","depends_on":[],"rules":["agent/rules/r.md"],"skills":[],"hooks":[],"git_hooks":[],"requires":[],"upstream_skills":[],"placeholders":{"X":{"description":"d","default":""}},"copies":[]}'

r1="$tmp/r1"; mk "$r1" modules/good "$ok"; printf 'use {{X}}\n' > "$r1/modules/good/agent/rules/r.md"
t_exit "valid module passes" 0 python3 "$lint" --root "$r1"

r2="$tmp/r2"; mk "$r2" modules/bad '{"name":"other","principles":[1],"role":"tool","depends_on":["nope"],"rules":["agent/rules/missing.md"],"skills":[],"hooks":[],"git_hooks":[],"requires":[],"upstream_skills":[],"placeholders":{}}'
printf 'use {{Y}}\n' > "$r2/modules/bad/agent/rules/r.md"
t_exit "invalid module fails" 1 python3 "$lint" --root "$r2"
t_out "name mismatch reported" "name 'other' != directory 'bad'" python3 "$lint" --root "$r2"
t_out "principle 1 rejected" "principles must be" python3 "$lint" --root "$r2"
t_out "unknown dependency reported" "depends_on unknown module 'nope'" python3 "$lint" --root "$r2"
t_out "missing file reported" "listed file missing: agent/rules/missing.md" python3 "$lint" --root "$r2"
t_out "undeclared placeholder reported" "undeclared placeholders \['Y'\]" python3 "$lint" --root "$r2"

r3="$tmp/r3"; mk "$r3" skills/zh '{"name":"zh","principles":[3],"role":"extra","depends_on":[],"rules":[],"skills":[],"hooks":[],"git_hooks":[],"requires":[],"upstream_skills":[],"placeholders":{}}'
t_out "supplementary skills must have no principles" "supplementary skills have principles \[\]" python3 "$lint" --root "$r3"

r4="$tmp/r4"; mk "$r4" modules/good "$ok"; printf 'use {{X}}\n' > "$r4/modules/good/agent/rules/r.md"
printf '# a\n## x\n## y\n' > "$r4/modules/good/README.zh.md"; printf '# a\n## x\n' > "$r4/modules/good/README.en.md"
t_out "doc heading parity enforced" "heading count zh=2 en=1" python3 "$lint" --root "$r4" --require-docs

r5="$tmp/r5"; mk "$r5" modules/sk '{"name":"sk","principles":[3],"role":"skills","depends_on":[],"rules":[],"skills":["s1"],"hooks":[],"git_hooks":[],"requires":[],"upstream_skills":[],"placeholders":{}}'
mkdir -p "$r5/modules/sk/agent/skills/s1"; printf -- '---\nname: s2\ndescription: Does things\n---\n' > "$r5/modules/sk/agent/skills/s1/SKILL.md"
t_out "skill name must match dir" "s1/SKILL.md name 's2' != 's1'" python3 "$lint" --root "$r5"
t_out "skill description must start with Use when" "description must start with 'Use when'" python3 "$lint" --root "$r5"

t_done lint
