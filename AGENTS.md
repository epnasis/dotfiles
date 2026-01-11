# Repository Guidelines

## Project Structure
- Dotfiles live under `home/` and are symlinked into `~` (e.g., `home/.vimrc`, `home/.gitconfig`).
- `home/.shell.d/` contains shell helpers sourced by `.bashrc`/`.zshrc`.
- `templates/` stores reusable scaffolding such as `templates/gitignore_default`.
- `install.sh` creates symlinks into `$HOME` and appends a `~/.shell.d` loader to `~/.bashrc`/`~/.zshrc`.

## Setup, Build, and Development Commands
- `./install.sh` — symlinks all dotfiles in `home/` into `~` and adds the loader to shell rc files.
- `ginit [repo-name]` — initialize a local git repo and optionally create a private GitHub repo via `gh`.
- `genc` — set up SOPS/Age workflow, update `.gitignore`, decrypt `.enc.*` files, and install pre-commit hook.
- `enc [files]` — encrypt file(s), or all unencrypted secrets if no args. Skips unchanged files to avoid polluting git history.
- `genc_hook` — manually install/reinstall the secrets sync pre-commit hook.

## Coding Style & Naming Conventions
- Shell scripts are bash/zsh; use 2-space indentation and keep functions short.
- Prefer lowercase file names for templates; dotfiles retain their standard names (e.g., `.zshrc`).
- When adding functions, keep related utilities grouped in `functions/` and add brief section headers.

## Testing Guidelines
- No automated tests are defined. When changing scripts, run them manually in a safe environment and verify expected side effects (e.g., created symlinks, updated files).

## Commit & Pull Request Guidelines
- Recent commits use short, imperative messages, sometimes with a `fix:` prefix. Follow the same style (e.g., `add zsh alias`, `fix: gsec key lookup`).
- Keep PRs focused; describe the dotfiles or functions touched and any manual verification performed.

## Security & Configuration Notes
- Encrypted secrets use `.enc.*` pattern: `.env` → `.enc.env`, `file.yaml` → `file.enc.yaml`.
- `genc` expects an Age public key in `~/dotfiles/.age_public_key` or a 1Password reference in `~/dotfiles/.age_key_ref`.
- Pre-commit hook blocks commits when plain files differ from their encrypted counterparts (content-based check).

## Session Notes (2025-01-18)
- Fixed portability and startup safety in `.zshrc`, `.bashrc`, and `.vimrc`, and documented repo guidelines in `AGENTS.md`.
- Vim colorscheme issue: `cobalt2` uses hex values for `ctermfg`; with only `termguicolors`, Vim can hit `E421`. Restoring `set t_Co=256` keeps `cobalt2` on its 256-color branch while still enabling truecolor.
- Windows-specific Vim settings were removed; `.vimrc` now targets macOS + terminal Vim.
- Validation: `zsh -n`, `bash -n`, and `vim -V1 -i NONE -Nu NONE -n -es +'source ~/.vimrc' +q` were used to verify syntax/config.

## Repo Review (2025-02-14)
### Findings
- `install.sh` reads `find` output with whitespace splitting, so files with spaces (e.g., `home/.config/bat/themes/Catppuccin Mocha.tmTheme`) can be skipped or mis-symlinked. (`install.sh:108`)
- `install.sh` does not create `~/.vim/undodir` or `~/.vim/swpdir` even though `.vimrc` expects them. (`home/.vimrc:20-21`)
- `genc_hook` sources every file in `~/.shell.d`, which can run interactive prompts or unrelated side effects during commits. (`home/.shell.d/75-sops.sh:227-236`)
- `ginit` embeds a `.gitignore` template that can drift from `templates/gitignore_default`. (`home/.shell.d/60-git.sh:14-25`)
- `.tmux.conf` uses `bc` for version comparisons without guarding for its absence, which can break the keybinding setup on minimal installs. (`home/.tmux.conf:88-92`)

### Proposals
- Switch `install.sh` to `find -print0` and a null-delimited read loop, and optionally add a non-interactive `--all`/`--yes` path for CI use.
- Add creation of `~/.vim/undodir` and `~/.vim/swpdir` in `install.sh` (or adjust `.vimrc` to use existing directories only).
- Move SOPS helpers into a dedicated file (e.g., `home/.shell.d/75-sops-lib.sh`) and source only that in hooks to avoid side effects.
- Make `ginit` read from `templates/gitignore_default` to keep templates single-sourced.
- Guard the `bc` usage or replace with a pure tmux version check using string compare in `if-shell`.

### Plan
1. Fix `install.sh` path handling and add the Vim directory creation step.
2. Isolate SOPS functions into a hook-safe file and update `genc_hook` to source only that file.
3. Wire `ginit` to use `templates/gitignore_default` and add a brief README for onboarding.
4. Update `.tmux.conf` to avoid `bc` dependency or add a conditional guard.
