# Git configuration
alias gs='git status'

# Clone a repository from your gh repo list using fzf
ghc() {
  command -v gh >/dev/null || { echo "gh not installed"; return 1; }
  command -v fzf >/dev/null || { echo "fzf not installed"; return 1; }

  local repo
  repo=$(gh repo list | fzf | awk '{print $1}')
  [[ -n "$repo" ]] && gh repo clone "$repo"
}

_gitignore_default() {
  cat << 'EOF'
.DS_Store
node_modules/
.venv/
__pycache__/
dist/
build/
coverage/
.idea/
.vscode/
EOF
}

# Initialize git repo with optional GitHub remote
ginit() {
  local rel_path="${PWD#$HOME/}"
  local project_path="${rel_path#*/}"
  local default_name="${project_path//\//-}"
  local repo_name="$1"

  if [[ -z "$repo_name" ]]; then
    echo -n "Repo name [$default_name]: "
    read -r input_name
    repo_name="${input_name:-$default_name}"
  fi

  if [[ ! -d ".git" ]]; then
    echo "[+] Initializing local git..."
    git init

    if [[ ! -f ".gitignore" ]]; then
      _gitignore_default > .gitignore
      echo "[+] Added .gitignore from template"
    fi

    git add .
    git commit -m "initial commit"
  else
    echo "[*] Local git already initialized."
  fi

  if ! command -v gh >/dev/null; then
    echo "[!] Warning: 'gh' CLI not found. Remote creation skipped."
    return 0
  fi

  if git remote get-url origin >/dev/null 2>&1; then
    echo "[*] Remote 'origin' already exists."
  else
    if gh repo view "$repo_name" >/dev/null 2>&1; then
      echo "[!] Error: Repo '$repo_name' already exists on GitHub."
      echo "    Link manually: git remote add origin git@github.com:$(gh api user -q .login)/$repo_name.git"
      return 1
    else
      echo "[+] Creating private repo '$repo_name'..."
      gh repo create "$repo_name" --private --source=. --push
      echo "[*] Repo ready: https://github.com/$(gh api user -q .login)/$repo_name"
    fi
  fi
}
