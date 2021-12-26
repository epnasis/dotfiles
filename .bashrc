# dah!
set -o vi
export EDITOR=vim

# ls
export LS_OPTIONS='--color=auto'
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias la='ls $LS_OPTIONS -A'

# ask me
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# history 
HISTFILESIZE=100000
HISTSIZE=1000000
SAVEHIST=2000000

if [ -n "$ZSH_VERSION" ]; then
  setopt hist_ignore_dups
  setopt hist_ignore_space
  setopt share_history
  unsetopt hist_verify
else
  PROMPT_COMMAND='history -a'
  HISTCONTROL=ignorespace:ignoredups
  shopt -s histappend
fi

# -----------------------------------------------------------------
# KEEP IT LAST - run in tmux
# -----------------------------------------------------------------
[ -z "$TMUX" ] && (
    tmux attach || tmux new
    tmux ls || exit
)
