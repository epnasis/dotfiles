[ -f ~/.bash_profile ] && . ~/.bash_profile


[ -f ~/.fzf.bash ] && source ~/.fzf.bash
. "$HOME/.cargo/env"

# Safe rm function (moves to trash instead of permanent delete)
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
[ -f "$DOTFILES_DIR/functions/safe_rm.zsh" ] && source "$DOTFILES_DIR/functions/safe_rm.zsh"
