# Oh-my-zsh setup
[[ -z "$ZSH_VERSION" ]] && return
[[ ! -d "$HOME/.oh-my-zsh" ]] && return

# Optimizations
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="true"

# Python plugin settings
PYTHON_VENV_NAME=".venv"
PYTHON_VENV_NAMES=($PYTHON_VENV_NAME venv)

plugins=(
  git
  #brew
  common-aliases
  #gcloud
  #gh
  #pip
  #python
  #uv
  #vi-mode
  #z
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  #docker
)

source "$ZSH/oh-my-zsh.sh"

# Disable problematic aliases from common-aliases
unalias 'P' 2>/dev/null   # pygmentize dependency
unalias 'rm' 2>/dev/null  # we use safe_rm function

# Catppuccin syntax highlighting theme
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
if [[ -f "$DOTFILES_DIR/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]]; then
  source "$DOTFILES_DIR/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh"
elif [[ -f "$HOME/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]]; then
  source "$HOME/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh"
fi
