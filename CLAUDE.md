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
