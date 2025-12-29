# ----------------------------------------------------------------- 
#  Repo Utils
# ----------------------------------------------------------------- 

ginit() {
  # --- 1. Determine Repo Name ---
  local rel_path="${PWD#$HOME/}"
  local project_path="${rel_path#*/}"
  local default_name="${project_path//\//-}"
  local repo_name="$1"

  if [ -z "$repo_name" ]; then
    echo -n "Repo name [$default_name]: "
    read -r input_name
    repo_name="${input_name:-$default_name}"
  fi

  # --- 2. Local Init ---
  if [ ! -d ".git" ]; then
    echo "[+] Initializing local git..."
    git init
    
    if [ ! -f ".gitignore" ]; then
      local template="$HOME/dotfiles/templates/gitignore_default"
      if [ -f "$template" ]; then
        cp "$template" .gitignore
        echo "[+] Added .gitignore from template"
      fi
    fi
    
    git add .
    git commit -m "initial commit"
  else
    echo "[*] Local git already initialized."
  fi

  # --- 3. Remote Creation ---
  if ! command -v gh >/dev/null 2>&1; then
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

genc() {
    if ! command -v sops >/dev/null 2>&1; then
        echo "[!] Error: SOPS is not installed. (brew install sops age)"
        return 1
    fi

    # --- 1. Gitignore Security ---
    if [ ! -f .gitignore ]; then
        local template="$HOME/dotfiles/templates/gitignore_default"
        if [ -f "$template" ]; then
            cp "$template" .gitignore
            echo "[+] Created .gitignore from template"
        else
            touch .gitignore
        fi
    fi

    # Ensure secrets patterns exist (idempotent)
    if ! grep -Fq "secrets/*" .gitignore; then
        echo "" >> .gitignore
        echo "# Secrets (SOPS encrypted)" >> .gitignore
        echo ".env" >> .gitignore
        echo "!.env.enc" >> .gitignore
        echo "secrets/*" >> .gitignore
        echo "!secrets/*.enc" >> .gitignore
        echo "[+] Added secrets security rules to .gitignore"
    fi

    # --- 2. SOPS Config (Lazy Init) ---
    local pub_key_file="$HOME/dotfiles/.age_public_key"
    
    if [ ! -f "$pub_key_file" ]; then
        echo -n "[?] Enter your Age Public Key (age1...) to initialize SOPS: "
        read -r user_pub_key
        if [[ "$user_pub_key" == age1* ]]; then
            echo "$user_pub_key" > "$pub_key_file"
            echo "[+] Saved public key to $pub_key_file"
        else
            echo "[!] Invalid key format. Skipping config generation."
        fi
    fi

    if [ ! -f ".sops.yaml" ] && [ -f "$pub_key_file" ]; then
        local pub_key=$(cat "$pub_key_file")
        echo "[+] Generating .sops.yaml..."
        cat <<EOF > .sops.yaml
creation_rules:
  - path_regex: (\.env$|\.enc\.env|secrets/.*)
    key_groups:
      - age:
          - "$pub_key"
EOF

        echo "    [*] Setup complete. Create secrets then run 'enc' to encrypt."
    fi

    # --- 3. Decryption ---
    _ensure_age_key || return 1

    echo "[*] Decrypting files..."
    local count=0
    # Find .enc.env and *.enc.* files
    while IFS= read -r encrypted_file; do
        local target_file=$(_plain_name "$encrypted_file")
        if [ ! -f "$target_file" ] || [ "$encrypted_file" -nt "$target_file" ]; then
            echo "    [+] Decrypting $encrypted_file -> $target_file"
            if sops -d "$encrypted_file" > "$target_file"; then
                ((count++))
            else
                echo "    [!] Failed to decrypt $encrypted_file"
            fi
        else
            echo "    [*] Skipping $encrypted_file (Up to date)"
        fi
    done < <(find . -type f \( -name ".enc.env*" -o -name "*.enc.*" \))

    [ "$count" -eq 0 ] && echo "[*] No new secrets to decrypt." || echo "[*] Decrypted $count files."

    # --- 5. Install Pre-commit Hook ---
    if [ -d ".git" ]; then
        genc_hook
    fi
}

_ensure_age_key() {
    # Ensure SOPS_AGE_KEY is set, fetching from 1Password or prompting if needed
    local age_key="$SOPS_AGE_KEY"
    local ref_file="$HOME/dotfiles/.age_key_ref"

    # A. Check Environment
    if [ -n "$age_key" ]; then
        return 0

    # B. Check 1Password Reference
    elif [ -f "$ref_file" ] && command -v op >/dev/null 2>&1; then
        echo "[op] Fetching key from 1Password..."
        age_key=$(op read "$(cat "$ref_file")" 2>/dev/null)
        if [ -n "$age_key" ]; then
            export SOPS_AGE_KEY="$age_key"
            return 0
        else
            echo "[!] Failed to read key from 1Password."
        fi
    fi

    # C. Interactive Prompt
    if [ -z "$age_key" ]; then
        if command -v op >/dev/null 2>&1; then
            echo "[?] 1Password CLI detected."
            read -r "op_ref?🔑 Paste your 1Password Item Reference (op://...) to save it: "
            op_ref="${op_ref//\"/}"

            if [[ "$op_ref" == op://* ]]; then
                echo "[op] Validating reference..."
                local test_key=$(op read "$op_ref" 2>/dev/null)
                if [ -n "$test_key" ]; then
                    echo "$op_ref" > "$ref_file"
                    echo "[+] Reference verified and saved to $ref_file"
                    export SOPS_AGE_KEY="$test_key"
                    return 0
                else
                    echo "[!] Error: Could not read secret from provided reference."
                fi
            else
                echo "[!] Invalid reference format. Falling back to raw key."
            fi
        fi

        if [ -z "$SOPS_AGE_KEY" ]; then
            read -rs "age_key?🔑 Paste your raw AGE Secret Key: "
            echo ""
            if [ -z "$age_key" ]; then
                echo "[!] Error: No key provided."
                return 1
            fi
            export SOPS_AGE_KEY="$age_key"
        fi
    fi
    return 0
}

_enc_name() {
    # Convert plain filename to encrypted: .env -> .enc.env, file.yaml -> file.enc.yaml
    local file="$1"
    local dir=$(dirname "$file")
    local base=$(basename "$file")

    if [[ "$base" == .env* ]]; then
        # .env or .env.local -> .enc.env or .enc.env.local
        echo "${dir}/.enc.${base#.}"
    else
        # file.yaml -> file.enc.yaml
        local name="${base%.*}"
        local ext="${base##*.}"
        echo "${dir}/${name}.enc.${ext}"
    fi
}

_plain_name() {
    # Convert encrypted filename to plain: .enc.env -> .env, file.enc.yaml -> file.yaml
    local file="$1"
    local dir=$(dirname "$file")
    local base=$(basename "$file")

    if [[ "$base" == .enc.env* ]]; then
        # .enc.env or .enc.env.local -> .env or .env.local
        echo "${dir}/.env${base#.enc.env}"
    else
        # file.enc.yaml -> file.yaml
        echo "${dir}/${base/.enc/}"
    fi
}

enc() {
    # Encrypt files (skips unchanged). Pattern: .env -> .enc.env, file.yaml -> file.enc.yaml
    # Usage: enc .env
    #        enc secrets/db.yaml secrets/api.yaml
    #        enc  (no args = encrypt all known unencrypted secrets)

    _ensure_age_key || return 1

    local files=("$@")

    # No args: find all unencrypted secret files
    if [ ${#files[@]} -eq 0 ]; then
        files=()
        [ -f ".env" ] && files+=(".env")
        if [ -d "secrets" ]; then
            for f in secrets/*; do
                [[ -f "$f" && ! "$f" =~ \.enc\. ]] && files+=("$f")
            done
        fi
        if [ ${#files[@]} -eq 0 ]; then
            echo "[*] No unencrypted secret files found"
            return 0
        fi
        echo "[*] Found ${#files[@]} file(s) to check"
    fi

    local encrypted_count=0
    local skipped_count=0
    local errors=0

    for plain in "${files[@]}"; do
        if [ ! -f "$plain" ]; then
            echo "[!] File not found: $plain"
            ((errors++))
            continue
        fi

        local encrypted=$(_enc_name "$plain")

        # Check if encrypted file exists and content matches
        if [ -f "$encrypted" ]; then
            local decrypted=$(sops -d "$encrypted" 2>/dev/null)
            local current=$(cat "$plain")
            if [[ "$decrypted" == "$current" ]]; then
                echo "[*] Skipping $plain (unchanged)"
                ((skipped_count++))
                continue
            fi
        fi

        echo "[+] Encrypting $plain -> $encrypted"
        if sops -e "$plain" > "$encrypted"; then
            # Sync plain file with SOPS-normalized format to avoid hook comparison issues
            sops -d "$encrypted" > "$plain" 2>/dev/null
            ((encrypted_count++))
        else
            echo "[!] Failed to encrypt $plain"
            ((errors++))
        fi
    done

    [ $encrypted_count -gt 0 ] && echo "[*] Encrypted $encrypted_count file(s)"
    [ $skipped_count -gt 0 ] && echo "[*] Skipped $skipped_count unchanged file(s)"
    [ $errors -gt 0 ] && echo "[!] $errors error(s) occurred" && return 1
    return 0
}

genc_hook() {
    if [ ! -d ".git" ]; then
        echo "[!] Error: Not a git repository."
        return 1
    fi

    mkdir -p .git/hooks

    cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# Pre-commit hook: verify encrypted secrets are in sync
# Pattern: .env -> .enc.env, file.yaml -> file.enc.yaml

source "$HOME/dotfiles/functions/repo_utils.zsh" 2>/dev/null || {
    echo "[!] Could not source repo_utils.zsh, skipping secrets check"
    exit 0
}

_ensure_age_key 2>/dev/null || {
    echo "[!] SOPS_AGE_KEY not available, skipping secrets check"
    exit 0
}

check_secret() {
    local plain="$1"
    local encrypted="$2"

    if [[ -f "$plain" && -f "$encrypted" ]]; then
        decrypted=$(sops -d "$encrypted" 2>/dev/null)
        current=$(cat "$plain")
        if [[ "$decrypted" != "$current" ]]; then
            echo "WARNING: $plain differs from $encrypted"
            echo "  Run: enc $plain"
            return 1
        fi
    elif [[ -f "$plain" && ! -f "$encrypted" ]]; then
        echo "WARNING: $plain exists but $encrypted does not"
        echo "  Run: enc $plain"
        return 1
    fi
    return 0
}

errors=0

# Check .env -> .enc.env
check_secret ".env" ".enc.env" || ((errors++))

# Check secrets/ directory
if [[ -d "secrets" ]]; then
    # Check each encrypted file has matching plain file in sync
    for enc_file in secrets/*.enc.*; do
        [[ -f "$enc_file" ]] || continue
        plain=$(_plain_name "$enc_file")
        check_secret "$plain" "$enc_file" || ((errors++))
    done

    # Check each plain file has encrypted counterpart
    for plain in secrets/*; do
        [[ -f "$plain" && ! "$plain" =~ \.enc\. ]] || continue
        enc_file=$(_enc_name "$plain")
        if [[ ! -f "$enc_file" ]]; then
            echo "WARNING: $plain has no encrypted version"
            echo "  Run: enc $plain"
            ((errors++))
        fi
    done
fi

if ((errors > 0)); then
    echo ""
    echo "Found $errors secret(s) out of sync. Commit blocked."
    exit 1
fi
HOOK

    chmod +x .git/hooks/pre-commit
    echo "[+] Installed pre-commit hook for secrets sync validation"
}
