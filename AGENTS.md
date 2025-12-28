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
- `gsec` — set up SOPS/Age workflow, update `.gitignore`, and decrypt `*.enc` files.

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
- Encrypted secrets are stored as `*.enc` files. Use `gsec` to manage `.sops.yaml` and decrypt into read-only files.
- `gsec` expects an Age public key in `~/.age_public_key` or a 1Password reference in `~/.age_key_ref`.
