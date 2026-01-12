# PATH modifications

# Homebrew (macOS)
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:$PATH"
[[ -d $HOME/homebrew/bin ]] && export PATH="$HOME/homebrew/bin:$PATH"
[[ -d /usr/local/bin ]] && export PATH="/usr/local/bin:$PATH"

# Local bin
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

# Ruby (macOS)
if [[ -d /opt/homebrew/opt/ruby/bin ]]; then
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
elif [[ -d /usr/local/opt/ruby/bin ]]; then
  export PATH="/usr/local/opt/ruby/bin:$PATH"
fi

# Python (macOS Homebrew)
if [[ -d /opt/homebrew/opt/python/libexec/bin ]]; then
  export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"
elif [[ -d /usr/local/opt/python/libexec/bin ]]; then
  export PATH="/usr/local/opt/python/libexec/bin:$PATH"
fi

# Windsurf/Codeium
[[ -d "$HOME/.codeium/windsurf/bin" ]] && export PATH="$HOME/.codeium/windsurf/bin:$PATH"
