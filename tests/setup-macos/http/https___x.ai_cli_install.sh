mkdir -p "$HOME/.grok/bin"
printf "#!/bin/sh\n" > "$HOME/.grok/bin/grok"; chmod +x "$HOME/.grok/bin/grok"
printf "\n# >>> grok installer >>>\nexport PATH=\"\$HOME/.grok/bin:\$PATH\"\n" >> "$HOME/.zshrc"
