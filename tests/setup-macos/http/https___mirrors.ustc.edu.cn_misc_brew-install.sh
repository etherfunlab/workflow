mkdir -p "$SETUP_BREW_PREFIX/bin" "$SETUP_BREW_PREFIX/share/zsh"
chmod 775 "$SETUP_BREW_PREFIX/share"
printf '#!/bin/sh\nexec "%s/brew" "$@"\n' "$STUB_DIR" > "$SETUP_BREW_PREFIX/bin/brew"
chmod +x "$SETUP_BREW_PREFIX/bin/brew"
