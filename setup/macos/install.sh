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
TOTAL=10
N_DONE=0 N_SKIP=0 N_ADOPT=0
KEEPALIVE=

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

cleanup() { [ -z "$KEEPALIVE" ] || kill "$KEEPALIVE" 2>/dev/null || true; }

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

main() {
  case "$SETUP_MIRROR" in
    "" | jsdelivr) ;;
    *) echo "SETUP_MIRROR must be empty or jsdelivr, got: $SETUP_MIRROR" >&2; exit 1 ;;
  esac
  trap cleanup EXIT
  say_header
  step_preflight
}

main "$@"
