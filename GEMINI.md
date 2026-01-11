# Dotfiles Analysis & Improvement Plan

## 1. Findings & Critique

### 🚨 Critical Issues
*   **Destructive Installation (`install.sh`)**: The current script uses `ln -sfn` which force-deletes existing files/directories at the destination. There is **no backup mechanism**. If you accidentally run this on a machine with important local configs (e.g., a distinct `.zshrc` or uncommitted secrets), they will be irretrievably lost.
*   **Hardcoded Secrets in Version Control**: `home/.gitconfig` contains your full name, email, and SSH signing key. This makes the dotfiles non-portable (e.g., for work vs. personal use) and risks exposing sensitive data if the repo is ever made public.
*   **Invasive Shell Integration**: The `setup_rc` function unconditionally appends a `source` block to shell RC files. Running the installer multiple times can lead to duplicate entries or conflicting blocks.
*   **Fragile Vim Configuration**: `.vimrc` defines persistent undo/swap directories (`~/.vim/undodir`), but the installer does not ensure these directories exist. This leads to immediate errors on a fresh install.

### ⚠️ Observations
*   **Implicit Dependencies**: The setup assumes many tools are installed (`starship`, `bat`, `fzf`, `rg`, `sops`) but provides no manifest (like a `Brewfile`) to verify or install them.
*   **Manual Intervention Required**: The user must manually handle `age` keys and some 1Password integrations without clear guidance or automated checks in the install process.

## 2. Suggestions & Best Practices

### ✅ Safer Installation Logic
*   **Automatic Backups**: Before overwriting any file, move the existing version to a timestamped backup directory (e.g., `~/.dotfiles_backup/YYYYMMDD_HHMMSS/`).
*   **Idempotency**: Check if a symlink is already correct before attempting to link.
*   **Dry Run**: Add a `--dry-run` flag to preview changes without modifying the filesystem.

### ✅ Modular Configuration
*   **Split Git Config**: Use Git's `[include]` directive. Keep generic aliases/settings in the tracked `.gitconfig` and move personal identity/keys to an untracked `~/.gitconfig.local`.
*   **Template Generation**: The installer should generate a template `.gitconfig.local` if it doesn't exist.

### ✅ Dependency Management
*   **Brewfile**: Create a `Brewfile` to list all binary and cask dependencies. This allows for one-command setup (`brew bundle`) on new macOS machines.

## 3. Implementation Plan

1.  **Refactor `install.sh`**:
    *   Implement `backup_file` function.
    *   Add dry-run capability.
    *   Ensure `~/.vim/{undodir,swpdir}` directories are created.
    *   Remove the invasive `setup_rc` appending logic in favor of a manual instruction or a cleaner "manager" script approach.

2.  **Modularize `.gitconfig`**:
    *   Edit `home/.gitconfig` to remove `[user]` and `[gpg]` sections.
    *   Add `[include] path = ~/.gitconfig.local`.
    *   Update `install.sh` to create a `~/.gitconfig.local` template with your current details (Name, Email, Key) *only* if the file doesn't exist.

3.  **Create `Brewfile`**:
    *   Catalog used tools (`bat`, `fzf`, `gh`, `starship`, `nvim`, etc.) and create a `Brewfile` in the root directory.

4.  **Verify**:
    *   Run `install.sh --dry-run` to verify logic.
    *   Check directory creation.
