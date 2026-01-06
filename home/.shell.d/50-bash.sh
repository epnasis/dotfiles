# Bash-specific settings
[[ -z "$BASH_VERSION" ]] && return

shopt -s checkwinsize
shopt -s globstar 2>/dev/null

# Completion
if [[ -f /etc/bash_completion ]]; then
  source /etc/bash_completion
elif [[ -f /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
elif [[ -f /opt/homebrew/etc/profile.d/bash_completion.sh ]]; then
  source /opt/homebrew/etc/profile.d/bash_completion.sh
fi
