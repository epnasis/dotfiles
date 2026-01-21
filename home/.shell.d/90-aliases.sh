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

if command -v bat >/dev/null 2>&1; then
	alias c=bat
fi

# Python
alias pva='source .venv/bin/activate'
alias pvd='deactivate'

# Shell config
alias zshconfig="vi ~/.zshrc; source ~/.zshrc"

# Gemini CLI helper
if command -v gemini >/dev/null; then
	unalias gg 2>/dev/null
	function gg {
		if [[ "$PWD" == "$HOME" && "$#" -eq 0 ]]; then
			local gemini_dir="$HOME/gemini"
			if [[ ! -d "$gemini_dir" ]]; then
				printf "Directory %s does not exist. Create it? [y/N] " "$gemini_dir"
				local response
				read -r response
				if [[ "$response" =~ ^[Yy] ]]; then
					mkdir -p "$gemini_dir"
				fi
			fi

			if [[ -d "$gemini_dir" ]]; then
				cd "$gemini_dir" || return
			fi
		fi
		gemini "$@"
	}
fi
