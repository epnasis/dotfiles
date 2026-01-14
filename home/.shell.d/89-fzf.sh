# FZF configuration
command -v fzf >/dev/null || return

# Catppuccin Mocha colors
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--bind 'ctrl-f:page-down,ctrl-b:page-up' \
--reverse --multi"

# Source fzf integrations
[[ -n "$ZSH_VERSION" ]] && source <(fzf --zsh)
[[ -n "$BASH_VERSION" ]] && source <(fzf --bash)

# Find git projects recursively and cd to selected one
fp() {
    command -v fd >/dev/null || { echo "fd not installed"; return 1; }

    local cmd=(
        fd -t d .
        --exec-batch sh -c '
            GREEN="\033[32m"; RED="\033[31m"; YELLOW="\033[33m"; RESET="\033[0m"
            for dir in "$@"; do
                if [ -d "$dir/.git" ]; then
                    l="${GREEN}v${RESET}"; r="${GREEN}=${RESET}"
                    st=$(git -C "$dir" status --porcelain -b 2>/dev/null)
                    if [ -n "$st" ]; then
                        header=$(echo "$st" | head -n1)
                        if echo "$header" | grep -q "\.\.\."; then
                            echo "$header" | grep -q "ahead" && r="${RED}>${RESET}"
                            echo "$header" | grep -q "behind" && r="${RED}<${RESET}"
                            echo "$header" | grep -q "ahead.*behind" && r="${RED}Y${RESET}"
                        else
                            r="${YELLOW}L${RESET}"
                        fi
                        files=$(echo "$st" | tail -n +2)
                        if [ -n "$files" ]; then
                            echo "$files" | grep -q "^[^ ?]" && l="${RED}*${RESET}"
                            echo "$files" | grep -q "^.[^ ]" && l="${RED}+${RESET}"
                            echo "$files" | grep -q "^??" && l="${RED}?${RESET}"
                        fi
                    fi
                    echo "$r$l $dir"
                fi
            done
        ' sh
    )

    local header="Remote: > Ahead, < Behind, Y Diverged, = Sync, L Local
Local:  * Staged, + Modified, ? Untracked, v Clean"

    local selected
    selected=$("${cmd[@]}" | fzf --ansi \
        --color 'hl:-1:underline,hl+:-1:underline' \
        --header "$header" \
        --preview 'git -c color.status=always -C {2..} status -sb && echo "" && git -c color.ui=always -C {2..} log --oneline --graph -n 10' \
        --preview-window 'right:60%:wrap')

    if [[ -n "$selected" ]]; then
        local target=$(echo "$selected" | sed 's/\x1B\[[0-9;]*[mK]//g' | cut -c4-)
        [[ -d "$target" ]] && cd "$target"
    fi
}
