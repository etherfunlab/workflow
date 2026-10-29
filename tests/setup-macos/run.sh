#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
setup="$root/setup/macos"
# Captured before any test overrides HOME. The suite never spells out a home
# path: the repo's pre-push denylist rejects one.
real_home=$HOME

# Templates.
t_exit "zshrc parses" 0 zsh -n "$setup/zshrc"
t_exit "p10k.zsh parses" 0 zsh -n "$setup/p10k.zsh"
t_exit "iterm2 profile is JSON" 0 python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$setup/iterm2-profile.json"
t_out "profile has the fixed guid" '"Guid": *"9B8C7E2A-4F31-4C5D-A6E0-2D7F5B3C9A11"' cat "$setup/iterm2-profile.json"
t_out "profile names the font" '"Normal Font": *"MesloLGS-NF-Regular 15"' cat "$setup/iterm2-profile.json"
t_true "no home paths under setup/" bash -c 'test -d "$1" && ! grep -rnF "$2" "$1"' _ "$setup" "$real_home"
t_out "zshrc sources syntax highlighting last" 'zsh-syntax-highlighting\.zsh\s*$' tail -n 1 "$setup/zshrc"
t_out "zshrc puts fpath before oh-my-zsh" 'fpath=\(.*\n(.*\n)*source \$ZSH/oh-my-zsh\.sh' cat "$setup/zshrc"
t_true "zshrc has no supabase line" bash -c 'test -f "$1" && ! grep -q SUPABASE "$1"' _ "$setup/zshrc"

t_done setup-macos
