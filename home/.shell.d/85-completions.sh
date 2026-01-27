# Tool-specific completions
# HashiCorp tools use `complete -C <binary>` (bash builtin).
# Zsh needs bashcompinit to emulate this.
[[ -n "$ZSH_VERSION" ]] && autoload -Uz bashcompinit && bashcompinit

command -v terraform >/dev/null && complete -o nospace -C "$(command -v terraform)" terraform
command -v vault >/dev/null && complete -o nospace -C "$(command -v vault)" vault
