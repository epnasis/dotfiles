# Antidote Plugin Manager Setup
[[ -z "$ZSH_VERSION" ]] && return

# 1. Bootstrap Antidote if missing
if [[ ! -d "${ZDOTDIR:-$HOME}/.antidote" ]]; then
  echo "[+] Installing Antidote plugin manager..."
  git clone --depth=1 https://github.com/mattmc3/antidote.git "${ZDOTDIR:-$HOME}/.antidote"
fi

# 2. Configure Zsh/OMZ options
# These must be set BEFORE loading plugins
export DISABLE_AUTO_UPDATE="true"
export DISABLE_MAGIC_FUNCTIONS="true"
export ENABLE_CORRECTION="false"
export COMPLETION_WAITING_DOTS="true"
export PYTHON_VENV_NAME=".venv"

# 3. Load Antidote and Plugins
source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
antidote load "${ZDOTDIR:-$HOME}/.zsh_plugins.txt"

# 4. Post-load configuration (Manual overrides)

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
