ZSH=${ZSH:-${ZDOTDIR:+$ZDOTDIR/ohmyzsh}}; ZSH=${ZSH:-$HOME/.oh-my-zsh}
[ -d "$ZSH" ] && { echo "The \$ZSH folder already exists ($ZSH)." >&2; exit 1; }
url=${REMOTE:-https://github.com/ohmyzsh/ohmyzsh.git}
case "$url" in ${STUB_GIT_FAIL:-^}) echo "Error: git clone of oh-my-zsh repo failed" >&2; exit 1 ;; esac
mkdir -p "$ZSH/.git" "$ZSH/custom/themes"; echo "# omz" > "$ZSH/oh-my-zsh.sh"
[ -f "$HOME/.zshrc" ] || echo "# omz template" > "$HOME/.zshrc"
