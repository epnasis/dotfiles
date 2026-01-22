#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$DOTFILES_DIR/home"
ALL_NEW=false
FILE_ARGS=()
ADOPTED_FILES=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [FILE...]

Install dotfiles by creating symlinks from \$HOME to this repository.

Options:
  --all     Install all dotfiles without prompting
  --help    Show this help message

Modes:
  No arguments    Interactive install of all dotfiles
  FILE...         Install or adopt specific files

File arguments:
  Inside dotfiles/  Install that specific dotfile (create symlink)
  Inside \$HOME      Adopt file into dotfiles (move + symlink)

Examples:
  $(basename "$0")                    # Interactive install all
  $(basename "$0") --all              # Non-interactive install all
  $(basename "$0") home/.vimrc        # Install specific dotfile
  $(basename "$0") ~/.config/app.conf # Adopt file into dotfiles

Symbols: ✓ installed  · already linked  - skipped
EOF
}

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --all) ALL_NEW=true ;;
    --help|-h) usage; exit 0 ;;
    *) FILE_ARGS+=("$arg") ;;
  esac
done

read_char() {
  local char
  read -n 1 -s char </dev/tty
  echo "$char"
}

show_file() {
  local file="$1"
  if command -v bat >/dev/null; then
    bat --style=plain --paging=always "$file"
  elif command -v less >/dev/null; then
    less "$file"
  elif command -v more >/dev/null; then
    more "$file"
  else
    cat "$file"
  fi
}

show_diff() {
  local file1="$1" file2="$2"
  
  if command -v realpath >/dev/null; then
    file1=$(realpath "$file1")
    file2=$(realpath "$file2")
  fi

  echo ""
  if command -v git >/dev/null; then
    git diff --no-index --color-words "$file1" "$file2" || true
  else
    diff -u "$file1" "$file2" || true
  fi
}

BACKUP_DIR="$DOTFILES_DIR/backups"

backup_file() {
  local file="$1"
  local name="$2"
  local timestamp
  timestamp=$(date +"%Y%m%d_%H%M%S")
  local backup_path="$BACKUP_DIR/$name.$timestamp"

  mkdir -p "$(dirname "$backup_path")"
  mv "$file" "$backup_path"
  echo "  ↳ Backed up to backups/$name.$timestamp"
}

handle_conflict() {
  local src="$1" dest="$2" name="$3"

  while true; do
    echo ""
    echo "Overwrite conflict: $name (existing file differs)"
    echo "[N]o / [d]iff / [f]orce / [q]uit? "
    local choice
    choice=$(read_char)
    echo ""

    case "$choice" in
      ""|n|N|s|S) echo "- $name (skipped)"; return 0 ;;
      d|D) show_diff "$dest" "$src" ;;
      f|F)
        backup_file "$dest" "$name"
        ln -sfn "$src" "$dest"
        echo "✓ $name (forced)"; return 0
        ;;
      q|Q) echo "Quit."; exit 1 ;;
    esac
  done
}

handle_new() {
  local src="$1" dest="$2" name="$3"

  if $ALL_NEW; then
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "✓ $name"
    return 0
  fi

  while true; do
    echo ""
    echo "Install: $name"
    echo "[N]o / / [y]es / [a]ll / [v]iew / [q]uit? "
    local choice
    choice=$(read_char)
    echo ""

    case "$choice" in
      ""|n|N|s|S) echo "- $name (skipped)"; return 0 ;;
      v|V) show_file "$src" ;;
      y|Y) mkdir -p "$(dirname "$dest")"; ln -s "$src" "$dest"; echo "✓ $name"; return 0 ;;
      a|A) ALL_NEW=true; mkdir -p "$(dirname "$dest")"; ln -s "$src" "$dest"; echo "✓ $name"; return 0 ;;
      q|Q) echo "Quit."; exit 1 ;;
    esac
  done
}

setup_rc() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0
  if grep -q "# --- dotfiles ---" "$rc"; then
    echo "· $rc (already configured)"
    return 0
  fi

  cat >> "$rc" << 'EOF'

# --- dotfiles ---
for f in ~/.shell.d/*.sh; do [[ -f "$f" ]] && . "$f"; done
# --- end dotfiles ---
EOF
  echo "✓ Updated $rc"
}

handle_broken_link() {
  local link="$1"
  while true; do
    echo ""
    echo "Broken symlink: $link"
    echo "Target: $(readlink "$link")"
    echo "[D]elete / [s]kip / [q]uit?"
    local choice
    choice=$(read_char)

    case "$choice" in
      d|D) rm "$link"; echo "✓ Deleted"; return 0 ;;
      s|S|""|n|N) echo "- Skipped"; return 0 ;;
      q|Q) echo "Quit."; exit 1 ;;
    esac
  done
}

# Classify a path as 'dotfile', 'home', or 'error'
# Returns via global CLASSIFY_RESULT
classify_path() {
  local path="$1"
  local abs_path

  # Resolve to absolute path
  if [[ "$path" = /* ]]; then
    abs_path="$path"
  else
    abs_path="$PWD/$path"
  fi

  # Normalize path (resolve .., remove trailing /)
  abs_path="$(cd "$(dirname "$abs_path")" 2>/dev/null && pwd)/$(basename "$abs_path")" || {
    echo "Error: Cannot resolve path: $path" >&2
    CLASSIFY_RESULT="error"
    return 1
  }

  # Check if inside dotfiles
  if [[ "$abs_path" == "$DOTFILES_DIR/"* ]]; then
    CLASSIFY_RESULT="dotfile"
    CLASSIFY_PATH="$abs_path"
    return 0
  fi

  # Check if inside $HOME
  if [[ "$abs_path" == "$HOME/"* ]]; then
    CLASSIFY_RESULT="home"
    CLASSIFY_PATH="$abs_path"
    return 0
  fi

  echo "Error: File must be inside $HOME or $DOTFILES_DIR: $path" >&2
  CLASSIFY_RESULT="error"
  return 1
}

# Install a single dotfile (create symlink from $HOME to dotfiles)
install_file() {
  local src="$1" dest="$2" name="$3"

  # Already correctly symlinked
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "· $name"
    return 0
  fi

  # Exists (file or wrong symlink)
  if [[ -e "$dest" || -L "$dest" ]]; then
    if diff -q "$dest" "$src" >/dev/null 2>&1; then
      ln -sfn "$src" "$dest"
      echo "✓ $name (same content)"
      return 0
    fi
    handle_conflict "$src" "$dest" "$name"
    return 0
  fi

  # New file
  handle_new "$src" "$dest" "$name"
}

# Adopt a file from $HOME into dotfiles, then create symlink
adopt_file() {
  local home_file="$1"
  local rel="${home_file#$HOME/}"
  local dotfile="$HOME_DIR/$rel"

  # Already symlinked to dotfiles
  if [[ -L "$home_file" && "$(readlink "$home_file")" == "$dotfile" ]]; then
    echo "· $rel (already managed)"
    return 0
  fi

  # No existing dotfile - simple adopt
  if [[ ! -e "$dotfile" ]]; then
    mkdir -p "$(dirname "$dotfile")"
    mv "$home_file" "$dotfile"
    ln -s "$dotfile" "$home_file"
    echo "✓ $rel (adopted)"
    ADOPTED_FILES+=("$rel")
    return 0
  fi

  # Dotfile exists with same content - just replace with symlink
  if diff -q "$home_file" "$dotfile" >/dev/null 2>&1; then
    rm "$home_file"
    ln -s "$dotfile" "$home_file"
    echo "✓ $rel (adopted)"
    ADOPTED_FILES+=("$rel")
    return 0
  fi

  # Conflict: home file differs from existing dotfile
  while true; do
    echo ""
    echo "Adopt conflict: $rel (differs from existing dotfile)"
    echo "[N]o / [d]iff / [f]orce / [q]uit? "
    local choice
    choice=$(read_char)
    echo ""

    case "$choice" in
      ""|n|N|s|S) echo "- $rel (skipped)"; return 0 ;;
      d|D) show_diff "$home_file" "$dotfile" ;;
      f|F)
        backup_file "$dotfile" "$rel"
        mv "$home_file" "$dotfile"
        ln -s "$dotfile" "$home_file"
        echo "✓ $rel (adopted)"
        ADOPTED_FILES+=("$rel")
        return 0
        ;;
      q|Q) echo "Quit."; exit 1 ;;
    esac
  done
}

# Process a file argument based on its location
process_file_arg() {
  local path="$1"

  if ! classify_path "$path"; then
    return 1
  fi

  case "$CLASSIFY_RESULT" in
    dotfile)
      # File inside dotfiles - install it
      if [[ "$CLASSIFY_PATH" == "$HOME_DIR/"* ]]; then
        local rel="${CLASSIFY_PATH#$HOME_DIR/}"
        install_file "$CLASSIFY_PATH" "$HOME/$rel" "$rel"
      else
        echo "Error: File must be inside $HOME_DIR: $path" >&2
        return 1
      fi
      ;;
    home)
      # File inside $HOME - adopt it
      if [[ ! -f "$CLASSIFY_PATH" ]]; then
        echo "Error: Not a file: $path" >&2
        return 1
      fi
      adopt_file "$CLASSIFY_PATH"
      ;;
  esac
}

check_broken_links() {
  echo "--- Checking for broken symlinks in managed directories ---"
  # Scan directories that exist in our dotfiles source
  find . -type d | while read -r rel_dir; do
    rel_dir="${rel_dir#./}"
    local target_dir
    if [[ -z "$rel_dir" ]]; then
      target_dir="$HOME"
    else
      target_dir="$HOME/$rel_dir"
    fi

    [[ -d "$target_dir" ]] || continue

    # Find broken symlinks in the target directory (non-recursive)
    # Using a process substitution loop to handle paths safely
    while IFS= read -r link; do
      if [[ ! -e "$link" ]]; then
        handle_broken_link "$link"
      fi
    done < <(find "$target_dir" -maxdepth 1 -type l)
  done
  echo "--- Done checking broken links ---"
  echo ""
}

# Main flow: file args or install all
if [[ ${#FILE_ARGS[@]} -gt 0 ]]; then
  # Process specific file arguments
  for arg in "${FILE_ARGS[@]}"; do
    process_file_arg "$arg"
  done
else
  # Install all dotfiles
  cd "$HOME_DIR"
  check_broken_links

  find . -type f | sort | while read -r file; do
    file="${file#./}"
    install_file "$PWD/$file" ~/"$file" "$file"
  done

  echo ""
  setup_rc ~/.bashrc
  setup_rc ~/.zshrc
fi

# Git reminder if files were adopted
if [[ ${#ADOPTED_FILES[@]} -gt 0 ]]; then
  echo ""
  echo "Adopted ${#ADOPTED_FILES[@]} file(s) into dotfiles."
  echo "Remember to commit:"
  echo "  cd $DOTFILES_DIR && git add -A && git commit"
fi
