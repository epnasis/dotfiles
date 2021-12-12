# dah!
set -o vi
export EDITOR=vim

# ls
export LS_OPTIONS='--color=auto'
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias la='ls $LS_OPTIONS -lA'

# ask me
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# tmux of course
[ -z "$TMUX" ] && (
    tmux attach || tmux new
    tmux ls || exit
)
