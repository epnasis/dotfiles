# Repository Guidelines

## Project Structure
- Root dotfiles live at repo root (e.g., `.zshrc`, `.vimrc`, `.gitconfig`).
- `functions/` contains shell helpers (notably `functions/repo_utils.zsh`).
- `templates/` stores reusable scaffolding such as `templates/gitignore_default`.
- `install.sh` creates symlinks into `$HOME` and prepares Vim swap/undo dirs.

## Setup, Build, and Development Commands
- `./install.sh` — symlinks all dotfiles in this repo into `~` and creates `~/.vim/undodir` and `~/.vim/swpdir`.
- `source functions/repo_utils.zsh` — load helper functions into your shell.
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
