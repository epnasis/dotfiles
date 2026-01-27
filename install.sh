#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$DOTFILES_DIR/home"
ALL_NEW=false
FILE_ARGS=()
ADOPTED_FILES=()

# Summary counters
COUNT_LINKED=0
COUNT_EXISTS=0
COUNT_SKIPPED=0
COUNT_FORCED=0
COUNT_ADOPTED=0
COUNT_DELETED=0

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  GREEN=$'\e[32m'
  YELLOW=$'\e[33m'
  RED=$'\e[31m'
  CYAN=$'\e[36m'
  DIM=$'\e[2m'
  BOLD=$'\e[1m'
  RESET=$'\e[0m'
else
  GREEN="" YELLOW="" RED="" CYAN="" DIM="" BOLD="" RESET=""
fi

# Output helpers — right-aligned 12-char status column
status() {
  local color="$1" verb="$2" file="$3" note="${4:-}"
  printf "%s%12s%s  %s%s%s" "$color" "$verb" "$RESET" "$CYAN" "$file" "$RESET"
  [[ -n "$note" ]] && printf " %s%s%s" "$DIM" "$note" "$RESET"
  printf "\n"
}

section() {
  echo ""
  echo "${BOLD}$1${RESET}"
}

prompt_box() {
  local title="$1" desc="$2" options="$3"
  echo ""
  echo "┌─ ${BOLD}$title${RESET}"
  [[ -n "$desc" ]] && echo "│  ${DIM}$desc${RESET}"
  echo "│"
  echo "│  $options"
  printf "└─ Choice: "
}

summary() {
  local parts=()
  [[ $COUNT_LINKED -gt 0 ]] && parts+=("${GREEN}$COUNT_LINKED linked${RESET}")
  [[ $COUNT_ADOPTED -gt 0 ]] && parts+=("${GREEN}$COUNT_ADOPTED adopted${RESET}")
  [[ $COUNT_EXISTS -gt 0 ]] && parts+=("${DIM}$COUNT_EXISTS existed${RESET}")
  [[ $COUNT_SKIPPED -gt 0 ]] && parts+=("${YELLOW}$COUNT_SKIPPED skipped${RESET}")
  [[ $COUNT_FORCED -gt 0 ]] && parts+=("${GREEN}$COUNT_FORCED forced${RESET}")
  [[ $COUNT_DELETED -gt 0 ]] && parts+=("${YELLOW}$COUNT_DELETED deleted${RESET}")

  if [[ ${#parts[@]} -gt 0 ]]; then
    echo ""
    echo "────────────────────────────────────────"
    printf "Done: "
    local first=true
    for part in "${parts[@]}"; do
      $first || printf " ${DIM}•${RESET} "
      printf "%s" "$part"
      first=false
    done
    echo ""
  fi
}

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

  # Pipe through pager for alternate screen (returns to prompt on exit)
  {
    if command -v git >/dev/null; then
      git diff --no-index --color "$file1" "$file2" || true
    else
      diff -u "$file1" "$file2" || true
    fi
  } | if command -v less >/dev/null; then less -R; else cat; fi
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
  printf "             %s↳ backed up to backups/%s%s\n" "$DIM" "$name.$timestamp" "$RESET"
}

handle_conflict() {
  local src="$1" dest="$2" name="$3"

  prompt_box "Conflict: $name" "Existing file differs from dotfiles version" "[d]iff  [f]orce  [s]kip  [q]uit"

  while true; do
    local choice
    choice=$(read_char)
    case "$choice" in
      d|D) show_diff "$dest" "$src" ;;
      f|F)
        echo ""
        backup_file "$dest" "$name"
        ln -sfn "$src" "$dest"
        status "$GREEN" "Forced" "$name"; ((COUNT_FORCED++)); return 0
        ;;
      ""|s|S) echo ""; status "$YELLOW" "Skipped" "$name"; ((COUNT_SKIPPED++)); return 0 ;;
      q|Q) echo "Quit."; exit 1 ;;
    esac
  done
}

handle_new() {
  local src="$1" dest="$2" name="$3"

  if $ALL_NEW; then
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    status "$GREEN" "Linked" "$name"
    ((COUNT_LINKED++))
    return 0
  fi

  prompt_box "Install: $name" "New file, not yet in your home directory" "[y]es  [n]o  [v]iew  [a]ll  [q]uit"

  while true; do
    local choice
    choice=$(read_char)
    case "$choice" in
      v|V) show_file "$src"; continue ;;
      a|A) ALL_NEW=true ;;
      y|Y) ;;
      ""|n|s|S) echo ""; status "$YELLOW" "Skipped" "$name"; ((COUNT_SKIPPED++)); return 0 ;;
      q|Q) echo "Quit."; exit 1 ;;
      *) continue ;;
    esac
    # Reached here means y|Y or a|A - do the link
    echo ""
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    status "$GREEN" "Linked" "$name"
    ((COUNT_LINKED++))
    return 0
  done
}

setup_rc() {
  local rc="$1"
  local name="${rc##*/}"  # basename without subshell
  [[ -f "$rc" ]] || return 0
  if grep -q "# --- dotfiles ---" "$rc"; then
    status "$DIM" "Exists" "$name" "(already configured)"
    return 0
  fi

  cat >> "$rc" << 'EOF'

# --- dotfiles ---
for f in ~/.shell.d/*.sh; do [[ -f "$f" ]] && . "$f"; done
# --- end dotfiles ---
EOF
  status "$GREEN" "Updated" "$name" "(added shell.d loader)"
}

handle_broken_link() {
  local link="$1"
  local name="${link#$HOME/}"
  local target
  target=$(readlink "$link")

  prompt_box "Broken: $name" "Target missing: $target" "[d]elete  [s]kip  [q]uit"

  while true; do
    local choice
    choice=$(read_char)
    case "$choice" in
      d|D) echo ""; rm "$link"; status "$YELLOW" "Deleted" "$name"; ((COUNT_DELETED++)); return 0 ;;
      ""|s|S) echo ""; status "$YELLOW" "Skipped" "$name"; ((COUNT_SKIPPED++)); return 0 ;;
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
    echo "${RED}Error:${RESET} Cannot resolve path: $path" >&2
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

  echo "${RED}Error:${RESET} File must be inside \$HOME or dotfiles: $path" >&2
  CLASSIFY_RESULT="error"
  return 1
}

# Install a single dotfile (create symlink from $HOME to dotfiles)
install_file() {
  local src="$1" dest="$2" name="$3"

  # Already correctly symlinked
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    status "$DIM" "Exists" "$name" "(already linked)"
    ((COUNT_EXISTS++))
    return 0
  fi

  # Exists (file or wrong symlink)
  if [[ -e "$dest" || -L "$dest" ]]; then
    if diff -q "$dest" "$src" >/dev/null 2>&1; then
      ln -sfn "$src" "$dest"
      status "$GREEN" "Linked" "$name" "(same content)"
      ((COUNT_LINKED++))
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
    status "$DIM" "Exists" "$rel" "(already managed)"
    ((COUNT_EXISTS++))
    return 0
  fi

  # No existing dotfile - simple adopt
  if [[ ! -e "$dotfile" ]]; then
    mkdir -p "$(dirname "$dotfile")"
    mv "$home_file" "$dotfile"
    ln -s "$dotfile" "$home_file"
    status "$GREEN" "Adopted" "$rel"
    ((COUNT_ADOPTED++))
    ADOPTED_FILES+=("$rel")
    return 0
  fi

  # Dotfile exists with same content - just replace with symlink
  if diff -q "$home_file" "$dotfile" >/dev/null 2>&1; then
    rm "$home_file"
    ln -s "$dotfile" "$home_file"
    status "$GREEN" "Adopted" "$rel" "(same content)"
    ((COUNT_ADOPTED++))
    ADOPTED_FILES+=("$rel")
    return 0
  fi

  # Conflict: home file differs from existing dotfile
  prompt_box "Adopt conflict: $rel" "File differs from existing dotfile version" "[d]iff  [f]orce  [s]kip  [q]uit"

  while true; do
    local choice
    choice=$(read_char)
    case "$choice" in
      d|D) show_diff "$home_file" "$dotfile" ;;
      f|F)
        echo ""
        backup_file "$dotfile" "$rel"
        mv "$home_file" "$dotfile"
        ln -s "$dotfile" "$home_file"
        status "$GREEN" "Adopted" "$rel"
        ((COUNT_ADOPTED++))
        ADOPTED_FILES+=("$rel")
        return 0
        ;;
      ""|s|S) echo ""; status "$YELLOW" "Skipped" "$rel"; ((COUNT_SKIPPED++)); return 0 ;;
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
        echo "${RED}Error:${RESET} File must be inside home/: $path" >&2
        return 1
      fi
      ;;
    home)
      # File inside $HOME - adopt it
      if [[ ! -f "$CLASSIFY_PATH" ]]; then
        echo "${RED}Error:${RESET} Not a file: $path" >&2
        return 1
      fi
      adopt_file "$CLASSIFY_PATH"
      ;;
  esac
}

check_broken_links() {
  local broken_links=()
  local dirs_to_check=()

  # Build list of $HOME directories that mirror our dotfiles structure
  while IFS= read -r rel_dir; do
    rel_dir="${rel_dir#./}"
    local target_dir="${rel_dir:+$HOME/$rel_dir}"
    target_dir="${target_dir:-$HOME}"
    [[ -d "$target_dir" ]] && dirs_to_check+=("$target_dir")
  done < <(find . -type d)

  # Single find call across all directories (much faster than N separate calls)
  if [[ ${#dirs_to_check[@]} -gt 0 ]]; then
    while IFS= read -r link; do
      [[ ! -e "$link" ]] && broken_links+=("$link")
    done < <(find "${dirs_to_check[@]}" -maxdepth 1 -type l 2>/dev/null)
  fi

  # Process interactively with for loop (avoids stdin conflicts)
  if [[ ${#broken_links[@]} -gt 0 ]]; then
    section "Checking symlinks..."
    for link in "${broken_links[@]}"; do
      handle_broken_link "$link"
    done
  fi
}

# Main flow: file args or install all
if [[ ${#FILE_ARGS[@]} -gt 0 ]]; then
  section "Processing files..."
  # Process specific file arguments
  for arg in "${FILE_ARGS[@]}"; do
    process_file_arg "$arg"
  done
else
  # Install all dotfiles
  cd "$HOME_DIR"
  check_broken_links

  section "Installing dotfiles..."
  # Collect files first, then process with for loop (avoids stdin conflicts with interactive prompts)
  files=()
  while IFS= read -r file; do
    files+=("${file#./}")
  done < <(find . -type f | sort)

  for file in "${files[@]}"; do
    install_file "$PWD/$file" ~/"$file" "$file"
  done

  section "Shell configuration..."
  setup_rc ~/.bashrc
  setup_rc ~/.zshrc
fi

# Show summary
summary

# Git reminder if files were adopted
if [[ ${#ADOPTED_FILES[@]} -gt 0 ]]; then
  echo ""
  echo "${YELLOW}Reminder:${RESET} Adopted files need to be committed:"
  echo "  cd $DOTFILES_DIR && git add -A && git commit"
fi
