# Auto-start tmux on SSH sessions
[[ -z "$SSH_CONNECTION" ]] && return
[[ -n "$TMUX" ]] && return
command -v tmux >/dev/null || return

tmux attach -t main 2>/dev/null || tmux new -s main
