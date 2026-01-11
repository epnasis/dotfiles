# 1Password CLI
command -v op >/dev/null || return

# SSH agent for forwarding keys
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

if [[ -n "$ZSH_VERSION" ]]; then
  eval "$(op completion zsh)"
  compdef _op op
elif [[ -n "$BASH_VERSION" ]]; then
  eval "$(op completion bash)"
fi

# 1Password plugins
[[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"
