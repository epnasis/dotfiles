# macOS-specific settings
[[ "$(uname)" != "Darwin" ]] && return

# ARM64 brew alias
if [[ "$(uname -m)" == "arm64" ]] && command -v arch >/dev/null; then
  alias brew="arch -arm64 brew"
fi

# Google Cloud SDK
[[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc"
[[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"
