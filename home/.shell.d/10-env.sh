# Environment variables
if command -v nvim >/dev/null 2>&1; then
  export EDITOR='nvim'
else
  export EDITOR='vim'
fi
export LANG=en_US.UTF-8
export UV_PYTHON_PREFERENCE="only-managed"
