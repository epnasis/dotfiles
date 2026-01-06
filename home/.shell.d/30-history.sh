# History settings
HISTSIZE=100000
SAVEHIST=200000

if [[ -n "$ZSH_VERSION" ]]; then
  setopt hist_ignore_dups share_history extended_history
elif [[ -n "$BASH_VERSION" ]]; then
  shopt -s histappend
  HISTCONTROL=ignoredups:erasedups
fi
