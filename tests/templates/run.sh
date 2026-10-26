#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
ct="$root/tests/check_templates.py"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

t_exit "repo templates pass" 0 python3 "$ct"
for f in AGENTS.md DESIGN.md FONTS.md GRID.md LOCALE.md RELEASE.md; do
  t_true "frontend has $f" test -f "$root/templates/frontend/$f"
done

mk() { # mk <root>: a valid base plus a template "t" with two docs
  mkdir -p "$1/templates/base" "$1/templates/t"
  printf '# AGENTS.md\n' > "$1/templates/base/AGENTS.md"; printf '@AGENTS.md\n' > "$1/templates/base/CLAUDE.md"
  printf '# t\n## a\n' > "$1/templates/t/README.zh.md"; printf '# t\n## a\n' > "$1/templates/t/README.en.md"
  printf '# A\n## 1. One\nSee §2 and `B.md` §3.\n## 2. Two\n### 2.1 Sub\n' > "$1/templates/t/A.md"
  printf '# B\n## 3. Three\nBack to `A.md` §2.1.\n' > "$1/templates/t/B.md"
}

r=$tmp/ok; mk $r
t_exit "valid template passes" 0 python3 "$ct" --root "$r"
r=$tmp/ref; mk $r; printf 'See §9.\n' >> "$r/templates/t/A.md"
t_out "dangling same-file reference reported" "A\.md §9 not found" python3 "$ct" --root "$r"
r=$tmp/xref; mk $r; printf 'See `B.md` §4.\n' >> "$r/templates/t/A.md"
t_out "dangling cross-file reference reported" "B\.md §4 not found" python3 "$ct" --root "$r"
r=$tmp/nofile; mk $r; printf 'See `C.md` §1.\n' >> "$r/templates/t/A.md"
t_out "reference to a missing file reported" "points at C\.md" python3 "$ct" --root "$r"
r=$tmp/dup; mk $r; printf '## 1. Again\n' >> "$r/templates/t/A.md"
t_out "reused section number reported" "used twice: \['1'\]" python3 "$ct" --root "$r"
r=$tmp/ph; mk $r; printf 'Color: {{BRAND}}\n' >> "$r/templates/t/B.md"
t_out "placeholder in a template reported" "PLACEHOLDER\}\} found" python3 "$ct" --root "$r"
r=$tmp/readme; mk $r; printf '## b\n' >> "$r/templates/t/README.zh.md"
t_out "README heading parity enforced" "heading count zh=2 en=1" python3 "$ct" --root "$r"
r=$tmp/claude; mk $r; printf 'x\n' > "$r/templates/base/CLAUDE.md"
t_out "base CLAUDE.md must import AGENTS.md" "does not import @AGENTS\.md" python3 "$ct" --root "$r"
r=$tmp/deep; mk $r; printf 'See §2.1.4.\n' >> "$r/templates/t/A.md"
t_out "deeper reference is not cut down to its parent" "A\.md §2\.1\.4 not found" python3 "$ct" --root "$r"
r=$tmp/deepok; mk $r; printf '#### 2.1.4 Deep\n' >> "$r/templates/t/A.md"; printf 'See `A.md` §2.1.4.\n' >> "$r/templates/t/B.md"
t_exit "deeper heading resolves" 0 python3 "$ct" --root "$r"
r=$tmp/group; mk $r; printf 'See (`B.md` §3, §1).\n' >> "$r/templates/t/A.md"
t_out "grouped cross-file reference rejected" "name the file on each cross-file reference" python3 "$ct" --root "$r"
r=$tmp/empty; mk $r; rm "$r/templates/t/A.md" "$r/templates/t/B.md"
t_out "template with only READMEs reported" "templates/t: no files to install" python3 "$ct" --root "$r"
r=$tmp/notemplates; mkdir -p "$r"
t_out "missing templates dir reported without a traceback" "^templates/ missing$" python3 "$ct" --root "$r"
t_no_out "missing templates dir does not crash" "Traceback" python3 "$ct" --root "$r"

t_done templates
