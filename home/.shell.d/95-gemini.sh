# Gemini CLI helper: cd to ~/gemini if in home directory, then run gemini
command -v gemini >/dev/null || return

gemini() {
  if [[ "$PWD" == "$HOME" && "$#" -eq 0 ]]; then
    cd "$HOME/gemini" || return
  fi
  command gemini "$@"
}

alias gg=gemini
