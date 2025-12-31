#!/bin/bash

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  Dotfiles Installation Script"
echo "=========================================="
echo

# Helper functions
info() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

link() {
    info "Creating symbolic link for: $1"
    ln -sfv "$1" ~
    echo
}

# Check for Homebrew
if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew not found. Install from https://brew.sh"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo
else
    info "Homebrew found"
fi

# Check and install oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    warn "oh-my-zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    info "oh-my-zsh installed"
else
    info "oh-my-zsh already installed"
fi

# Install oh-my-zsh custom plugins
info "Installing oh-my-zsh custom plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    info "Installed zsh-autosuggestions"
else
    info "zsh-autosuggestions already installed"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    info "Installed zsh-syntax-highlighting"
else
    info "zsh-syntax-highlighting already installed"
fi

# zsh-completions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
    git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
    info "Installed zsh-completions"
else
    info "zsh-completions already installed"
fi

echo

# Check for required CLI tools
info "Checking for required tools..."
MISSING_TOOLS=()

for tool in starship fzf bat sops age gh nvim; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    warn "Missing tools: ${MISSING_TOOLS[*]}"
    echo "  Install with: brew install ${MISSING_TOOLS[*]}"
    echo
else
    info "All required tools found"
fi

# Create necessary directories
info "Creating necessary directories..."
mkdir -p ~/.vim/undodir
mkdir -p ~/.vim/swpdir
mkdir -p ~/.zsh
mkdir -p ~/.config
echo

# Setup zsh theme
info "Setting up zsh syntax highlighting theme..."
if [ -f "$SCRIPT_DIR/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]; then
    ln -sfv "$SCRIPT_DIR/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh" ~/.zsh/
else
    warn "Catppuccin theme not found in repo, downloading..."
    mkdir -p "$SCRIPT_DIR/zsh"
    curl -fsSL -o "$SCRIPT_DIR/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh" \
        https://raw.githubusercontent.com/catppuccin/zsh-syntax-highlighting/main/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
    ln -sfv "$SCRIPT_DIR/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh" ~/.zsh/
fi
echo

# Setup starship config
if command -v starship >/dev/null 2>&1; then
    info "Setting up Starship config..."
    if [ -f "$SCRIPT_DIR/config/starship.toml" ]; then
        ln -sfv "$SCRIPT_DIR/config/starship.toml" ~/.config/starship.toml
    else
        warn "Starship config not found in repo"
        echo "  Will use Starship's default config"
    fi
    echo
fi

# Setup bat config and theme
if command -v bat >/dev/null 2>&1; then
    info "Setting up bat config and theme..."
    BAT_CONFIG_DIR="$(bat --config-dir)"
    mkdir -p "$BAT_CONFIG_DIR/themes"

    if [ -f "$SCRIPT_DIR/config/bat/config" ]; then
        ln -sfv "$SCRIPT_DIR/config/bat/config" "$BAT_CONFIG_DIR/config"
    else
        warn "bat config not found in repo, creating default..."
        mkdir -p "$SCRIPT_DIR/config/bat"
        echo '--theme="Catppuccin Mocha"' > "$SCRIPT_DIR/config/bat/config"
        ln -sfv "$SCRIPT_DIR/config/bat/config" "$BAT_CONFIG_DIR/config"
    fi

    # Download Catppuccin theme if not present
    if [ ! -f "$BAT_CONFIG_DIR/themes/Catppuccin Mocha.tmTheme" ]; then
        info "Downloading Catppuccin Mocha theme for bat..."
        curl -fsSL -o "$BAT_CONFIG_DIR/themes/Catppuccin Mocha.tmTheme" \
            https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme
        bat cache --build
    fi
    echo
fi

# Symlink dotfiles
info "Symlinking dotfiles..."
for dotfile in "$SCRIPT_DIR"/.*; do
    basename_file=$(basename "$dotfile")
    if [[ "$basename_file" =~ (^\.git$|^\.gitignore$|\.swp$|~|^\.$|^\.\.$) ]]; then
        continue # exclude files based on regex above
    fi
    link "$dotfile"
done

echo
info "=========================================="
info "  Installation Complete!"
info "=========================================="
echo
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.zshrc"
echo "  2. For iTerm2: Import Catppuccin Mocha color scheme from:"
echo "     https://github.com/catppuccin/iterm/raw/main/colors/catppuccin-mocha.itermcolors"
echo "  3. Install a Nerd Font for icons:"
echo "     brew install --cask font-jetbrains-mono-nerd-font"
echo
if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    warn "Remember to install missing tools: ${MISSING_TOOLS[*]}"
    echo "  brew install ${MISSING_TOOLS[*]}"
    echo
fi
