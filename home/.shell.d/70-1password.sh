# 1Password CLI
command -v op >/dev/null || return

# SSH agent for forwarding keys
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

if [[ -n "$ZSH_VERSION" ]]; then
	OP_COMPLETION_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/op_completion.zsh"
	if [[ ! -f "$OP_COMPLETION_CACHE" ]]; then
		mkdir -p "$(dirname "$OP_COMPLETION_CACHE")"
		op completion zsh > "$OP_COMPLETION_CACHE"
	fi
	source "$OP_COMPLETION_CACHE"
	compdef _op op
elif [[ -n "$BASH_VERSION" ]]; then
	eval "$(op completion bash)"
fi

# 1Password plugins
[[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"
