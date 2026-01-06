# Zsh-specific settings
[[ -z "$ZSH_VERSION" ]] && return

autoload -U +X bashcompinit && bashcompinit
autoload -U compinit && compinit

# Disable auto-correction
unsetopt correct correct_all

# Python plugin settings
PYTHON_VENV_NAME=".venv"
PYTHON_VENV_NAMES=($PYTHON_VENV_NAME venv)
