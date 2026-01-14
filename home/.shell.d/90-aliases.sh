# General aliases

if command -v nvim >/dev/null 2>&1; then
	alias vi='nvim'
	alias vim='nvim'
fi

alias lg='lazygit'
alias rr='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"'
if command -v eza >/dev/null 2>&1; then
	alias l='eza -F --icons=auto --group-directories-first'
	alias la='eza -aF --icons=auto --group-directories-first'
	alias ll='eza -lF --git --icons=auto --group-directories-first'
	alias lla='eza -alF --git --icons=auto --group-directories-first'
	alias lt='eza --sort=time -lF --icons=auto --group-directories-first'
	alias tree='eza -TF --icons=auto --group-directories-first'
fi
alias f=fzf

# Python
alias pva='source .venv/bin/activate'
alias pvd='deactivate'

# Shell config
alias zshconfig="vi ~/.zshrc; source ~/.zshrc"
