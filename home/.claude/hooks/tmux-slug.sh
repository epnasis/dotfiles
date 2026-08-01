#!/usr/bin/env bash
# tmux pane-title-changed hook: keep the window name a short slug of the task.
# Claude Code writes its task summary to the pane title; when the summary TEXT
# changes (not just the spinner glyph), ask Haiku to compress it to a <=12-char
# slug and rename the window.
# Invoked by tmux as: tmux-slug.sh <title> <window_id> <pane_current_command>
set -euo pipefail

# tmux run-shell uses a minimal PATH; claude lives in ~/.local/bin
PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

# No claude on this machine: leave window names to tmux's automatic-rename fallback
command -v claude >/dev/null 2>&1 || exit 0

title="${1:-}"
window="${2:-}"
cmd="${3:-}"
[ -n "$window" ] || exit 0

# Only summarize titles from coding agents; other title-setters (yazi, shells)
# should keep tmux's automatic-rename name instead. Claude Code's process name
# is its bare version number, e.g. "2.1.201". docker/podman cover containerized
# agents (the cld sandbox function).
case "$cmd" in
  claude|agy|codex|node|docker|podman) ;;
  *) printf '%s' "$cmd" | grep -Eq '^[0-9]+(\.[0-9]+)*$' || exit 0 ;;
esac

# Strip spinner glyph / leading symbols; ignore short non-task titles (shell noise)
text=$(printf '%s' "$title" | sed -E 's/^[^a-zA-Z0-9]+//')
[ "${#text}" -lt 15 ] && exit 0

# The cache records a COMPLETED naming: the title text and the slug the window
# actually carries. tmux-session-title.sh reads it to decide whether a window
# name was derived from the session asking, so it must never claim a name the
# rename below has not applied yet — hence the separate in-flight marker rather
# than writing the cache up front.
cache_dir="$HOME/.cache/tmux-slug"
mkdir -p "$cache_dir"
find "$cache_dir" -name '*.pending' -mmin +10 -delete 2>/dev/null || true
cache="$cache_dir/${window#@}"
pending="$cache.pending"
[ -f "$cache" ] && [ "$(head -n 1 "$cache")" = "$text" ] && exit 0
[ -f "$pending" ] && [ "$(cat "$pending")" = "$text" ] && exit 0
printf '%s' "$text" > "$pending"

slug=$(claude -p --model haiku \
  "Summarize this coding task as a tmux window name: a single lowercase slug, max 12 characters, only a-z 0-9 and dashes. Reply with the slug only, nothing else. Task: ${text:0:300}" \
  2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-' | cut -c1-12) || true

# claude failing (offline, auth, ...) leaves the last completed naming in place
# and clears the marker, so the next title change retries
if [ -n "$slug" ]; then
  tmux rename-window -t "$window" "$slug"
  printf '%s\n%s\n' "$text" "$slug" > "$cache.tmp" && mv -f "$cache.tmp" "$cache"
fi
rm -f "$pending"
