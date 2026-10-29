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

# Harness for install.sh: a temp HOME, stubbed tools first on a PATH without
# the real Homebrew, and canned HTTP responses. Stubs log every call.
STUB_DIR="$root/tests/setup-macos/stubs"
P10K_COMMIT=d05a1b00f9a61f9578bf9dc19b8451942dde8734
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
n=0
fresh() {
  n=$((n+1)); tmp="$work/$n"; mkdir -p "$tmp/home" "$tmp/http"
  cp "$root/tests/setup-macos/http/"* "$tmp/http/"
  local f
  for f in zshrc p10k.zsh iterm2-profile.json; do
    cp "$setup/$f" "$tmp/http/https___raw.githubusercontent.com_etherfunlab_workflow_main_setup_macos_$f"
    cp "$setup/$f" "$tmp/http/https___cdn.jsdelivr.net_gh_etherfunlab_workflow@main_setup_macos_$f"
  done
  unset SETUP_MIRROR SETUP_P10K_COMMIT STUB_ARCH STUB_UID STUB_GIT_FAIL STUB_BREW_FAIL \
    STUB_BREW_FORCE_OK STUB_ITERM_RUNNING EXTRA_PATH NO_COLOR \
    HOMEBREW_BREW_GIT_REMOTE HOMEBREW_API_DOMAIN HOMEBREW_BOTTLE_DOMAIN
  export HOME="$tmp/home" SHELL=/bin/zsh STUB_DIR \
    SETUP_BREW_PREFIX="$tmp/brew" SETUP_APPS_DIR="$tmp/apps" SETUP_LOG="$tmp/setup.log" \
    SETUP_CLT_FLAG="$tmp/clt-flag" STUB_CLT="$tmp/clt" STUB_HTTP="$tmp/http" \
    STUB_LOG="$tmp/calls" STUB_BREW_STATE="$tmp/brew-state"
  : > "$STUB_LOG"; : > "$STUB_BREW_STATE"
}
safe() { # never let install.sh near the real HOME or Homebrew
  case "$HOME:$SETUP_BREW_PREFIX" in "$work"/*:"$work"/*) ;; *) echo "unsafe test env"; return 99 ;; esac
}
# Shadows /usr/bin/install, which this suite never needs.
install() { safe && PATH="$STUB_DIR:${EXTRA_PATH:+$EXTRA_PATH:}/usr/bin:/bin" bash "$setup/install.sh"; }
# The way the documented start line runs it: no BASH_SOURCE, templates over curl.
install_piped() { safe && (cd "$tmp" && PATH="$STUB_DIR:/usr/bin:/bin" bash -c "$(cat "$setup/install.sh")"); }
calls() { cat "$STUB_LOG"; }

# Preflight.
fresh; STUB_ARCH=x86_64 t_exit "intel mac exits 1" 1 install
t_true "intel mac wrote nothing" test ! -e "$HOME/.zshrc" -a ! -e "$SETUP_LOG"
fresh; STUB_UID=0 t_exit "root exits 1" 1 install
fresh; SETUP_MIRROR=bogus t_exit "unknown mirror exits 1" 1 install
SETUP_MIRROR=bogus t_out "unknown mirror says why" 'SETUP_MIRROR must be empty or jsdelivr' install
fresh; install > "$tmp/out" 2>&1
t_true "no color codes when piped" perl -ne '$b = 1 if /==>/; $e = 1 if /\e\[/; END { exit !($b && !$e) }' "$tmp/out"
fresh; t_out "preflight banner" '==> \[ 1/10\] Preflight\n\s+macOS 27\.0\.1, arm64, not root\s+ok' install

# Command Line Tools and Homebrew.
fresh; install >/dev/null
t_out "clt installed headless" 'softwareupdate -i Command Line Tools for Xcode-27\.0' calls
t_no_out "no gui clt prompt" 'xcode-select --install' calls
t_true "clt flag cleaned up" test ! -e "$SETUP_CLT_FLAG"
fresh; touch "$STUB_CLT"
t_out "clt present is skipped" '\[ 2/10\] Xcode Command Line Tools\n\s+already installed\s+skip' install
fresh; install >/dev/null
t_out "default mode uses github installer" 'curl .*raw\.githubusercontent\.com/Homebrew/install/HEAD/install\.sh' calls
t_no_out "default mode touches no mirror" 'mirrors\.ustc\.edu\.cn' calls
fresh; SETUP_MIRROR=jsdelivr install >/dev/null
t_out "mirror mode uses ustc installer" 'curl .*mirrors\.ustc\.edu\.cn/misc/brew-install\.sh' calls
t_out "mirror mode points brew at ustc" 'HOMEBREW_BREW_GIT_REMOTE=https://mirrors\.ustc\.edu\.cn/brew\.git' cat "$SETUP_LOG"
fresh; SETUP_MIRROR=jsdelivr HOMEBREW_BOTTLE_DOMAIN=https://example.test/b install >/dev/null
t_out "preset HOMEBREW var wins" 'HOMEBREW_BOTTLE_DOMAIN=https://example\.test/b' cat "$SETUP_LOG"
fresh; mkdir -p "$SETUP_BREW_PREFIX/bin"; cp "$STUB_DIR/brew" "$SETUP_BREW_PREFIX/bin/brew"
t_out "brew present is skipped" '\[ 3/10\] Homebrew\n\s+already installed\s+skip' install
fresh; rm "$tmp/http/https___raw.githubusercontent.com_Homebrew_install_HEAD_install.sh"
t_exit "unreachable brew installer stops the run" 1 install
t_out "stop names the log" 'installer\s+FAIL\n\n.*curl .*exited 22\..*\n(\s+│.*\n){1,3}\s+Full log: .*setup\.log\n\s+Fix the problem and run the same command again' install

# oh-my-zsh and powerlevel10k.
p10k="themes/powerlevel10k"
fresh; install >/dev/null
t_out "omz default installer" 'curl .*raw\.githubusercontent\.com/ohmyzsh/ohmyzsh/master/tools/install\.sh' calls
t_true "omz unattended keeps zshrc" grep -q -- "--unattended --keep-zshrc" "$SETUP_LOG"
t_out "p10k default clones github" 'git clone --depth=1 https://github\.com/romkatv/powerlevel10k\.git' calls
fresh; SETUP_MIRROR=jsdelivr install >/dev/null
t_out "omz mirror installer" 'curl .*install\.ohmyz\.sh/' calls
t_true "omz mirror mode without failure stays on github" bash -c '! grep -q "gitee\.com/mirrors/oh-my-zsh" "$1"' _ "$SETUP_LOG"
t_out "p10k mirror lists the pinned commit" "data\.jsdelivr\.com/v1/packages/gh/romkatv/powerlevel10k@$P10K_COMMIT\?structure=flat" calls
t_true "p10k mirror fetched every listed file" test -f "$HOME/.oh-my-zsh/custom/$p10k/internal/p10k.zsh" -a -f "$HOME/.oh-my-zsh/custom/$p10k/powerlevel10k.zsh-theme"
t_true "p10k mirror restores the exec bit" test -x "$HOME/.oh-my-zsh/custom/$p10k/gitstatus/install"
t_no_out "p10k mirror never touches github" 'github\.com/romkatv' calls
t_no_out "p10k mirror never asks for a branch" 'powerlevel10k@master' calls
t_no_out "package name is not taken for a file" 'powerlevel10k@[0-9a-f]+romkatv' calls
fresh; SETUP_MIRROR=jsdelivr STUB_GIT_FAIL='*github.com/ohmyzsh*' install > "$tmp/out" 2>&1
t_out "omz falls back to gitee" 'REMOTE=https://gitee\.com/mirrors/oh-my-zsh\.git' cat "$SETUP_LOG"
t_out "fallback is announced" 'trying the gitee mirror\n\s+cloned from gitee\.com/mirrors/oh-my-zsh\s+done' cat "$tmp/out"
fresh; STUB_GIT_FAIL='*github.com/ohmyzsh*' t_out "omz default mode does not fall back" '\[ 4/10\] oh-my-zsh\n\s+installer\s+FAIL' install
fresh; printf '<html><body>502 Bad Gateway</body></html>\n' > "$tmp/http/https___data.jsdelivr.com_v1_packages_gh_romkatv_powerlevel10k@deadbeef?structure=flat"
SETUP_MIRROR=jsdelivr SETUP_P10K_COMMIT=deadbeef t_exit "bad listing stops the run" 1 install
t_true "bad listing leaves no p10k dir" test ! -e "$HOME/.oh-my-zsh/custom/$p10k"
fresh; SETUP_MIRROR=jsdelivr SETUP_P10K_COMMIT=feedface install >/dev/null 2>&1
t_true "missing listing leaves no p10k dir" test ! -e "$HOME/.oh-my-zsh/custom/$p10k"
fresh; mkdir -p "$HOME/.oh-my-zsh/.git" "$HOME/.oh-my-zsh/custom/$p10k"
t_out "omz and p10k present are skipped" 'oh-my-zsh\n\s+already installed\s+skip\n.*powerlevel10k\n\s+already installed\s+skip' install

t_done setup-macos
