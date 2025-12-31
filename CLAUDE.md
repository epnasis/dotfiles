# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository for macOS with zsh, neovim, tmux, and git configurations. Includes shell utilities for streamlined repo initialization and SOPS/AGE secrets management.

## Structure

```
~/dotfiles/
├── .*                    # Dotfiles symlinked to $HOME (.zshrc, .vimrc, .gitconfig, etc.)
├── functions/
│   └── repo_utils.zsh    # Shell functions: ginit, genc, enc, genc_hook
├── templates/
│   └── gitignore_default # Template for new repos (includes SOPS patterns)
├── .age_public_key       # AGE public key for SOPS encryption
├── .age_key_ref          # 1Password reference to AGE private key
└── install.sh            # Symlinks dotfiles to $HOME
```

## Commands

| Command | Purpose |
|---------|---------|
| `ginit [name]` | Initialize git repo + create private GitHub repo via `gh` |
| `genc` | Setup SOPS config, decrypt `.enc.*` files, install pre-commit hook |
| `enc [files]` | Encrypt file(s), or all if no args. Skips unchanged. |
| `genc_hook` | Manually reinstall the secrets sync pre-commit hook |

## Secrets Workflow

The setup uses SOPS with AGE encryption. Workflow designed for editing unencrypted files locally:

```bash
# New repo setup
ginit myproject
genc                    # sets up .sops.yaml, .gitignore, pre-commit hook

# Daily workflow
nvim .env               # edit secrets normally
enc                     # encrypt all changed files (or: enc .env, enc secrets/*.yaml)
git commit              # hook validates sync (content-based)

# Clone on another machine
git clone ...
genc                    # decrypts .enc.* files + installs hook
```

**File patterns:**
- `.env` → `.enc.env` (root level)
- `secrets/db.yaml` → `secrets/db.enc.yaml` (secrets directory)

**Pre-commit hook:** Blocks commits if unencrypted files differ from their `.enc` counterparts. Uses content comparison (not timestamps) to avoid unnecessary re-encryption polluting git history.

## Key Design Decisions

1. **Unencrypted files are gitignored, encrypted files are committed** - Allows normal editor workflow while keeping secrets safe in git.

2. **Content-based sync validation** - SOPS encryption produces different ciphertext for same plaintext (nonces/IVs), so the hook decrypts and compares content rather than file hashes.

3. **1Password integration** - Private AGE key stored in 1Password, referenced via `op://` URI in `.age_key_ref`. Avoids storing private key on disk.

4. **Template-based gitignore** - `ginit` copies `templates/gitignore_default` which already includes SOPS patterns, avoiding duplication in `genc`.

## Installation

```bash
cd ~/dotfiles
./install.sh            # symlinks dotfiles to $HOME
source ~/.zshrc         # or restart shell
```

## Dependencies

- `sops` and `age` - `brew install sops age`
- `gh` - GitHub CLI for `ginit`
- `op` - 1Password CLI (optional, for key retrieval)
- `starship` - Prompt theme (`brew install starship`)
- `bat` - Cat replacement with syntax highlighting (`brew install bat`)
- `fzf` - Fuzzy finder (`brew install fzf`)

## Shell Theming (Catppuccin Mocha)

Unified Catppuccin Mocha theme across terminal tools to match neovim.

### Components

| Tool | Config Location | Purpose |
|------|-----------------|---------|
| Starship | `~/.config/starship.toml` | Prompt with git status, python version, etc. |
| zsh-syntax-highlighting | `~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh` | Command syntax colors |
| fzf | `FZF_DEFAULT_OPTS` in `.zshrc` | Fuzzy finder colors |
| bat | `~/.config/bat/config` | Syntax-highlighted cat replacement |
| iTerm2 | Preferences → Profiles → Colors | Terminal colors |

### Starship Prompt

Config at `~/.config/starship.toml` uses Catppuccin palette with Nerd Font icons.

**Important:** When editing `starship.toml`, Nerd Font characters may get stripped by some editors. Use `printf` with Unicode escapes:

```bash
# Git branch icon (U+E0A0)
printf 'symbol = "\ue0a0 "\n'

# Other common icons:
# Python: \ue73c
# Node.js: \ue718
# Rust: \ue7a8
# Go: \ue627
# Docker: \ue7b0
```

### Setup from Scratch

```bash
# 1. Install Starship
brew install starship

# 2. Download syntax highlighting theme
mkdir -p ~/.zsh
curl -o ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh \
  https://raw.githubusercontent.com/catppuccin/zsh-syntax-highlighting/main/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh

# 3. Setup bat theme
mkdir -p "$(bat --config-dir)/themes"
curl -o "$(bat --config-dir)/themes/Catppuccin Mocha.tmTheme" \
  https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme
bat cache --build
echo '--theme="Catppuccin Mocha"' > ~/.config/bat/config

# 4. iTerm2 - import color scheme from:
# https://github.com/catppuccin/iterm/raw/main/colors/catppuccin-mocha.itermcolors
```

### .zshrc Additions

```bash
# Catppuccin syntax highlighting (after oh-my-zsh source)
source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh

# fzf Catppuccin colors
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--reverse --multi"

# Starship init (keep at end of .zshrc)
eval "$(starship init zsh)"
```

### Font Requirements

Requires a Nerd Font for icons. iTerm2 → Preferences → Profiles → Text → Font.

Recommended: JetBrainsMono Nerd Font, Iosevka Nerd Font, or Hack Nerd Font.

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

## Technical Notes (SOPS Behavior)

### File Naming: `.enc.*` vs `*.enc`

We use `.enc.env` and `file.enc.yaml` (not `.env.enc` or `file.yaml.enc`) because:
- SOPS auto-detects file type from the **final** extension
- `file.enc.yaml` → SOPS sees `.yaml`, auto-detects YAML format
- `file.yaml.enc` → SOPS sees `.enc`, defaults to JSON, fails
- With `*.enc` pattern, you'd need `--input-type` and `--output-type` flags for every operation

### .sops.yaml path_regex

The `path_regex` in `.sops.yaml` is a **key selector**, not a security feature:
- Only used during encryption to choose which AGE key to use
- Matched against the **input** file path (e.g., `.env` when running `sops -e .env`)
- For decryption, SOPS reads key info from the encrypted file itself
- Our regex `(\.env$|\.enc\.env|secrets/.*)` covers both plain and encrypted files for flexibility

### SOPS Format Normalization

SOPS normalizes file formatting, which affects content comparison:
- **YAML**: Normalizes to 4-space indentation (your 2-space file becomes 4-space after decrypt)
- **dotenv**: May strip blank lines

To handle this, `enc` syncs the plain file with SOPS-normalized format after encrypting:
```bash
sops -e "$plain" > "$encrypted"
sops -d "$encrypted" > "$plain"  # sync format
```

### Pre-commit Hook Architecture

The hook sources `$HOME/dotfiles/functions/repo_utils.zsh` to reuse:
- `_ensure_age_key` - fetches AGE key from env, 1Password, or prompts
- `_enc_name` / `_plain_name` - filename conversion helpers

This avoids code duplication and ensures consistent behavior.

### Helper Functions

| Function | Purpose |
|----------|---------|
| `_ensure_age_key` | Fetches AGE key from env → 1Password → interactive prompt |
| `_enc_name` | `.env` → `.enc.env`, `file.yaml` → `file.enc.yaml` |
| `_plain_name` | `.enc.env` → `.env`, `file.enc.yaml` → `file.yaml` |

### Why Content Comparison (Not Hashes)

SOPS uses nonces/IVs, so re-encrypting identical content produces different ciphertext. Comparing encrypted file hashes would always show "changed". Instead:
1. Decrypt the `.enc.*` file
2. Compare decrypted content with plain file
3. Only encrypt if content actually differs

This prevents unnecessary re-encryption that would pollute git history.
