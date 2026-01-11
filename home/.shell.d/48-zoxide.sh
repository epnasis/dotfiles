# zoxide init
command -v zoxide >/dev/null || return

eval "$(zoxide init --cmd j zsh)"
