# macOS-specific settings
[[ "$(uname)" != "Darwin" ]] && return

# ARM64 brew alias
if [[ "$(uname -m)" == "arm64" ]] && command -v arch >/dev/null; then
  alias brew="arch -arm64 brew"
fi

alias reboot="sudo fdesetup authrestart"

# Google Cloud SDK (manual install at ~/google-cloud-sdk)
if [[ -n "$ZSH_VERSION" ]]; then
  [[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc"
  [[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"
elif [[ -n "$BASH_VERSION" ]]; then
  [[ -f "$HOME/google-cloud-sdk/path.bash.inc" ]] && source "$HOME/google-cloud-sdk/path.bash.inc"
  [[ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]] && source "$HOME/google-cloud-sdk/completion.bash.inc"
fi
