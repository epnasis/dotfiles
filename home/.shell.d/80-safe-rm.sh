# Safe rm wrapper - trash for interactive, real rm for scripts
rm() {
  # Non-interactive -> real rm (don't break scripts)
  [[ $- != *i* ]] && { command /bin/rm "$@"; return; }

  # Find trash command (macOS: trash, Linux: trash-put or gio)
  local trash_cmd
  if command -v trash &>/dev/null; then
    trash_cmd="trash"
  elif command -v trash-put &>/dev/null; then
    trash_cmd="trash-put"
  elif command -v gio &>/dev/null; then
    trash_cmd="gio trash"
  else
    echo "Warning: No trash command, using real rm" >&2
    command /bin/rm "$@"; return
  fi

  # Parse args
  local files=() has_force=false all_temp=true
  for arg in "$@"; do
    if [[ "$arg" == -* ]]; then
      [[ "$arg" == *f* ]] && has_force=true
    else
      files+=("$arg")
      if [[ -e "$arg" ]]; then
        local real=$(realpath "$arg" 2>/dev/null)
        local in_temp=false
        for tmp in "${TMPDIR:-/tmp}" /tmp /var/tmp /private/tmp; do
          local tmp_real=$(realpath "$tmp" 2>/dev/null) || continue
          [[ "$real" == "$tmp_real"/* ]] && in_temp=true && break
        done
        [[ "$in_temp" == false ]] && all_temp=false
      else
        all_temp=false
      fi
    fi
  done

  # No files (rm --help) or all temp files -> real rm
  [[ ${#files[@]} -eq 0 || "$all_temp" == true ]] && { command /bin/rm "$@"; return; }

  # Trash each file, respecting -f for non-existent
  for file in "${files[@]}"; do
    if [[ -e "$file" || -L "$file" ]]; then
      $trash_cmd "$file"
    elif [[ "$has_force" == false ]]; then
      echo "rm: $file: No such file or directory" >&2
      return 1
    fi
  done
}
