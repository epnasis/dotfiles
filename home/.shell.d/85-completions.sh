# Tool-specific completions
command -v terraform >/dev/null && complete -o nospace -C "$(command -v terraform)" terraform
command -v vault >/dev/null && complete -o nospace -C "$(command -v vault)" vault
