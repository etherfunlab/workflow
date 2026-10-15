# tests/lib.sh — assertion helpers. Source it, call t_*, end with: t_done <suite>
T_PASS=0
T_FAIL=0

# t_exit <name> <want-exit> <cmd...>
t_exit() {
  local name=$1 want=$2; shift 2
  local out got
  out=$("$@" 2>&1); got=$?
  if [ "$got" = "$want" ]; then T_PASS=$((T_PASS+1))
  else T_FAIL=$((T_FAIL+1)); printf 'FAIL %s: exit %s, want %s\n%s\n' "$name" "$got" "$want" "$out"; fi
}

_t_match() { perl -CSDA -e '$re = shift; local $/; my $s = <STDIN>; exit($s =~ /$re/m ? 0 : 1)' "$1"; }

# t_out <name> <perl-regex> <cmd...>  — passes when combined output matches
t_out() {
  local name=$1 re=$2; shift 2
  local out; out=$("$@" 2>&1)
  if printf '%s' "$out" | _t_match "$re"; then T_PASS=$((T_PASS+1))
  else T_FAIL=$((T_FAIL+1)); printf 'FAIL %s: output did not match /%s/\n%s\n' "$name" "$re" "$out"; fi
}

# t_no_out <name> <perl-regex> <cmd...>  — passes when combined output does NOT match
t_no_out() {
  local name=$1 re=$2; shift 2
  local out; out=$("$@" 2>&1)
  if printf '%s' "$out" | _t_match "$re"; then T_FAIL=$((T_FAIL+1)); printf 'FAIL %s: output matched /%s/\n%s\n' "$name" "$re" "$out"
  else T_PASS=$((T_PASS+1)); fi
}

# t_true <name> <cmd...>  — passes when cmd exits 0
t_true() {
  local name=$1; shift
  if "$@" >/dev/null 2>&1; then T_PASS=$((T_PASS+1)); else T_FAIL=$((T_FAIL+1)); echo "FAIL $name"; fi
}

t_done() { echo "$1: $T_PASS passed, $T_FAIL failed"; [ "$T_FAIL" -eq 0 ]; }
