#!/usr/bin/env bash
# Claude Code hook: adopt the tmux window name as the session title.
#
# tmux-slug.sh already compresses this session's title into a short window name.
# This copies that name back, so the same string is what shows in the prompt
# box, /resume, the terminal title, and the session list on the phone. Going
# through the hook (rather than writing the transcript) is what pushes the new
# title to the bridge, so a running session is renamed in the app too.
#
# Only adopts a name derived from THIS session. A window reused for a new
# session still carries the previous task's name, and adopting it would stick,
# because a short custom title stops tmux-slug.sh from ever re-slugging. The
# slug cache records a completed naming — either side of it matching this
# session's title proves the window is ours, so `tmux rename-window` is also a
# way to rename the session. (Only until the next adoption: renaming by hand
# twice without a re-slug in between leaves the cache matching neither.)
set -euo pipefail

[ -n "${TMUX:-}" ] || exit 0
[ -n "${TMUX_PANE:-}" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat)
event=$(printf '%s' "$payload" | jq -r '.hook_event_name // "UserPromptSubmit"')
transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // ""')
[ -f "$transcript" ] || exit 0

window=$(tmux display-message -p -t "$TMUX_PANE" '#{window_name}' 2>/dev/null || true)
window_id=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null || true)
[ -n "$window" ] && [ -n "$window_id" ] || exit 0

# A name tmux truncated to fit the status bar would shrink the real title
case "$window" in *…) exit 0 ;; esac

# Claude re-appends an ai-title record most turns, so the last title record is
# usually the ai one even when a custom title is set and winning. Resolve the
# way Claude Code does — custom over ai — rather than by file order.
titles=$(tail -n 2000 "$transcript" |
  jq -rR 'fromjson? | select(.type=="custom-title" or .type=="ai-title")
          | "\(.type) \(.customTitle // .aiTitle)"' 2>/dev/null || true)
current=$(printf '%s\n' "$titles" | sed -n 's/^custom-title //p' | tail -n 1)
[ -n "$current" ] || current=$(printf '%s\n' "$titles" | sed -n 's/^ai-title //p' | tail -n 1)
[ -n "$current" ] || exit 0
[ "$window" != "$current" ] || exit 0

cache="$HOME/.cache/tmux-slug/${window_id#@}"
[ -f "$cache" ] || exit 0
cached_text=$(sed -n '1p' "$cache")
cached_slug=$(sed -n '2p' "$cache")
[ "$cached_text" = "$current" ] || [ "$cached_slug" = "$current" ] || exit 0

jq -cn --arg title "$window" --arg event "$event" \
  '{hookSpecificOutput: {hookEventName: $event, sessionTitle: $title}}'
