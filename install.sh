#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
ALL_NEW=false

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --all) ALL_NEW=true ;;
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
  echo ""
  if command -v git >/dev/null; then
    git diff --no-index --color-words "$file1" "$file2" || true
  else
    diff -u "$file1" "$file2" || true
  fi
}

handle_conflict() {
  local src="$1" dest="$2" name="$3"

  while true; do
    echo ""
    echo "Conflict: $name (existing file differs)"
    printf "[S]kip / [d]iff / [f]orce / [q]uit? "
    local choice
    choice=$(read_char)
    echo ""

    case "$choice" in
      ""|s|S) echo "- $name (skipped)"; return 0 ;;
      d|D) show_diff "$dest" "$src" ;;
      f|F) ln -sfn "$src" "$dest"; echo "✓ $name (forced)"; return 0 ;;
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
    printf "New: $name - [S]kip / [v]iew / [y]es / [a]ll / [q]uit? "
    local choice
    choice=$(read_char)
    echo ""

    case "$choice" in
      ""|s|S) echo "- $name (skipped)"; return 0 ;;
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

cd "$DOTFILES_DIR/home"

find . -type f | sort | while read -r file; do
  file="${file#./}"
  src="$PWD/$file"
  dest=~/"$file"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "· $file"
    continue
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    if diff -q "$dest" "$src" >/dev/null 2>&1; then
      ln -sfn "$src" "$dest"
      echo "✓ $file (same content)"
      continue
    fi
    handle_conflict "$src" "$dest" "$file"
    continue
  fi

  handle_new "$src" "$dest" "$file"
done

echo ""
setup_rc ~/.bashrc
setup_rc ~/.zshrc
