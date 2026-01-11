# Google Cloud SDK
command -v gcloud >/dev/null || return

# Derive SDK path from gcloud binary location
# gcloud is at $SDK/bin/gcloud, so go up two levels
_gcloud_sdk="$(dirname "$(dirname "$(command -v gcloud)")")"

# Completions (zsh only, has internal guard for compdef)
[[ -n "$ZSH_VERSION" && -f "$_gcloud_sdk/completion.zsh.inc" ]] && source "$_gcloud_sdk/completion.zsh.inc"

unset _gcloud_sdk
