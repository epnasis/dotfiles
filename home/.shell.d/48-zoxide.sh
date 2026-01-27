# zoxide init
command -v zoxide >/dev/null || return

if [[ -n "$ZSH_VERSION" ]]; then
  eval "$(zoxide init --cmd j zsh)"
elif [[ -n "$BASH_VERSION" ]]; then
  eval "$(zoxide init --cmd j bash)"
fi
