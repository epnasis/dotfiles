# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important: Keep This File Updated

**CRITICAL INSTRUCTION:** When making changes to this repository, ALWAYS update this CLAUDE.md file to:
- Document new configurations, scripts, or workflows
- Explain design decisions and rationale behind changes
- Record important learnings and troubleshooting insights
- Preserve context for future sessions
- Update command tables, file structure diagrams, and examples

This ensures continuity across sessions and helps future Claude instances understand the repository's evolution.

## Git Commit Guidelines

**NEVER add Claude Code marketing footers or attribution to commit messages.** Keep commits clean and professional without "Generated with Claude Code" footers, co-author tags, or similar branding.

## Overview

Personal dotfiles repository for macOS with zsh, neovim, tmux, and git configurations. Includes shell utilities for streamlined repo initialization and SOPS/AGE secrets management.

## Structure

```
~/dotfiles/
├── .*                    # Dotfiles symlinked to $HOME (.zshrc, .vimrc, .gitconfig, etc.)
├── config/
│   ├── starship.toml     # Starship prompt configuration
│   └── bat/
│       ├── config        # bat syntax highlighter config
│       └── themes/       # Catppuccin Mocha theme for bat
├── zsh/
│   └── catppuccin_mocha-zsh-syntax-highlighting.zsh  # Zsh syntax theme
├── functions/
│   ├── repo_utils.zsh    # Shell functions: ginit, genc, enc, genc_hook
│   └── safe_rm.zsh       # Safe rm wrapper (moves to trash in interactive shells)
├── templates/
│   └── gitignore_default # Template for new repos (includes SOPS patterns)
├── .age_public_key       # AGE public key for SOPS encryption
├── .age_key_ref          # 1Password reference to AGE private key
└── install.sh            # Comprehensive setup script (installs dependencies + symlinks)
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

The `install.sh` script is now fully automated and portable. It will:
- Install oh-my-zsh and required plugins
- Check for and report missing tools
- Set up all config files and themes
- Symlink dotfiles to $HOME

```bash
cd ~/dotfiles
./install.sh            # Automated setup - installs dependencies + symlinks dotfiles
source ~/.zshrc         # or restart shell
```

The script will prompt you to install any missing tools with specific brew commands.

## Dependencies

All dependencies are checked by `install.sh`. Install missing ones with:

```bash
brew install starship fzf bat sops age gh nvim
```

**Core tools:**
- `oh-my-zsh` - Zsh framework (auto-installed by install.sh)
- `starship` - Prompt theme
- `fzf` - Fuzzy finder
- `bat` - Cat replacement with syntax highlighting
- `sops` and `age` - Secrets encryption
- `gh` - GitHub CLI for `ginit`
- `nvim` - Neovim editor
- `op` - 1Password CLI (optional, for key retrieval)

**Oh-my-zsh plugins** (auto-installed by install.sh):
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions

## macOS Gatekeeper Quarantine Fix

When using Homebrew-installed binaries over SSH, macOS Gatekeeper may show GUI popups asking to confirm running "downloaded from internet" apps. These popups are invisible in SSH sessions, causing commands to hang.

**Symptoms:**
- Shell hangs when loading (e.g., during `op completion zsh`)
- Works fine when accessed via RDP/GUI
- Affects tools like `op`, `gh`, or other Homebrew CLI tools

**Fix (run once after installing affected tools):**
```bash
# For specific tools that hang:
xattr -d com.apple.quarantine $(which op)
xattr -d com.apple.quarantine $(which gh)

# Or for all Homebrew binaries (less secure but convenient):
xattr -r -d com.apple.quarantine /opt/homebrew/bin/*  # Apple Silicon
xattr -r -d com.apple.quarantine /usr/local/bin/*     # Intel
```

**Verify quarantine is removed:**
```bash
xattr $(which op)
# Should show nothing or no com.apple.quarantine
```

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

**Note:** The `install.sh` script now handles most of this automatically. Just run `./install.sh` after cloning the repo.

For manual setup:

```bash
# 1. Install tools
brew install starship fzf bat

# 2. Run install.sh (handles oh-my-zsh, plugins, themes, configs)
./install.sh

# 3. iTerm2 - import color scheme from:
# https://github.com/catppuccin/iterm/raw/main/colors/catppuccin-mocha.itermcolors

# 4. Install Nerd Font
brew install --cask font-jetbrains-mono-nerd-font
```

All theme files and configs are now included in the repo under `config/` and `zsh/` directories.

### Font Requirements

Requires a Nerd Font for icons. iTerm2 → Preferences → Profiles → Text → Font.

Recommended: JetBrainsMono Nerd Font, Iosevka Nerd Font, or Hack Nerd Font.

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

## Tmux Configuration

### SSH Client Environment Update

The `.tmux.conf` includes:
```bash
set-option -g update-environment "SSH_CLIENT"
```

This ensures tmux updates the `SSH_CLIENT` variable when reattaching to a session from a different SSH connection.

**Why this matters:**
- `SSH_CLIENT` contains connection info: `<client-ip> <client-port> <server-port>`
- By default, tmux updates `DISPLAY`, `SSH_AUTH_SOCK`, `SSH_CONNECTION`, but NOT `SSH_CLIENT`
- Without this setting: attach from Computer A, detach, reattach from Computer B → `SSH_CLIENT` shows stale Computer A info
- With this setting: `SSH_CLIENT` reflects the current connection
- Benefits: scripts that check connection source get accurate info, security logging works correctly, useful when connecting from multiple locations

## Oh-My-Zsh Plugins

The `.zshrc` includes these plugins for enhanced functionality:

| Plugin | Purpose |
|--------|---------|
| `git` | Git aliases and functions |
| `brew` | Homebrew completion and aliases |
| `common-aliases` | Useful shell aliases (note: `P` and `rm` aliases disabled) |
| `gcloud` | Google Cloud SDK completion |
| `gh` | GitHub CLI completion |
| `pip` | Python pip completion |
| `python` | Python virtual environment helpers (configured with `.venv` preference) |
| `uv` | UV package manager support |
| `vi-mode` | Vi keybindings in shell |
| `z` | Jump to frequent directories |
| `zsh-autosuggestions` | Command suggestions based on history |
| `zsh-syntax-highlighting` | Syntax highlighting for commands |
| `zsh-completions` | Additional completion definitions |
| `docker` | Docker completion and aliases |

**Python plugin configuration:**
```bash
PYTHON_VENV_NAME=".venv"
PYTHON_VENV_NAMES=($PYTHON_VENV_NAME venv)
```

## Custom Shell Functions

### `ghc()` - Clone GitHub Repo with FZF
```bash
ghc
```
Interactive repository cloner using `gh` and `fzf`. Lists your GitHub repos, lets you fuzzy-search and select, then clones the selected repo.

### `gemini()` - Gemini CLI Helper
```bash
gemini [args]
```
Auto-navigates to `~/gemini` when called from home directory without arguments, then runs the gemini command. Aliased as `gg`.

## Safe rm Wrapper

The `rm` command is replaced by a shell function (in `functions/safe_rm.zsh`) that moves files to trash instead of permanently deleting them.

### Behavior

| Context | Action |
|---------|--------|
| Interactive shell + non-temp files | Moves to trash |
| Interactive shell + temp files only | Real `rm` (no point trashing temp files) |
| Non-interactive (scripts) | Real `rm` (preserves script behavior) |
| No trash command available | Real `rm` with warning |
| `rm -f` on non-existent file | Silent skip (mimics real rm -f) |
| `rm` on non-existent file | Error (mimics real rm) |

### Platform Support

| OS | Trash Command |
|----|---------------|
| macOS | `/usr/bin/trash` (built-in, Apple-signed) |
| Linux | `trash-put` (trash-cli) or `gio trash` |

### Design Rationale

1. **Shell function beats aliases** - Functions take precedence over aliases, solving conflicts with `common-aliases` plugin's `rm -i`.

2. **Scripts use real rm** - Detects non-interactive shells via `$-` variable to avoid breaking scripts.

3. **Temp files bypass trash** - Files in `$TMPDIR`, `/tmp`, `/var/tmp`, or `/private/tmp` are deleted permanently.

4. **No dotfiles = be careful** - On servers without your dotfiles, `rm` behaves normally. Use `/bin/rm` explicitly when you want permanent deletion.

### Linux Setup

```bash
# Ubuntu/Debian
sudo apt install trash-cli

# Fedora
sudo dnf install trash-cli

# GNOME systems usually have gio pre-installed
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
