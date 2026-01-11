# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Planning

When done with tasks agreed in sesion propose to focus on next times you can find in @TODO.md file.

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

## Git Commit Signing

All commits are signed using SSH keys via 1Password integration.

### Configuration (in `.gitconfig`)

```ini
[user]
  signingkey = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...

[gpg]
  format = ssh

[gpg "ssh"]
  program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
  allowedSignersFile = ~/.config/git/allowed_signers

[commit]
  gpgsign = true
```

### Allowed Signers File

Located at `~/.config/git/allowed_signers`, this file maps email addresses to SSH public keys for signature verification:

```
pawel@wenda.eu ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...
```

**Format:** `<email> <key-type> <public-key>`

**Purpose:**

- Enables `git log --show-signature` to verify commit signatures
- Required for `git verify-commit` to work
- Maps trusted identities to their signing keys

### How It Works

1. **Signing:** When you commit, 1Password's `op-ssh-sign` prompts for authentication (Touch ID/password) and signs the commit with your SSH key
2. **Verification:** Git checks the signature against keys in `allowed_signers` to confirm the commit came from a trusted source
3. **GitHub:** GitHub also verifies signatures if you've added your SSH signing key to your account

### Verifying Commits

```bash
# Show signature status in log
git log --show-signature

# Verify a specific commit
git verify-commit HEAD

# Show signature in short format
git log --format='%G? %h %s'
# G = Good signature, N = No signature, B = Bad signature
```

## Overview

Personal dotfiles repository for macOS and Linux (Debian/Fedora) with modular shell configuration supporting both bash and zsh. Includes neovim, tmux, git configs, and SOPS/AGE secrets management.

## Structure

```
~/dotfiles/
├── install.sh              # Interactive installer (use --all for non-interactive)
├── home/                   # Files symlinked to $HOME (mirrors ~/ structure)
│   ├── .vimrc, .tmux.conf, .inputrc, .editrc, .gitconfig
│   ├── .config/
│   │   ├── starship.toml   # Starship prompt configuration
│   │   ├── bat/            # bat config + Catppuccin theme
│   │   └── git/allowed_signers
│   └── .shell.d/           # Modular shell scripts (numbered for load order)
│       ├── 10-env.sh       # EDITOR, LANG (conditional nvim/vim)
│       ├── 20-path.sh      # PATH modifications
│       ├── 30-history.sh   # History settings (bash/zsh)
│       ├── 40-aliases.sh   # General aliases
│       ├── 45-fzf.sh       # FZF config + fp() function
│       ├── 50-bash.sh      # Bash-specific settings
│       ├── 50-zsh.sh       # Zsh-specific settings
│       ├── 55-oh-my-zsh.sh # Oh-my-zsh setup (optional, skips if not installed)
│       ├── 60-git.sh       # Git aliases + ginit, ghc functions
│       ├── 65-linux.sh     # Linux-specific settings
│       ├── 65-macos.sh     # macOS-specific settings
│       ├── 70-1password.sh # 1Password CLI + SSH agent
│       ├── 75-sops.sh      # SOPS/AGE: genc, enc, genc_hook
│       ├── 80-safe-rm.sh   # Safe rm wrapper (trash)
│       ├── 85-completions.sh
│       ├── 90-starship.sh  # Starship prompt init
│       ├── 95-gemini.sh    # Gemini CLI helper
│       └── 99-tmux-ssh.sh  # Auto-start tmux on SSH
├── zsh/
│   └── catppuccin_mocha-zsh-syntax-highlighting.zsh
├── .age_public_key         # AGE public key for SOPS encryption
└── .age_key_ref            # 1Password reference to AGE private key
```

## Commands

| Command        | Purpose                                                            |
| -------------- | ------------------------------------------------------------------ |
| `fp`           | Find git projects recursively with fzf, cd to selected             |
| `gs`           | Alias for `git status`                                             |
| `ginit [name]` | Initialize git repo + create private GitHub repo via `gh`          |
| `ghc`          | Clone a repo from your GitHub account using fzf                    |
| `genc`         | Setup SOPS config, decrypt `.enc.*` files, install pre-commit hook |
| `enc [files]`  | Encrypt file(s), or all if no args. Skips unchanged.               |
| `genc_hook`    | Manually reinstall the secrets sync pre-commit hook                |
| `gg` / `gemini`| Gemini CLI helper (cd to ~/gemini if in home)                      |

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

4. **Inline gitignore template** - `ginit` uses a heredoc function `_gitignore_default()` in `60-git.sh` for the standard gitignore. SOPS patterns are added separately by `genc`.

5. **Modular shell.d architecture** - Each feature in its own numbered file with guards. Files load in numeric order, skip gracefully if dependencies missing.

## Shell.d Architecture

Each file in `~/.shell.d/` is sourced in numeric order. Files use guards to skip if:
- Wrong shell (bash vs zsh)
- Wrong platform (macOS vs Linux)
- Required tool not installed

Example guard patterns:
```bash
# Skip if not on macOS
[[ "$(uname)" != "Darwin" ]] && return

# Skip if tool not installed
command -v fzf >/dev/null || return

# Zsh-only
[[ -z "$ZSH_VERSION" ]] && return
```

This allows the same dotfiles to work across different machines with different tools installed.

## Installation

```bash
cd ~/dotfiles

# Interactive mode - prompts for each file
./install.sh

# Non-interactive - install all files without prompts
./install.sh --all
```

The script will:
1. Symlink files from `home/` to `~/`
2. Append shell.d sourcing block to `~/.bashrc` and `~/.zshrc` (idempotent)

**Symbols:** `✓` installed, `·` already linked, `-` skipped

**Options for new files:** `[N]o / [y]es / [a]ll / [v]iew / [q]uit`
**Options for conflicts:** `[N]o / [d]iff / [f]orce / [q]uit`

The RC append block:
```bash
# --- dotfiles ---
for f in ~/.shell.d/*.sh; do [[ -f "$f" ]] && . "$f"; done
# --- end dotfiles ---
```

## Dependencies

Install tools with your package manager:

```bash
# macOS
brew install starship fzf bat sops age gh nvim

# Debian/Ubuntu
apt install fzf bat
# Others: starship, sops, age, gh, nvim via GitHub releases or other sources

# Fedora
dnf install fzf bat
```

**Core tools:**

- `starship` - Prompt theme
- `fzf` - Fuzzy finder
- `bat` - Cat replacement with syntax highlighting
- `sops` and `age` - Secrets encryption (optional)
- `gh` - GitHub CLI for `ginit`
- `nvim` - Neovim editor (EDITOR falls back to vim if not installed)
- `op` - 1Password CLI (optional, for key retrieval)

**Optional (zsh only):**

- `oh-my-zsh` - Zsh framework (55-oh-my-zsh.sh skips if not installed)
- zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions

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

| Tool                    | Config Location                                       | Purpose                                      |
| ----------------------- | ----------------------------------------------------- | -------------------------------------------- |
| Starship                | `~/.config/starship.toml`                             | Prompt with git status, python version, etc. |
| zsh-syntax-highlighting | `~/dotfiles/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh` | Command syntax colors                  |
| fzf                     | `FZF_DEFAULT_OPTS` in `~/.shell.d/45-fzf.sh`          | Fuzzy finder colors                          |
| bat                     | `~/.config/bat/config`                                | Syntax-highlighted cat replacement           |
| iTerm2                  | Preferences → Profiles → Colors                       | Terminal colors                              |

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

All theme files and configs are now included in the repo under `home/.config/` and `zsh/` directories.

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

Configured in `~/.shell.d/55-oh-my-zsh.sh` (only loads if oh-my-zsh is installed):

| Plugin                    | Purpose                                                                 |
| ------------------------- | ----------------------------------------------------------------------- |
| `git`                     | Git aliases and functions                                               |
| `brew`                    | Homebrew completion and aliases                                         |
| `common-aliases`          | Useful shell aliases (note: `P` and `rm` aliases disabled)              |
| `gcloud`                  | Google Cloud SDK completion                                             |
| `gh`                      | GitHub CLI completion                                                   |
| `pip`                     | Python pip completion                                                   |
| `python`                  | Python virtual environment helpers (configured with `.venv` preference) |
| `uv`                      | UV package manager support                                              |
| `vi-mode`                 | Vi keybindings in shell                                                 |
| `z`                       | Jump to frequent directories                                            |
| `zsh-autosuggestions`     | Command suggestions based on history                                    |
| `zsh-syntax-highlighting` | Syntax highlighting for commands                                        |
| `zsh-completions`         | Additional completion definitions                                       |
| `docker`                  | Docker completion and aliases                                           |

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

The `rm` command is replaced by a shell function (in `~/.shell.d/80-safe-rm.sh`) that moves files to trash instead of permanently deleting them.

### Behavior

| Context                             | Action                                   |
| ----------------------------------- | ---------------------------------------- |
| Interactive shell + non-temp files  | Moves to trash                           |
| Interactive shell + temp files only | Real `rm` (no point trashing temp files) |
| Non-interactive (scripts)           | Real `rm` (preserves script behavior)    |
| No trash command available          | Real `rm` with warning                   |
| `rm -f` on non-existent file        | Silent skip (mimics real rm -f)          |
| `rm` on non-existent file           | Error (mimics real rm)                   |

### Platform Support

| OS    | Trash Command                             |
| ----- | ----------------------------------------- |
| macOS | `/usr/bin/trash` (built-in, Apple-signed) |
| Linux | `trash-put` (trash-cli) or `gio trash`    |

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

The hook sources `~/.shell.d/*.sh` to access helper functions:

- `_ensure_age_key` - fetches AGE key from env, 1Password, or prompts
- `_enc_name` / `_plain_name` - filename conversion helpers

This avoids code duplication and ensures consistent behavior between shell functions and the hook.

### Helper Functions

| Function          | Purpose                                                   |
| ----------------- | --------------------------------------------------------- |
| `_ensure_age_key` | Fetches AGE key from env → 1Password → interactive prompt |
| `_enc_name`       | `.env` → `.enc.env`, `file.yaml` → `file.enc.yaml`        |
| `_plain_name`     | `.enc.env` → `.env`, `file.enc.yaml` → `file.yaml`        |

### Why Content Comparison (Not Hashes)

SOPS uses nonces/IVs, so re-encrypting identical content produces different ciphertext. Comparing encrypted file hashes would always show "changed". Instead:

1. Decrypt the `.enc.*` file
2. Compare decrypted content with plain file
3. Only encrypt if content actually differs

This prevents unnecessary re-encryption that would pollute git history.
