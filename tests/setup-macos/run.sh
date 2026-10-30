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
  n=$((n+1)); tmp="$work/$n"; mkdir -p "$tmp/home" "$tmp/http" "$tmp/tmpdir"
  cp "$root/tests/setup-macos/http/"* "$tmp/http/"
  local f
  for f in zshrc p10k.zsh iterm2-profile.json; do
    cp "$setup/$f" "$tmp/http/https___raw.githubusercontent.com_etherfunlab_workflow_main_setup_macos_$f"
    cp "$setup/$f" "$tmp/http/https___cdn.jsdelivr.net_gh_etherfunlab_workflow@main_setup_macos_$f"
  done
  unset SETUP_MIRROR SETUP_P10K_COMMIT STUB_ARCH STUB_UID STUB_GIT_FAIL STUB_BREW_FAIL \
    STUB_ITERM_RUNNING STUB_SUDO_FAIL EXTRA_PATH NO_COLOR ZDOTDIR HOMEBREW_GITHUB_API_TOKEN \
    HOMEBREW_BREW_GIT_REMOTE HOMEBREW_API_DOMAIN HOMEBREW_BOTTLE_DOMAIN
  export HOME="$tmp/home" SHELL=/bin/zsh STUB_DIR TMPDIR="$tmp/tmpdir" \
    SETUP_BREW_PREFIX="$tmp/brew" SETUP_APPS_DIR="$tmp/apps" SETUP_LOG="$tmp/setup.log" \
    SETUP_CLT_FLAG="$tmp/clt-flag" STUB_CLT="$tmp/clt" STUB_HTTP="$tmp/http" \
    STUB_LOG="$tmp/calls" STUB_BREW_STATE="$tmp/brew-state"
  : > "$STUB_LOG"; : > "$STUB_BREW_STATE"
}
safe() { # never let install.sh near the real HOME, Homebrew, /tmp or /Applications
  case "$HOME:$SETUP_BREW_PREFIX:$SETUP_CLT_FLAG:$SETUP_APPS_DIR" in
    "$work"/*:"$work"/*:"$work"/*:"$work"/*) ;; *) echo "unsafe test env"; return 99 ;;
  esac
  local s
  for s in uname sw_vers id sudo xcode-select softwareupdate curl git brew defaults pgrep; do
    [ -x "$STUB_DIR/$s" ] || { echo "stub missing: $s"; return 99; }
  done
}
# Shadows /usr/bin/install, which this suite never needs.
install() { safe && PATH="$STUB_DIR:${EXTRA_PATH:+$EXTRA_PATH:}/usr/bin:/bin" bash "$setup/install.sh" "$@"; }
# The way the documented start line runs it: no BASH_SOURCE, templates over curl.
install_piped() { safe && (cd "$tmp" && PATH="$STUB_DIR:/usr/bin:/bin" bash -c "$(cat "$setup/install.sh")" - "$@"); }
calls() { cat "$STUB_LOG"; }

# Preflight.
fresh; STUB_ARCH=x86_64 t_exit "intel mac exits 1" 1 install
t_true "intel mac wrote nothing" test ! -e "$HOME/.zshrc" -a ! -e "$SETUP_LOG"
t_true "rejected run made no scratch dir" bash -c '[ -z "$(ls -A "$1")" ]' _ "$TMPDIR"
fresh; STUB_UID=0 t_exit "root exits 1" 1 install
fresh; SETUP_MIRROR=bogus t_exit "unknown mirror exits 1" 1 install
SETUP_MIRROR=bogus t_out "unknown mirror says why" 'SETUP_MIRROR must be empty or jsdelivr' install
fresh; install > "$tmp/out" 2>&1
t_true "no color codes when piped" perl -ne '$b = 1 if /==>/; $e = 1 if /\e\[/; END { exit !($b && !$e) }' "$tmp/out"
fresh; t_out "preflight banner" '==> \[ 1/10\] Preflight\n\s+macOS 27\.0\.1, arm64, not root\s+ok' install
fresh; t_no_out "no job-control noise from the sudo keepalive" 'Terminated|line [0-9]+:' install
t_exit "install.sh parses" 0 bash -n "$setup/install.sh"
fresh; mkdir -p "$SETUP_BREW_PREFIX/bin"; cp "$STUB_DIR/brew" "$SETUP_BREW_PREFIX/bin/brew"; printf 'cask:miniforge\n' > "$STUB_BREW_STATE"
t_exit "brew miniforge stops the run before anything is installed" 1 install
t_out "miniforge stop says why" 'miniforge.*conflicts with.*miniconda' install
t_true "miniforge stop touched nothing" bash -c '! grep -qE "brew install|softwareupdate -i" "$1" && ! test -e "$2/.zshrc" && ! test -e "$3"' _ "$STUB_LOG" "$HOME" "$SETUP_LOG"
fresh; STUB_SUDO_FAIL=1 t_exit "cancelled sudo exits 1" 1 install
fresh; STUB_SUDO_FAIL=1 t_out "cancelled sudo names the log" 'sudo -v failed\.\n\s+Full log: .*setup\.log' install

# Command Line Tools and Homebrew.
fresh; install >/dev/null
t_out "clt installed headless, highest version" 'softwareupdate -i Command Line Tools for Xcode 27\.0-27\.0\.1$' calls
t_no_out "clt beta is not picked" 'softwareupdate -i .*beta' calls
t_true "softwareupdate listing is in the log" grep -q "Command Line Tools for Xcode 27.0-27.0.1" "$SETUP_LOG"
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
fresh; HOMEBREW_GITHUB_API_TOKEN=ghp_secret123 SETUP_MIRROR=jsdelivr install >/dev/null
t_true "tokens never reach the log" bash -c '! grep -q ghp_secret123 "$1"' _ "$SETUP_LOG"
t_true "log is private" bash -c '[ "$(stat -f %Lp "$1")" = 600 ]' _ "$SETUP_LOG"

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
fresh; printf '{"type":"gh","name":"romkatv/powerlevel10k","version":"cafe","files":[{"name":"/powerlevel10k.zsh-theme","hash":"x","size":1},{"name":"/inter' > "$tmp/http/https___data.jsdelivr.com_v1_packages_gh_romkatv_powerlevel10k@cafe?structure=flat"
echo "# theme" > "$tmp/http/https___cdn.jsdelivr.net_gh_romkatv_powerlevel10k@cafe_powerlevel10k.zsh-theme"
SETUP_MIRROR=jsdelivr SETUP_P10K_COMMIT=cafe t_exit "truncated listing stops the run" 1 install
t_true "truncated listing leaves no p10k dir" test ! -e "$HOME/.oh-my-zsh/custom/$p10k"
fresh; printf '{"type":"gh","name":"romkatv/powerlevel10k","version":"bad","files":[{"name":"/powerlevel10k.zsh-theme","hash":"x","size":1},{"name":"/internal/p10k.zsh","hash":"x","size":1},{"name":"/../../../escape","hash":"x","size":1}],"links":{}}\n' > "$tmp/http/https___data.jsdelivr.com_v1_packages_gh_romkatv_powerlevel10k@bad?structure=flat"
echo evil > "$tmp/http/https___cdn.jsdelivr.net_gh_romkatv_powerlevel10k@bad_.._.._.._escape"
for f in powerlevel10k.zsh-theme internal_p10k.zsh; do echo "# $f" > "$tmp/http/https___cdn.jsdelivr.net_gh_romkatv_powerlevel10k@bad_$f"; done
SETUP_MIRROR=jsdelivr SETUP_P10K_COMMIT=bad t_exit "traversal in the listing stops the run" 1 install
t_true "traversal wrote nothing outside the scratch dir" test ! -e "$tmp/escape" -a ! -e "$tmp/tmpdir/escape"
fresh; mkdir -p "$HOME/.oh-my-zsh/.git" "$HOME/.oh-my-zsh/custom/$p10k"; touch "$HOME/.oh-my-zsh/oh-my-zsh.sh" "$HOME/.oh-my-zsh/custom/$p10k/powerlevel10k.zsh-theme"
t_out "omz and p10k present are skipped" 'oh-my-zsh\n\s+already installed\s+skip\n.*powerlevel10k\n\s+already installed\s+skip' install
fresh; mkdir -p "$HOME/.oh-my-zsh/.git"; install > "$tmp/out"
t_true "interrupted omz clone is reinstalled" test -f "$HOME/.oh-my-zsh/oh-my-zsh.sh"
t_out "broken omz dir is moved aside and listed" 'Backups:\n(.*\n)*\s+~/\.oh-my-zsh\.backup-\d{8}-\d{6}' cat "$tmp/out"
fresh; mkdir -p "$HOME/.oh-my-zsh/custom/$p10k"; install >/dev/null
t_true "empty p10k dir is reinstalled" test -f "$HOME/.oh-my-zsh/custom/$p10k/powerlevel10k.zsh-theme"
fresh; ZDOTDIR="$tmp/zdot" install >/dev/null
t_true "omz lands in ~/.oh-my-zsh despite ZDOTDIR" test -f "$HOME/.oh-my-zsh/oh-my-zsh.sh"
t_true "omz is not installed under ZDOTDIR" test ! -e "$tmp/zdot/ohmyzsh"

# Brew packages, apps and CLIs.
fresh; install >/dev/null
for f in zsh-syntax-highlighting zsh-autosuggestions zsh-completions grep; do
  t_out "formula $f installed" "brew install -q $f\$" calls
done
t_true "share dirs lose group write" bash -c '[ "$(stat -f %Sp "$1/share" | cut -c6)" = "-" ]' _ "$SETUP_BREW_PREFIX"
t_out "font cask installed" 'brew install -q --cask font-meslo-for-powerlevel10k' calls
t_out "vs code installed" 'brew install -q --cask visual-studio-code' calls
t_out "grok installer fetched" 'curl .*x\.ai/cli/install\.sh' calls
fresh; mkdir -p "$HOME/Library/Fonts"; touch "$HOME/Library/Fonts/MesloLGS NF Regular.ttf"
t_out "font present is skipped" 'MesloLGS NF already in ~/Library/Fonts\s+skip' install
fresh; mkdir -p "$SETUP_APPS_DIR/iTerm.app"; install > "$tmp/out"
t_out "dmg-installed app is adopted" 'brew install -q --cask --adopt iterm2' calls
t_out "adopt shows in output" 'iTerm2.*\s+adopt' cat "$tmp/out"
fresh; mkdir -p "$SETUP_APPS_DIR/iTerm.app"; STUB_BREW_FAIL=iterm2 install > "$tmp/out" 2>&1
t_no_out "failed adopt is not retried with force" 'brew install .*--force' calls
t_out "failed adopt shows brew's own error" 'iTerm2.*FAIL\n\n.*brew install -q --cask --adopt iterm2 exited 1\.' cat "$tmp/out"
fresh; mkdir -p "$tmp/node_modules/codex/bin" "$SETUP_BREW_PREFIX/bin"; touch "$tmp/node_modules/codex/bin/codex"
ln -s "$tmp/node_modules/codex/bin/codex" "$SETUP_BREW_PREFIX/bin/codex"; install > "$tmp/out"
t_true "occupied bin path: brew cask gets it" bash -c '[ -f "$1/bin/codex" ] && [ ! -L "$1/bin/codex" ]' _ "$SETUP_BREW_PREFIX"
t_true "occupied bin path: old link moved aside, not deleted" bash -c 'ls "$1"/.setup-macos/replaced/codex-* >/dev/null 2>&1 && [ -e "$2/node_modules/codex/bin/codex" ]' _ "$HOME" "$tmp"
t_out "occupied bin path listed as earlier install" "codex\s+$tmp/node_modules/codex/bin/codex\s+moved out of brew" cat "$tmp/out"
fresh; mkdir -p "$SETUP_BREW_PREFIX/Caskroom/codex/0.1/bin" "$SETUP_BREW_PREFIX/bin"; printf '#!/bin/sh\n# stub cask codex\n' > "$SETUP_BREW_PREFIX/Caskroom/codex/0.1/bin/codex"
ln -s "$SETUP_BREW_PREFIX/Caskroom/codex/0.1/bin/codex" "$SETUP_BREW_PREFIX/bin/codex"; install >/dev/null
t_true "brew's own link is not moved aside" test ! -e "$HOME/.setup-macos/replaced"
t_out "brew's own link: cask still installed" 'brew install -q --cask codex' calls
fresh; printf 'cask:claude-code\n' > "$STUB_BREW_STATE"; install >/dev/null
t_out "conflicting cask replaced" 'brew uninstall -q --cask claude-code\n(.*\n)*brew install -q --cask claude-code@latest' calls
fresh; mkdir -p "$tmp/npm"; touch "$tmp/npm/codex" "$tmp/npm/conda"; chmod +x "$tmp/npm/codex" "$tmp/npm/conda"
EXTRA_PATH="$tmp/npm" install > "$tmp/out"
t_out "npm codex listed as left in place" "codex\s+$tmp/npm/codex\s+brew version is first on PATH" cat "$tmp/out"
t_out "other conda listed as left in place" "conda\s+$tmp/npm/conda\s+brew version is first on PATH" cat "$tmp/out"
fresh; STUB_BREW_FAIL=codex t_exit "failed cask stops the run" 1 install
fresh; STUB_BREW_FAIL=codex t_out "failure shows log tail and path" 'codex\s+FAIL\n\n.*brew install.*exited 1\..*\n(\s+│.*\n){1,3}\s+Full log: .*setup\.log\n\s+Fix the problem and run the same command again' install
fresh; STUB_BREW_FAIL=codex install >/dev/null 2>&1; : > "$STUB_LOG"; install >/dev/null
t_out "failed cask retried on rerun" 'brew install -q --cask codex' calls
t_no_out "finished steps not redone on rerun" 'brew install -q --cask miniconda' calls

# Dotfiles, iTerm2 profile, summary, reruns.
fresh; install > "$tmp/out"
t_true "zshrc equals template" cmp -s "$setup/zshrc" "$HOME/.zshrc"
t_true "p10k equals template" cmp -s "$setup/p10k.zsh" "$HOME/.p10k.zsh"
t_true "iterm profile installed" cmp -s "$setup/iterm2-profile.json" "$HOME/Library/Application Support/iTerm2/DynamicProfiles/workflow.json"
t_out "default profile set" 'defaults write com\.googlecode\.iterm2 Default Bookmark Guid -string 9B8C7E2A-4F31-4C5D-A6E0-2D7F5B3C9A11' calls
t_true "zprofile has one shellenv line" bash -c '[ "$(grep -c "brew shellenv" "$1")" = 1 ]' _ "$HOME/.zprofile"
t_true "default mode writes no mirror block" bash -c 'test -f "$1" && ! grep -q "homebrew mirror" "$1"' _ "$HOME/.zprofile"
t_out "dotfiles banner" '==> \[10/10\] Dotfiles' cat "$tmp/out"
t_out "summary counts" '==> Done in \d+m\d\ds\. \d+ installed, \d+ already in place\.' cat "$tmp/out"
t_out "next steps listed" 'Next:\n\s+1\. Quit Terminal and open iTerm2\.\n\s+2\. claude.*\n\s+3\. codex login.*\n\s+4\. grok.*' cat "$tmp/out"
: > "$STUB_LOG"; install > "$tmp/out2"
t_true "second run makes no backup" bash -c '! ls "$1"/.zshrc.backup-* "$1"/.p10k.zsh.backup-* 2>/dev/null' _ "$HOME"
t_no_out "second run installs nothing" 'brew install|brew uninstall|git clone|softwareupdate -i|defaults write' calls
t_true "second run keeps one shellenv line" bash -c '[ "$(grep -c "brew shellenv" "$1")" = 1 ]' _ "$HOME/.zprofile"
t_out "second run says everything is in place" ' 0 installed, \d+ already in place' cat "$tmp/out2"
fresh; printf 'export OLD=1\n' > "$HOME/.zshrc"; install > "$tmp/out"
t_true "different zshrc is backed up" bash -c 'ls "$1"/.zshrc.backup-* >/dev/null 2>&1' _ "$HOME"
t_out "backup path appears in summary" 'Backups:\n\s+.*/\.zshrc\.backup-\d{8}-\d{6}' cat "$tmp/out"
t_true "old content is in the backup" bash -c 'grep -q "export OLD=1" "$1"/.zshrc.backup-*' _ "$HOME"
t_true "backup taken before installers ran" bash -c 'ls "$1"/.zshrc.backup-* >/dev/null 2>&1 && ! grep -q "grok installer" "$1"/.zshrc.backup-*' _ "$HOME"
t_true "only one backup per file" bash -c '[ "$(ls "$1"/.zshrc.backup-* | wc -l)" -eq 1 ]' _ "$HOME"
t_true "installer edits are gone from the final zshrc" cmp -s "$setup/zshrc" "$HOME/.zshrc"
fresh; printf 'export OLD=1\n' > "$HOME/.zshrc"; rm "$tmp/http/https___raw.githubusercontent.com_Homebrew_install_HEAD_install.sh"; install >/dev/null 2>&1
t_true "backup exists before the first installer runs" bash -c 'grep -q "export OLD=1" "$1"/.zshrc.backup-*' _ "$HOME"
fresh; install >/dev/null
t_true "no zshrc before means no backup" bash -c '! ls "$1"/.zshrc.backup-* 2>/dev/null' _ "$HOME"
fresh; mkdir -p "$tmp/dotfiles"; printf 'export OLD=1\n' > "$tmp/dotfiles/zshrc"; ln -s "$tmp/dotfiles/zshrc" "$HOME/.zshrc"; install >/dev/null
t_true "symlinked zshrc: the link is replaced, its target untouched" bash -c '[ ! -L "$1/.zshrc" ] && cmp -s "$2" "$1/.zshrc" && grep -q "export OLD=1" "$3/dotfiles/zshrc"' _ "$HOME" "$setup/zshrc" "$tmp"
t_true "symlinked zshrc: old content backed up" bash -c 'grep -q "export OLD=1" "$1"/.zshrc.backup-*' _ "$HOME"
fresh; cp "$setup/zshrc" "$HOME/.zshrc"; install >/dev/null
t_true "identical zshrc is not backed up" bash -c '! ls "$1"/.zshrc.backup-* 2>/dev/null' _ "$HOME"
fresh; printf 'export OLD=1\n' > "$HOME/.zshrc"; STUB_BREW_FAIL=codex install >/dev/null 2>&1
t_true "failed run keeps the person's zshrc and its backup" bash -c 'grep -q "export OLD=1" "$1/.zshrc" && grep -q "export OLD=1" "$1"/.zshrc.backup-*' _ "$HOME"
fresh; STUB_BREW_FAIL=codex install >/dev/null 2>&1
t_true "failed run on a fresh Mac leaves omz's zshrc, no backup" bash -c 'grep -q "omz template" "$1/.zshrc" && ! ls "$1"/.zshrc.backup-* >/dev/null 2>&1' _ "$HOME"
fresh; printf 'eval $(/opt/homebrew/bin/brew shellenv)\n' > "$HOME/.zprofile"; install >/dev/null
t_true "shellenv line already present with different quoting" bash -c '[ "$(grep -c "brew shellenv" "$1")" = 1 ]' _ "$HOME/.zprofile"
fresh; printf 'eval "$(/usr/local/bin/brew shellenv)"\n' > "$HOME/.zprofile"; install >/dev/null
t_true "intel brew line does not count" bash -c '[ "$(grep -c "/opt/homebrew/bin/brew shellenv" "$1")" = 1 ]' _ "$HOME/.zprofile"
fresh; printf '# eval "$(/opt/homebrew/bin/brew shellenv)"\n' > "$HOME/.zprofile"; install >/dev/null
t_true "commented shellenv line does not count" bash -c '[ "$(grep -c "^eval.*/opt/homebrew/bin/brew shellenv" "$1")" = 1 ]' _ "$HOME/.zprofile"
fresh; SETUP_MIRROR=jsdelivr install >/dev/null
t_out "mirror block written once" '# >>> setup/macos: homebrew mirror >>>\nexport HOMEBREW_BREW_GIT_REMOTE=.*\nexport HOMEBREW_API_DOMAIN=.*\nexport HOMEBREW_BOTTLE_DOMAIN=.*\n# <<< setup/macos: homebrew mirror <<<' cat "$HOME/.zprofile"
SETUP_MIRROR=jsdelivr install >/dev/null
t_true "mirror block not duplicated" bash -c '[ "$(grep -c "homebrew mirror >>>" "$1")" = 1 ]' _ "$HOME/.zprofile"
fresh; printf 'eval "$(/opt/homebrew/bin/brew shellenv)"' > "$HOME/.zprofile"; SETUP_MIRROR=jsdelivr install >/dev/null
t_out "mirror block starts on its own line after a file without trailing newline" 'shellenv\)"\n# >>> setup/macos: homebrew mirror >>>' cat "$HOME/.zprofile"
fresh; SETUP_MIRROR=jsdelivr HOMEBREW_API_DOMAIN=https://example.test/api install >/dev/null
t_out "mirror block keeps a preset value" 'export HOMEBREW_API_DOMAIN="https://example\.test/api"' cat "$HOME/.zprofile"
fresh; STUB_ITERM_RUNNING=1 install > "$tmp/out"
t_no_out "running iTerm2 keeps its default" 'defaults write' calls
t_out "running iTerm2 is explained" 'iTerm2 is running, not changing its default profile' cat "$tmp/out"
fresh; SHELL=/bin/bash t_out "non-zsh login shell gets a hint" 'login shell is bash; run: chsh -s /bin/zsh' install
fresh; printf 'export STRAY=1\n' > "$tmp/zshrc"; install_piped >/dev/null
t_true "stray zshrc in cwd is not used" cmp -s "$setup/zshrc" "$HOME/.zshrc"
t_out "piped run fetches templates from github" 'curl .*raw\.githubusercontent\.com/etherfunlab/workflow/main/setup/macos/zshrc' calls
fresh; SETUP_MIRROR=jsdelivr install_piped >/dev/null
t_out "mirror run fetches templates from jsDelivr" 'curl .*cdn\.jsdelivr\.net/gh/etherfunlab/workflow@main/setup/macos/zshrc' calls
t_no_out "mirror run never asks raw.githubusercontent.com for templates" 'raw\.githubusercontent\.com/etherfunlab' calls

# --no-gui: no iTerm2, VS Code, font or iTerm2 profile; everything else as before.
fresh; t_exit "unknown option exits 1" 1 install --bogus
t_out "unknown option says which" 'Unknown option: --bogus' install --bogus
t_true "unknown option wrote nothing" test ! -e "$HOME/.zshrc" -a ! -e "$SETUP_LOG"
fresh; install --no-gui > "$tmp/out"
t_true "no-gui exits 0" bash -c 'grep -q "==> Done" "$1"' _ "$tmp/out"
t_no_out "no-gui installs no GUI cask" 'brew install .*(iterm2|visual-studio-code|font-)' calls
t_out "no-gui still installs the CLIs" 'brew install -q --cask miniconda\n(.*\n)*brew install -q --cask claude-code@latest\n(.*\n)*brew install -q --cask codex' calls
t_true "no-gui writes no iTerm2 profile" test ! -e "$HOME/Library/Application Support/iTerm2"
t_no_out "no-gui leaves iTerm2 defaults alone" 'defaults write' calls
t_out "no-gui header says so" 'mode  default, no GUI' cat "$tmp/out"
t_out "no-gui counts eight steps" '==> \[ 1/8\] Preflight\n(.*\n)*==> \[ 8/8\] Dotfiles' cat "$tmp/out"
t_no_out "no-gui has no Fonts or Apps banner" '==> \[ ?\d/8\] (Fonts|Apps)' cat "$tmp/out"
t_out "no-gui next steps open a terminal, not iTerm2" 'Next:\n\s+1\. Open a new terminal window\.\n\s+2\. claude' cat "$tmp/out"
t_no_out "no-gui next steps do not mention iTerm2" 'Next:(.*\n)*.*iTerm2' cat "$tmp/out"
t_true "no-gui zshrc equals template" cmp -s "$setup/zshrc" "$HOME/.zshrc"
: > "$STUB_LOG"; install --no-gui > "$tmp/out2"
t_no_out "no-gui second run installs nothing" 'brew install|brew uninstall|git clone|softwareupdate -i|defaults write' calls
t_out "no-gui second run says everything is in place" ' 0 installed, \d+ already in place' cat "$tmp/out2"
fresh; SETUP_MIRROR=jsdelivr install --no-gui > "$tmp/out"
t_out "no-gui mirror header names both" 'mode  mirror: jsDelivr \+ Homebrew mirror, no GUI' cat "$tmp/out"
fresh; install_piped --no-gui >/dev/null
t_no_out "no-gui does not fetch the iTerm2 profile" 'curl .*iterm2-profile\.json' calls
t_out "no-gui piped run still fetches zshrc" 'curl .*setup/macos/zshrc' calls
fresh; mkdir -p "$SETUP_BREW_PREFIX/bin"; cp "$STUB_DIR/brew" "$SETUP_BREW_PREFIX/bin/brew"; printf 'cask:iterm2@beta\n' > "$STUB_BREW_STATE"
t_exit "no-gui ignores an iterm2@beta install" 0 install --no-gui
fresh; mkdir -p "$SETUP_BREW_PREFIX/bin"; cp "$STUB_DIR/brew" "$SETUP_BREW_PREFIX/bin/brew"; printf 'cask:iterm2@beta\n' > "$STUB_BREW_STATE"
t_exit "default mode still stops on iterm2@beta" 1 install

# CI: the workflow runs install.sh --no-gui on a macOS runner.
wf="$root/.github/workflows/setup-macos.yml"
t_exit "workflow is YAML" 0 ruby -ryaml -e 'YAML.load_file(ARGV[0])' "$wf"
t_true "workflow triggers on push to main" ruby -ryaml -e 'w = YAML.load_file(ARGV[0]); exit((w["on"] || w[true])["push"]["branches"] == ["main"] ? 0 : 1)' "$wf"
t_true "workflow watches setup/macos" ruby -ryaml -e 'w = YAML.load_file(ARGV[0]); exit((w["on"] || w[true])["push"]["paths"].include?("setup/macos/**") ? 0 : 1)' "$wf"
t_true "workflow runs on macOS" ruby -ryaml -e 'w = YAML.load_file(ARGV[0]); exit(w["jobs"].values.all? { |j| j["runs-on"].to_s.start_with?("macos") } ? 0 : 1)' "$wf"
wf_runs() { ruby -ryaml -e 'w = YAML.load_file(ARGV[0]); puts w["jobs"].values.flat_map { |j| j["steps"] }.map { |s| s["run"] }.compact.join("\n")' "$wf"; }
# Every install.sh invocation in a run: block, and there is at least one, passes --no-gui.
wf_gui_free() { local l; l=$(wf_runs | grep 'install\.sh') && [ -n "$l" ] && ! printf '%s\n' "$l" | grep -qv -- '--no-gui'; }
t_out "workflow runs install.sh --no-gui" '^\s*bash setup/macos/install\.sh --no-gui' wf_runs
t_true "workflow never runs the GUI mode" wf_gui_free
fresh; rm "$tmp/http/https___raw.githubusercontent.com_etherfunlab_workflow_main_setup_macos_p10k.zsh"
t_exit "unreachable template exits 1" 1 install_piped
t_out "unreachable template is named" 'template p10k\.zsh\s+FAIL' install_piped
t_true "unreachable template stops before installing anything" bash -c '! grep -qE "brew-install|softwareupdate -i|git clone|brew install" "$1"' _ "$STUB_LOG"

t_done setup-macos
