# General aliases

if command -v nvim >/dev/null 2>&1; then
    alias vi='nvim'
    alias vim='nvim'
fi

alias lg='lazygit'
alias rr='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"'

# Python
alias pva='source .venv/bin/activate'
alias pvd='deactivate'

# Shell config
alias zshconfig="vi ~/.zshrc; source ~/.zshrc"
