command -v tmux >/dev/null || return

# tmux host syncing env from connecting client
_sync_ssh_env() {
	if [ -n "$TMUX" ]; then
		# Query the session-local environment (Latest Client Wins)
		local LATEST_SOCK
		LATEST_SOCK=$(tmux show-environment SSH_AUTH_SOCK 2>/dev/null | cut -d= -f2)

		# [+] Only update if a valid socket is found and it differs from current
		if [ -n "$LATEST_SOCK" ] && [ "$LATEST_SOCK" != "$SSH_AUTH_SOCK" ] && [[ "$LATEST_SOCK" != *"unknown variable"* ]]; then
			export SSH_AUTH_SOCK="$LATEST_SOCK"
		fi
	fi
}

# [+] Register the Signal Trap (Instant sync on attach)
trap _sync_ssh_env SIGUSR1

# [+] Register Shell Hooks (Sync before every command)
if [ -n "$ZSH_VERSION" ]; then
	autoload -Uz add-zsh-hook
	add-zsh-hook precmd _sync_ssh_env
elif [ -n "$BASH_VERSION" ]; then
	if [[ ! "$PROMPT_COMMAND" =~ "_sync_ssh_env" ]]; then
		PROMPT_COMMAND="_sync_ssh_env${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
	fi
fi

# Auto-start tmux on SSH sessions
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && [[ $- == *i* ]]; then
	tmux set-environment -g SSH_AUTH_SOCK "$SSH_AUTH_SOCK" 2>/dev/null
	tmux set-environment -g SSH_CLIENT "$SSH_CLIENT" 2>/dev/null
	tmux set-environment -g SSH_CONNECTION "$SSH_CONNECTION" 2>/dev/null
	tmux new-session -A -s main && exit 0
fi
