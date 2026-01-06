# Starship prompt
command -v starship >/dev/null || return

if [[ -n "$ZSH_VERSION" ]]; then
  eval "$(starship init zsh)"
elif [[ -n "$BASH_VERSION" ]]; then
  eval "$(starship init bash)"
fi
