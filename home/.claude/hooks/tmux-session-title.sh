#!/usr/bin/env bash
# Claude Code hook: adopt the tmux window name as the session title.
#
# tmux-slug.sh already compresses this session's title into a short window name.
# This copies that name back, so the same string is what shows in the prompt
# box, /resume, the terminal title, and the session list on the phone. Going
# through the hook (rather than writing the transcript) is what pushes the new
# title to the bridge, so a running session is renamed in the app too.
#
# Only adopts a name tmux-slug.sh derived from THIS session: a window reused for
# a new session still carries the previous task's name, and adopting it would
# stick, because a short custom title stops tmux-slug.sh from ever re-slugging.
# The slug cache holds the text a window name was computed from — when that text
# is this session's own title, the name is ours to take.
set -euo pipefail

[ -n "${TMUX:-}" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat)
event=$(printf '%s' "$payload" | jq -r '.hook_event_name // "UserPromptSubmit"')
transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // ""')
[ -f "$transcript" ] || exit 0

pane_args=()
[ -n "${TMUX_PANE:-}" ] && pane_args=(-t "$TMUX_PANE")
window=$(tmux display-message -p "${pane_args[@]}" '#{window_name}' 2>/dev/null || true)
window_id=$(tmux display-message -p "${pane_args[@]}" '#{window_id}' 2>/dev/null || true)
[ -n "$window" ] && [ -n "$window_id" ] || exit 0

# A name tmux truncated to fit the status bar would shrink the real title
case "$window" in *…) exit 0 ;; esac

titles=$(tail -n 500 "$transcript" |
  jq -rR 'fromjson? | select(.type=="custom-title" or .type=="ai-title") | .customTitle // .aiTitle' 2>/dev/null || true)
current=$(printf '%s\n' "$titles" | grep -v '^$' | tail -n 1)
[ -n "$current" ] || exit 0
[ "$window" != "$current" ] || exit 0

slug_cache="$HOME/.cache/tmux-slug/${window_id#@}"
[ -f "$slug_cache" ] || exit 0
[ "$(cat "$slug_cache")" = "$current" ] || exit 0

jq -cn --arg title "$window" --arg event "$event" \
  '{hookSpecificOutput: {hookEventName: $event, sessionTitle: $title}}'
