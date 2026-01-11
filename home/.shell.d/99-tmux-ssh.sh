# Auto-start tmux on SSH sessions
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && [[ $- == *i* ]]; then
	tmux new-session -A -s main && exit 0
fi
