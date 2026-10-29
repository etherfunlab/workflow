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
# Asks for the sudo password once. Safe to rerun: finished steps are skipped.
set -euo pipefail

SETUP_MIRROR="${SETUP_MIRROR:-}"
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
TOTAL=10
N_DONE=0 N_SKIP=0 N_ADOPT=0
KEEPALIVE= WORK= LAST_CMD= LAST_RC=0

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
  printf '%s==>%s %smacOS setup%s  %setherfunlab/workflow%s\n' "$BLUE$BOLD" "$RESET" "$BOLD" "$RESET" "$DIM" "$RESET"
  printf '    mode  %s\n' "$mode"
  printf '    log   %s\n' "$(tilde "$LOG")"
}

# say_banner <n> <title>
say_banner() { printf '%s==>%s %s[%2d/%d] %s%s\n' "$BLUE$BOLD" "$RESET" "$BOLD" "$1" "$TOTAL" "$2" "$RESET"; }

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
    printf '    %-62s %s%-5s%s %s%6s%s\n' "$desc" "$color" "$status" "$RESET" "$DIM" "$((secs / 60))m$(printf %02d $((secs % 60)))s" "$RESET"
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

cleanup() {
  [ -z "$KEEPALIVE" ] || kill "$KEEPALIVE" 2>/dev/null || true
  [ -z "$WORK" ] || rm -rf "$WORK"
}

step_preflight() {
  say_banner 1 Preflight
  [ "$(uname -s)" = Darwin ] || die "This script is for macOS."
  [ "$(uname -m)" = arm64 ] || die "This script needs an Apple Silicon Mac (arm64)."
  [ "$(id -u)" != 0 ] || die "Run this as your own user, not root; it asks for sudo when it needs it."
  mkdir -p "$(dirname "$LOG")"
  : >> "$LOG"
  sudo -v
  # Keep the sudo timestamp fresh until this script exits.
  (while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 50; done) >/dev/null 2>&1 &
  KEEPALIVE=$!
  say_item "macOS $(sw_vers -productVersion), arm64, not root" ok
}

step_clt() {
  say_banner 2 "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then say_item "already installed" skip; return; fi
  local label t=$SECONDS
  touch "$CLT_FLAG"
  label=$(softwareupdate -l 2>/dev/null | sed -n 's/^\* Label: \(Command Line Tools for Xcode-.*\)$/\1/p' | tail -n 1)
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
  env | grep '^HOMEBREW_' >> "$LOG" || true
}

step_homebrew() {
  say_banner 3 Homebrew
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
    run env ${2:+REMOTE=$2} GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=30 \
      sh "$WORK/omz-install.sh" --unattended --keep-zshrc
}

step_omz() {
  say_banner 4 oh-my-zsh
  if [ -d "$HOME/.oh-my-zsh/.git" ]; then say_item "already installed" skip; return; fi
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
  say_banner 5 powerlevel10k
  local dest="$ZSH_CUSTOM_DIR/themes/powerlevel10k" t=$SECONDS
  if [ -d "$dest" ]; then say_item "already installed" skip; return; fi
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
  if [ -z "$names" ]; then
    say_item "file list from jsDelivr" FAIL
    say_fail "The jsDelivr file list for powerlevel10k@$P10K_COMMIT names no files."
  fi
  while IFS= read -r name; do
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

main() {
  case "$SETUP_MIRROR" in
    "" | jsdelivr) ;;
    *) echo "SETUP_MIRROR must be empty or jsdelivr, got: $SETUP_MIRROR" >&2; exit 1 ;;
  esac
  trap cleanup EXIT
  WORK=$(mktemp -d)
  say_header
  step_preflight
  step_clt
  step_homebrew
  step_omz
  step_p10k
}

main "$@"
