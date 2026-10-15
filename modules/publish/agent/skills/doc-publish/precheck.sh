#!/usr/bin/env bash
# Mechanical precheck for documents: what a regex can judge, so people don't have to.
# Usage: precheck.sh <file.md> [...]
# Optional config: precheck.conf next to this script (shell syntax):
#   ZH_CHECKS=1        Chinese typography in files that contain Chinese
#   CONTRAST_WARN=1    list contrast constructions for a person to judge (never fails)
#   FRONTMATTER_CMD="" command that validates frontmatter; empty skips it
# Unicode matching uses perl, never `grep -P`: on macOS a script gets BSD grep,
# which has no -P.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZH_CHECKS=1
CONTRAST_WARN=1
FRONTMATTER_CMD=""
[ -f "$here/precheck.conf" ] && . "$here/precheck.conf"
[ $# -eq 0 ] && { echo "usage: $0 <file.md> [...]"; exit 2; }

fail=0

# scan <regex> <file>: matching lines, skipping fenced code blocks and inline code
scan() {
  perl -CSDA -ne '
    BEGIN { $re = shift @ARGV }
    if (/^\s*(```|~~~)/) { $in = !$in; next }
    next if $in;
    (my $t = $_) =~ s/`[^`]*`//g;
    print "  $.: $_" if $t =~ /$re/;
  ' "$1" "$2"
}
has_han() { perl -CSD -ne 'if (/\p{Han}/) { $f = 1; last } END { exit($f ? 0 : 1) }' "$1"; }
hit()  { local out; out=$(scan "$1" "$2"); if [ -n "$out" ]; then printf '%s\n' "$out"; echo "  ✗ $3"; fail=1; fi; }
warn() { local out; out=$(scan "$1" "$2"); if [ -n "$out" ]; then printf '%s\n' "$out"; echo "  ⚠ $3"; fi; }

for f in "$@"; do
  echo "== $f"
  [ -f "$f" ] || { echo "  ✗ file not found"; fail=1; continue; }
  if [ "$ZH_CHECKS" = 1 ] && has_han "$f"; then
    hit '\x{2013}' "$f" 'en-dash (U+2013): use ASCII -'
    hit '\p{Han},|,\p{Han}' "$f" 'half-width comma next to Chinese: use ，'
  fi
  if [ "$CONTRAST_WARN" = 1 ]; then
    warn '不(?:是|只是|仅仅?是)[^，。！？\n]{0,30}，\s*(?:而)?是|并非[^，。\n]{0,30}，?\s*而是|，\s*(?:而)?不是|与其说[^，。\n]{0,25}，?\s*不如说|\bnot (?:just |only |merely )?[^,.;\n]{1,40}, but\b' "$f" \
      'contrast construction: can the negated reading be traced to a source? If not, delete it. Not blocking.'
  fi
done

if [ -n "$FRONTMATTER_CMD" ] && ! bash -c "$FRONTMATTER_CMD" >/dev/null 2>&1; then
  echo "✗ frontmatter check failed: $FRONTMATTER_CMD"
  fail=1
fi

if [ $fail -eq 0 ]; then echo "✓ precheck passed"; else echo "✗ precheck failed: fix before the next stage"; fi
exit $fail
