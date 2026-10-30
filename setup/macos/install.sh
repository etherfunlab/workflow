#!/bin/bash
# Sets up an Apple Silicon Mac for building with agents: Homebrew, oh-my-zsh
# with powerlevel10k, brew-installed zsh plugins, iTerm2 and VS Code, miniconda,
# Claude Code, Codex and Grok CLI, then ~/.zshrc, ~/.p10k.zsh and ~/.zprofile.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/etherfunlab/workflow/main/setup/macos/install.sh)"
#
# Weak network: this repo's files come from jsDelivr, Homebrew from the USTC
# mirror, oh-my-zsh from the gitee mirror when GitHub fails, and powerlevel10k
# from jsDelivr at a pinned commit.
#
#   SETUP_MIRROR=jsdelivr /bin/bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/etherfunlab/workflow@main/setup/macos/install.sh)"
#
# No GUI: skips iTerm2, VS Code, the font and the iTerm2 profile. The "-" fills
# $0 so that --no-gui reaches the script.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/etherfunlab/workflow/main/setup/macos/install.sh)" - --no-gui
#
# Asks for the sudo password once. Safe to rerun: finished steps are skipped.
set -eEuo pipefail

SETUP_MIRROR="${SETUP_MIRROR:-}"
NO_GUI=
# Empty under `bash -c "$(curl …)"`; set when run from a clone.
SCRIPT_SRC="${BASH_SOURCE[0]:-}"
REPO_RAW=https://raw.githubusercontent.com/etherfunlab/workflow/main/setup/macos
REPO_CDN=https://cdn.jsdelivr.net/gh/etherfunlab/workflow@main/setup/macos
BREW_PREFIX="${SETUP_BREW_PREFIX:-/opt/homebrew}"
APPS_DIR="${SETUP_APPS_DIR:-/Applications}"
LOG="${SETUP_LOG:-$HOME/.setup-macos/$(date +%Y%m%d-%H%M%S).log}"
# Its presence makes softwareupdate list the Command Line Tools without a dialog.
CLT_FLAG="${SETUP_CLT_FLAG:-/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress}"
# jsDelivr cannot resolve a branch to a commit, so mirror mode pins powerlevel10k
# here. Bump by hand after checking that master installs from jsDelivr.
P10K_COMMIT="${SETUP_P10K_COMMIT:-d05a1b00f9a61f9578bf9dc19b8451942dde8734}"
P10K_CDN=https://cdn.jsdelivr.net/gh/romkatv/powerlevel10k
P10K_LIST=https://data.jsdelivr.com/v1/packages/gh/romkatv/powerlevel10k
ZSH_CUSTOM_DIR="$HOME/.oh-my-zsh/custom"
TOTAL=10 STEP=0
N_DONE=0 N_SKIP=0 N_ADOPT=0
KEEPALIVE= WORK= LAST_CMD= LAST_RC=0 START=$SECONDS
# For the summary: earlier installs as "what|where|note" lines, backup paths as lines.
EARLIER= BACKUPS=

# Output: ANSI 16 colors only, so the person's terminal theme decides the shades.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$'\033[1m' DIM=$'\033[2m' RED=$'\033[31m' GREEN=$'\033[32m' YELLOW=$'\033[33m' BLUE=$'\033[34m' RESET=$'\033[0m'
else
  BOLD= DIM= RED= GREEN= YELLOW= BLUE= RESET=
fi

tilde() { case $1 in "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }

die() { printf '    %s%s%s\n' "$RED$BOLD" "$1" "$RESET" >&2; exit 1; }

say_header() {
  local mode=default
  [ "$SETUP_MIRROR" = jsdelivr ] && mode="mirror: jsDelivr + Homebrew mirror"
  [ -z "$NO_GUI" ] || mode="$mode, no GUI"
  printf '%s==>%s %smacOS setup%s  %setherfunlab/workflow%s\n' "$BLUE$BOLD" "$RESET" "$BOLD" "$RESET" "$DIM" "$RESET"
  printf '    mode  %s\n' "$mode"
  printf '    log   %s\n' "$(tilde "$LOG")"
}

# say_banner <title>: numbers the steps in the order they run.
say_banner() {
  STEP=$((STEP + 1))
  printf '%s==>%s %s[%2d/%d] %s%s\n' "$BLUE$BOLD" "$RESET" "$BOLD" "$STEP" "$TOTAL" "$1" "$RESET"
}

fmt_secs() { printf '%dm%02ds' $(($1 / 60)) $(($1 % 60)); }

# say_item <description> <ok|done|skip|adopt|FAIL> [seconds]
say_item() {
  local desc=$1 status=$2 secs=${3:-0} color=
  case $status in
    ok) color=$GREEN ;;
    done) color=$GREEN; N_DONE=$((N_DONE + 1)) ;;
    skip) color=$DIM; N_SKIP=$((N_SKIP + 1)) ;;
    adopt) color=$YELLOW; N_ADOPT=$((N_ADOPT + 1)) ;;
    FAIL) color=$RED$BOLD ;;
  esac
  if [ "$secs" -ge 5 ]; then
    printf '    %-62s %s%-5s%s %s%6s%s\n' "$desc" "$color" "$status" "$RESET" "$DIM" "$(fmt_secs "$secs")" "$RESET"
  else
    printf '    %-62s %s%s%s\n' "$desc" "$color" "$status" "$RESET"
  fi
}

# run <cmd...>: output goes to the log only. Callers check the status.
run() {
  LAST_CMD="$*"
  printf '+ %s\n' "$*" >> "$LOG"
  LAST_RC=0
  "$@" >> "$LOG" 2>&1 || LAST_RC=$?
  return "$LAST_RC"
}

say_notice() { printf '    %s%s%s\n' "$YELLOW" "$1" "$RESET"; }

# say_fail [headline]: after an item line marked FAIL, show the end of the log
# and stop. The headline defaults to the last command run and its status.
say_fail() {
  printf '\n    %s%s%s Last lines of the log:\n' "$RED$BOLD" "${1:-$LAST_CMD exited $LAST_RC.}" "$RESET"
  tail -n 3 "$LOG" | while IFS= read -r line; do printf '    %s│ %s%s\n' "$DIM" "$line" "$RESET"; done
  printf '    Full log: %s\n' "$(tilde "$LOG")"
  printf '    Fix the problem and run the same command again. Finished steps are skipped.\n'
  exit 1
}

# For commands that fail outside `run` (cp, mv, chmod, sudo -v): say what failed
# and where the log is instead of dying with a bare error.
on_err() {
  printf '\n    %s%s failed.%s\n    Full log: %s\n' "$RED$BOLD" "$BASH_COMMAND" "$RESET" "$(tilde "$LOG")" >&2
  exit 1
}

cleanup() {
  [ -z "$KEEPALIVE" ] || kill "$KEEPALIVE" 2>/dev/null || true
  [ -z "$WORK" ] || rm -rf "$WORK"
}

step_preflight() {
  say_banner Preflight
  [ "$(uname -s)" = Darwin ] || die "This script is for macOS."
  [ "$(uname -m)" = arm64 ] || die "This script needs an Apple Silicon Mac (arm64)."
  [ "$(id -u)" != 0 ] || die "Run this as your own user, not root; it asks for sudo when it needs it."
  check_cask_conflicts
  (umask 077; mkdir -p "$(dirname "$LOG")"; : >> "$LOG"; chmod 600 "$LOG")
  sudo -v
  # Keep the sudo timestamp fresh until this script exits.
  (trap - ERR EXIT; while kill -0 "$$" 2>/dev/null; do sudo -n true || true; sleep 50; done) >/dev/null 2>&1 &
  KEEPALIVE=$!
  disown "$KEEPALIVE" # no "Terminated" notice when cleanup kills it
  say_item "macOS $(sw_vers -productVersion), arm64, not root" ok
}

# Homebrew refuses a cask whose conflicts_with cask is installed, --force or
# not, and removing the conflicting one would take the person's data with it.
check_cask_conflicts() {
  [ -x "$BREW_PREFIX/bin/brew" ] || return 0
  local pairs=miniforge:miniconda pair c
  [ -n "$NO_GUI" ] || pairs="$pairs iterm2@beta:iterm2 iterm2@nightly:iterm2"
  for pair in $pairs; do
    c=${pair%%:*}
    if "$BREW_PREFIX/bin/brew" list --cask "$c" >/dev/null 2>&1; then
      die "Cask $c is installed and conflicts with ${pair#*:}, which this script installs. Decide what to keep, then run it again."
    fi
  done
}

# fetch_template <name>: into $WORK, from beside this script in a clone, else
# from GitHub or (mirror mode) jsDelivr.
fetch_template() {
  local here=
  [ -z "$SCRIPT_SRC" ] || here="$(dirname "$SCRIPT_SRC")/$1"
  if [ -n "$here" ] && [ -f "$here" ]; then cp "$here" "$WORK/$1"; return; fi
  local base=$REPO_RAW
  [ "$SETUP_MIRROR" != jsdelivr ] || base=$REPO_CDN
  run curl -fsSL -o "$WORK/$1" "$base/$1"
}

# move_aside <dir> <label>: a directory in the way (an interrupted clone, say) is
# renamed, listed under Backups, and reinstalled.
move_aside() {
  local b="$1.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$1" "$b"
  BACKUPS="$BACKUPS$(tilde "$b")"$'\n'
  say_notice "$2 is incomplete, moved to $(tilde "$b")"
}

# backup_if_changed <template> <file>
backup_if_changed() {
  [ -f "$2" ] || return 0
  if cmp -s "$1" "$2"; then return 0; fi
  local b
  b="$2.backup-$(date +%Y%m%d-%H%M%S)"
  cp -p "$2" "$b"
  BACKUPS="$BACKUPS$(tilde "$b")"$'\n'
  say_item "backup $(tilde "$2") → $(tilde "$b")" ok
}

# Runs right after preflight: templates are fetched before anything is
# installed, and backups are taken before any installer appends to ~/.zshrc.
prepare_dotfiles() {
  local f files="zshrc p10k.zsh"
  [ -n "$NO_GUI" ] || files="$files iterm2-profile.json"
  for f in $files; do
    fetch_template "$f" || { say_item "template $f" FAIL; say_fail; }
  done
  backup_if_changed "$WORK/zshrc" "$HOME/.zshrc"
  backup_if_changed "$WORK/p10k.zsh" "$HOME/.p10k.zsh"
}

step_clt() {
  say_banner "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then say_item "already installed" skip; return; fi
  local label t=$SECONDS
  touch "$CLT_FLAG"
  # Same pipeline as Homebrew's installer: labels read "Command Line Tools for
  # Xcode 26.4-26.4.1" today and "…Xcode-16.0" on older systems.
  printf '+ softwareupdate -l\n' >> "$LOG"
  label=$(softwareupdate -l 2>&1 | tee -a "$LOG" | grep -B1 -E 'Command Line Tools' | awk -F'*' '/^ *\*/ {print $2}' |
    sed -e 's/^ *Label: //' -e 's/^ *//' | grep -vi beta | sort -V | tail -n 1 || true)
  if [ -z "$label" ]; then
    rm -f "$CLT_FLAG"; LAST_CMD="softwareupdate -l" LAST_RC=1
    say_item "no Command Line Tools offered by softwareupdate" FAIL; say_fail
  fi
  if ! run sudo softwareupdate -i "$label"; then rm -f "$CLT_FLAG"; say_item "$label" FAIL; say_fail; fi
  rm -f "$CLT_FLAG"
  say_item "$label" done $((SECONDS - t))
}

# Mirror mode points Homebrew at USTC; values the person already set win.
brew_env() {
  export NONINTERACTIVE=1
  if [ "$SETUP_MIRROR" = jsdelivr ]; then
    export HOMEBREW_BREW_GIT_REMOTE="${HOMEBREW_BREW_GIT_REMOTE:-https://mirrors.ustc.edu.cn/brew.git}"
    export HOMEBREW_API_DOMAIN="${HOMEBREW_API_DOMAIN:-https://mirrors.ustc.edu.cn/homebrew-bottles/api}"
    export HOMEBREW_BOTTLE_DOMAIN="${HOMEBREW_BOTTLE_DOMAIN:-https://mirrors.ustc.edu.cn/homebrew-bottles}"
  fi
  env | grep -E '^HOMEBREW_(BREW_GIT_REMOTE|API_DOMAIN|BOTTLE_DOMAIN)=' >> "$LOG" || true
}

step_homebrew() {
  say_banner Homebrew
  brew_env
  if [ -x "$BREW_PREFIX/bin/brew" ]; then
    say_item "already installed" skip
  else
    local url=https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh t=$SECONDS
    [ "$SETUP_MIRROR" = jsdelivr ] && url=https://mirrors.ustc.edu.cn/misc/brew-install.sh
    if ! run curl -fsSL -o "$WORK/brew-install.sh" "$url" || ! run /bin/bash "$WORK/brew-install.sh"; then
      say_item "installer" FAIL; say_fail
    fi
    say_item "installed to $BREW_PREFIX" done $((SECONDS - t))
  fi
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
}

# omz_install <installer url> [git remote]. The low-speed limit makes a stalled
# clone fail after 30 s instead of hanging.
omz_install() {
  run curl -fsSL -o "$WORK/omz-install.sh" "$1" &&
    run env -u ZDOTDIR ZSH="$HOME/.oh-my-zsh" ${2:+REMOTE=$2} GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=30 \
      sh "$WORK/omz-install.sh" --unattended --keep-zshrc
}

step_omz() {
  say_banner oh-my-zsh
  if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then say_item "already installed" skip; return; fi
  [ ! -e "$HOME/.oh-my-zsh" ] || move_aside "$HOME/.oh-my-zsh" "~/.oh-my-zsh"
  local t=$SECONDS
  if [ "$SETUP_MIRROR" != jsdelivr ]; then
    omz_install https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh || { say_item installer FAIL; say_fail; }
    say_item "~/.oh-my-zsh" done $((SECONDS - t))
    return
  fi
  if omz_install https://install.ohmyz.sh/; then say_item "~/.oh-my-zsh" done $((SECONDS - t)); return; fi
  say_notice "github.com timed out or failed, trying the gitee mirror"
  omz_install https://install.ohmyz.sh/ https://gitee.com/mirrors/oh-my-zsh.git || { say_item installer FAIL; say_fail; }
  say_item "cloned from gitee.com/mirrors/oh-my-zsh" done $((SECONDS - t))
}

step_p10k() {
  say_banner powerlevel10k
  local dest="$ZSH_CUSTOM_DIR/themes/powerlevel10k" t=$SECONDS
  if [ -f "$dest/powerlevel10k.zsh-theme" ]; then say_item "already installed" skip; return; fi
  [ ! -e "$dest" ] || move_aside "$dest" "powerlevel10k"
  if [ "$SETUP_MIRROR" != jsdelivr ]; then
    run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$dest" || { say_item "git clone" FAIL; say_fail; }
    say_item "cloned from github.com/romkatv/powerlevel10k" done $((SECONDS - t))
    return
  fi
  # File by file from jsDelivr into a scratch dir; moved into place only when complete.
  local tmp="$WORK/p10k" names name count=0 f
  run curl -fsSL -o "$WORK/p10k.json" "$P10K_LIST@$P10K_COMMIT?structure=flat" || { say_item "file list from jsDelivr" FAIL; say_fail; }
  # Drop everything before "files" so the package's own "name" is not read as a file.
  names=$(tr -d '\n' < "$WORK/p10k.json" | sed 's/.*"files": *\[//' | tr '}' '\n' | sed -n 's/.*"name": *"\([^"]*\)".*/\1/p')
  # A truncated body (a CDN error with HTTP 200) must not install half a theme.
  if [ "$(tr -d '\n\r\t ' < "$WORK/p10k.json" | tail -c 1)" != '}' ] ||
     ! printf '%s\n' "$names" | grep -qx '/powerlevel10k.zsh-theme' ||
     ! printf '%s\n' "$names" | grep -qx '/internal/p10k.zsh'; then
    say_item "file list from jsDelivr" FAIL
    say_fail "The jsDelivr file list for powerlevel10k@$P10K_COMMIT is incomplete."
  fi
  while IFS= read -r name; do
    # Paths come from the network: absolute within the package, plain characters, no "..".
    case $name in
      /*/../* | /../* | */.. | */./* | //* | *[!A-Za-z0-9._/-]* | "") 
        say_item "$name from jsDelivr" FAIL
        say_fail "The jsDelivr file list for powerlevel10k@$P10K_COMMIT has an unsafe path: $name" ;;
    esac
    run curl -fsSL --create-dirs -o "$tmp$name" "$P10K_CDN@$P10K_COMMIT$name" || { say_item "$name from jsDelivr" FAIL; say_fail; }
    count=$((count + 1))
  done <<< "$names"
  for f in build install mbuild; do
    if [ -f "$tmp/gitstatus/$f" ]; then chmod +x "$tmp/gitstatus/$f"; fi
  done
  mkdir -p "$(dirname "$dest")"
  mv "$tmp" "$dest"
  say_item "$count files from jsDelivr @${P10K_COMMIT:0:7}" done $((SECONDS - t))
}

brew_formula() {
  local t=$SECONDS
  if brew list --formula "$1" >/dev/null 2>&1; then say_item "$1" skip; return; fi
  run brew install -q "$1" || { say_item "$1" FAIL; say_fail; }
  say_item "$1" done $((SECONDS - t))
}

# brew_cask <cask> [App.app] [label] [binary]: an app already in APPS_DIR that
# brew did not install is adopted. A binary on the cask's path that is not the
# cask's own (an npm link, say) is moved aside, because brew refuses to replace
# it even with --force; the package it points to stays installed.
brew_cask() {
  local cask=$1 app=${2:-} label=${3:-$1} bin=${4:-} t=$SECONDS adopt= status=done desc path target aside
  desc=$label
  if brew list --cask "$cask" >/dev/null 2>&1; then say_item "$label" skip; return; fi
  if [ -n "$app" ] && [ -e "$APPS_DIR/$app" ]; then
    adopt=--adopt status=adopt
    desc="$label: $(tilde "$APPS_DIR/$app") was not installed by brew"
    EARLIER="$EARLIER$label|$(tilde "$APPS_DIR/$app")|now managed by brew"$'\n'
  fi
  path="$BREW_PREFIX/bin/$bin"
  if [ -n "$bin" ] && { [ -e "$path" ] || [ -L "$path" ]; } && ! brew_owns "$path"; then
    target=$(readlink "$path" || true)
    aside="$HOME/.setup-macos/replaced/$bin-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$(dirname "$aside")"
    mv "$path" "$aside"
    EARLIER="$EARLIER$bin|${target:-$(tilde "$path")}|moved out of brew's way to $(tilde "$aside")"$'\n'
    say_notice "$bin: $(tilde "$path") was not from brew, moved it to $(tilde "$aside")"
  fi
  run brew install -q --cask $adopt "$cask" || { say_item "$desc" FAIL; say_fail; }
  say_item "$desc" $status $((SECONDS - t))
}

# brew_owns <path>: a link into Caskroom or Cellar is Homebrew's; brew sorts
# those out itself.
brew_owns() {
  local t
  t=$(readlink "$1" 2>/dev/null) || return 1
  case $t in "$BREW_PREFIX"/Caskroom/* | "$BREW_PREFIX"/Cellar/* | ../Caskroom/* | ../Cellar/*) return 0 ;; esac
  return 1
}

# note_earlier <command>: a copy outside Homebrew stays where it is; the brew
# one comes first on PATH.
note_earlier() {
  local p
  p=$(command -v "$1" 2>/dev/null) || return 0
  case $p in
    "$BREW_PREFIX"/*) ;;
    *) EARLIER="$EARLIER$1|$(tilde "$p")|brew version is first on PATH"$'\n' ;;
  esac
}

step_zsh_plugins() {
  say_banner "zsh plugins"
  local f
  for f in zsh-syntax-highlighting zsh-autosuggestions zsh-completions grep; do brew_formula "$f"; done
  # compaudit rejects group-writable completion dirs; Homebrew leaves share/ group-writable.
  if [ -d "$BREW_PREFIX/share" ]; then chmod go-w "$BREW_PREFIX/share"; fi
  if [ -d "$BREW_PREFIX/share/zsh" ]; then chmod -R go-w "$BREW_PREFIX/share/zsh"; fi
}

step_fonts() {
  say_banner Fonts
  if [ -f "$HOME/Library/Fonts/MesloLGS NF Regular.ttf" ]; then
    say_item "MesloLGS NF already in ~/Library/Fonts" skip
    return
  fi
  brew_cask font-meslo-for-powerlevel10k "" "MesloLGS NF"
}

step_apps() {
  say_banner Apps
  brew_cask iterm2 iTerm.app iTerm2
  brew_cask visual-studio-code "Visual Studio Code.app" "Visual Studio Code" code
}

step_clis() {
  say_banner CLIs
  brew list --cask miniconda >/dev/null 2>&1 || note_earlier conda
  brew_cask miniconda "" miniconda conda
  if brew list --cask claude-code >/dev/null 2>&1; then
    say_notice "replacing cask claude-code with claude-code@latest"
    run brew uninstall -q --cask claude-code || { say_item claude-code FAIL; say_fail; }
  fi
  brew list --cask claude-code@latest >/dev/null 2>&1 || note_earlier claude
  brew_cask claude-code@latest "" claude-code@latest claude
  brew list --cask codex >/dev/null 2>&1 || note_earlier codex
  brew_cask codex "" codex codex
  local t=$SECONDS
  if [ -x "$HOME/.grok/bin/grok" ]; then
    say_item grok skip
  else
    { run curl -fsSL -o "$WORK/grok-install.sh" https://x.ai/cli/install.sh &&
      run /bin/bash "$WORK/grok-install.sh"; } || { say_item grok FAIL; say_fail; }
    say_item "grok, x.ai installer" done $((SECONDS - t))
  fi
}

# place_file <src> <dest> <label>: no backup here; prepare_dotfiles took it.
place_file() {
  if [ -f "$2" ] && [ ! -L "$2" ] && cmp -s "$1" "$2"; then say_item "$3" skip; return; fi
  mkdir -p "$(dirname "$2")"
  [ ! -L "$2" ] || rm "$2" # a dotfiles-repo link: replace the link, leave its target alone
  cp "$1" "$2"
  say_item "$3" done
}

end_line() { [ ! -s "$1" ] || [ "$(tail -c 1 "$1")" = "" ] || echo >> "$1"; }

ensure_zprofile() {
  local f="$HOME/.zprofile" changed= label="~/.zprofile: brew shellenv"
  [ -e "$f" ] || : > "$f"
  if ! grep -qE '^[^#]*/opt/homebrew/bin/brew[[:space:]]+shellenv' "$f"; then
    end_line "$f"
    printf '\neval "$(/opt/homebrew/bin/brew shellenv)"\n' >> "$f"
    changed=1
  fi
  if [ "$SETUP_MIRROR" = jsdelivr ]; then
    label="$label, mirror block"
    if ! grep -qF '# >>> setup/macos: homebrew mirror >>>' "$f"; then
      end_line "$f"
      {
        printf '# >>> setup/macos: homebrew mirror >>>\n'
        printf 'export HOMEBREW_BREW_GIT_REMOTE="%s"\n' "$HOMEBREW_BREW_GIT_REMOTE"
        printf 'export HOMEBREW_API_DOMAIN="%s"\n' "$HOMEBREW_API_DOMAIN"
        printf 'export HOMEBREW_BOTTLE_DOMAIN="%s"\n' "$HOMEBREW_BOTTLE_DOMAIN"
        printf '# <<< setup/macos: homebrew mirror <<<\n'
      } >> "$f"
      changed=1
    fi
  fi
  if [ -n "$changed" ]; then say_item "$label" done; else say_item "$label" skip; fi
}

# iTerm2 reads "Default Bookmark Guid" at launch, loads dynamic profiles, then
# makes the guid the default when only a dynamic profile has it, so this also
# works before iTerm2's first launch.
install_iterm_profile() {
  local guid
  place_file "$WORK/iterm2-profile.json" "$HOME/Library/Application Support/iTerm2/DynamicProfiles/workflow.json" 'iTerm2 profile "workflow"'
  guid=$(sed -n 's/.*"Guid": *"\([^"]*\)".*/\1/p' "$WORK/iterm2-profile.json")
  if [ "$(defaults read com.googlecode.iterm2 "Default Bookmark Guid" 2>/dev/null || true)" = "$guid" ]; then
    say_item 'iTerm2 default profile is "workflow"' skip
    return
  fi
  if pgrep -x iTerm2 >/dev/null 2>&1; then
    say_notice 'iTerm2 is running, not changing its default profile; pick "workflow" in iTerm2 > Settings > Profiles'
    return
  fi
  run defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$guid" || { say_item "iTerm2 default profile" FAIL; say_fail; }
  say_item 'iTerm2 default profile set to "workflow"' done
}

step_dotfiles() {
  say_banner Dotfiles
  place_file "$WORK/zshrc" "$HOME/.zshrc" "~/.zshrc"
  place_file "$WORK/p10k.zsh" "$HOME/.p10k.zsh" "~/.p10k.zsh"
  ensure_zprofile
  [ -n "$NO_GUI" ] || install_iterm_profile
}

summary() {
  local shell=${SHELL:-}
  shell=${shell##*/}
  printf '%s==>%s %sDone in %s.%s %d installed, %d already in place.\n' "$BLUE$BOLD" "$RESET" "$GREEN$BOLD" \
    "$(fmt_secs $((SECONDS - START)))" "$RESET" $((N_DONE + N_ADOPT)) "$N_SKIP"
  if [ -n "$BACKUPS" ]; then
    printf '    Backups:\n'
    printf '%s' "$BACKUPS" | while IFS= read -r b; do printf '      %s\n' "$b"; done
  fi
  if [ -n "$EARLIER" ]; then
    printf '    Earlier installs found on this Mac:\n'
    printf '%s' "$EARLIER" | while IFS='|' read -r what where note; do
      printf '      %-10s %-40s %s%s%s\n' "$what" "$where" "$DIM" "$note" "$RESET"
    done
  fi
  printf '    Next:\n'
  if [ -n "$NO_GUI" ]; then printf '      1. Open a new terminal window.\n'; else printf '      1. Quit Terminal and open iTerm2.\n'; fi
  printf '      2. claude        sign in when it asks\n'
  printf '      3. codex login\n'
  printf '      4. grok          sign in when it asks\n'
  if [ "$shell" != zsh ]; then printf '      5. Your login shell is %s; run: chsh -s /bin/zsh\n' "$shell"; fi
}

main() {
  local a
  for a in "$@"; do
    case $a in
      --no-gui) NO_GUI=1 TOTAL=8 ;;
      *) printf 'Unknown option: %s\nUsage: install.sh [--no-gui]\n' "$a" >&2; exit 1 ;;
    esac
  done
  case "$SETUP_MIRROR" in
    "" | jsdelivr) ;;
    *) echo "SETUP_MIRROR must be empty or jsdelivr, got: $SETUP_MIRROR" >&2; exit 1 ;;
  esac
  trap cleanup EXIT
  trap on_err ERR
  WORK=$(mktemp -d)
  say_header
  step_preflight
  prepare_dotfiles
  step_clt
  step_homebrew
  step_omz
  step_p10k
  step_zsh_plugins
  if [ -z "$NO_GUI" ]; then
    step_fonts
    step_apps
  fi
  step_clis
  step_dotfiles
  summary
}

main "$@"
