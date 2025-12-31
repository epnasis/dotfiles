# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# Disabled oh-my-zsh theme - using Starship instead
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="false"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  vi-mode
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  docker
  #kubectl
)

source $ZSH/oh-my-zsh.sh

# Catppuccin Mocha syntax highlighting theme
source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="vi ~/.zshrc; source ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# custom
autoload -U +X bashcompinit && bashcompinit
#source /usr/local/etc/bash_completion.d/az

# disable asking to correct arguments
unsetopt correct correct_all

# kubeclt completion
#if [ $commands[kubectl] ]; then
#  source <(kubectl completion zsh)
#fi

# adding helm completion manually to fix issue https://github.com/helm/helm/issues/5046
#if [ $commands[helm] ]; then
#  source <(helm completion zsh | sed -E 's/\["(.+)"\]/\[\1\]/g')
#fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then source "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then source "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

if command -v terraform >/dev/null 2>&1; then
  complete -o nospace -C "$(command -v terraform)" terraform
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# FZF with Catppuccin Mocha colors
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--reverse --multi"

export EDITOR='nvim'
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
elif [ -d "/usr/local/opt/ruby/bin" ]; then
  export PATH="/usr/local/opt/ruby/bin:$PATH"
fi

if [ "$(uname -m)" = "arm64" ] && command -v arch >/dev/null 2>&1; then
  alias brew="arch -arm64 brew"
fi

# 1password autocomplete
if command -v op >/dev/null 2>&1; then
  eval "$(op completion zsh)"
  compdef _op op
fi

# make pytho
if [ -d "/opt/homebrew/opt/python/libexec/bin" ]; then
  export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"
elif [ -d "/usr/local/opt/python/libexec/bin" ]; then
  export PATH="/usr/local/opt/python/libexec/bin:$PATH"
fi

if command -v vault >/dev/null 2>&1; then
  complete -o nospace -C "$(command -v vault)" vault
fi
if [ -f "$HOME/.config/op/plugins.sh" ]; then
  source "$HOME/.config/op/plugins.sh"
fi

# -----------------------------------------------------------------
# KEEP IT LAST - run in tmux
# -----------------------------------------------------------------
# if running inside file manager
#PARENT_CMD=$(ps -co command= $PPID)
#if [ "$PARENT_CMD" = "Marta" ]; then
#    [ -z "$TMUX" ] && ( tmux attach || tmux new ) 
#fi
#

# alias for Garmin FIT CSV Tool
alias fittool='java -jar ~/Downloads/FitSDKRelease_21.133.00/java/FitCSVTool.jar'

# git aliases
alias lg='lazygit'

# python aliases
alias pva='source .venv/bin/activate'
alias pvd='deactivate'

# Added by Windsurf
if [ -d "$HOME/.codeium/windsurf/bin" ]; then
  export PATH="$HOME/.codeium/windsurf/bin:$PATH"
fi

# NVIM everywhere
alias vi='nvim'
alias vim='nvim'

# UV
export UV_PYTHON_PREFERENCE="only-managed"
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Gemini CLI helper: cd to ~/gemini if in home directory, then run gemini
gemini() {
    if [ "$PWD" = "$HOME" ] && [ "$#" -eq 0 ]; then
        cd "$HOME/gemini" || return
    fi
    command gemini "$@"
}
alias gg=gemini
alias rr='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"'
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
if [ -f "$DOTFILES_DIR/functions/repo_utils.zsh" ]; then
  source "$DOTFILES_DIR/functions/repo_utils.zsh"
fi

# Initialize Starship prompt (keep at end)
eval "$(starship init zsh)"
