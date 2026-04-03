command -v tmux >/dev/null || return

# Auto-start tmux on SSH sessions
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && [[ $- == *i* ]]; then
	# Update stable symlink with the forwarded socket sshd gave us.
	# Skip only if SSH_AUTH_SOCK is already pointing at our stable path (nothing new to update)
	# or if unset (agent forwarding not active).
	if [ -n "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock" ]; then
		ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/ssh_auth_sock"
	fi
	export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
	tmux set-environment -g SSH_AUTH_SOCK "$SSH_AUTH_SOCK" 2>/dev/null
	tmux set-environment -g SSH_CLIENT "$SSH_CLIENT" 2>/dev/null
	tmux set-environment -g SSH_CONNECTION "$SSH_CONNECTION" 2>/dev/null
	# Attach or create; if tmux exits non-zero (config error, crash), fall through to a plain shell
	tmux new-session -A -s main && exit 0
fi

# New shells inside tmux: always use the stable symlink so the path is consistent
# regardless of which SSH session originally spawned the pane.
if [ -n "$TMUX" ] && [ -L "$HOME/.ssh/ssh_auth_sock" ]; then
	export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
fi
