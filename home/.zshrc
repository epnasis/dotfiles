# --- dotfiles ---
for f in ~/.shell.d/*.sh; do [[ -f "$f" ]] && . "$f"; done
# --- end dotfiles ---

# Machine-specific config (not in dotfiles)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
