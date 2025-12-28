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

gsec() {
    if ! command -v sops >/dev/null 2>&1; then
        echo "[!] Error: SOPS is not installed. (brew install sops age)"
        return 1
    fi

    # --- 1. Gitignore Security ---
    if [ ! -f .gitignore ]; then touch .gitignore; fi
    
    if ! grep -Fxq ".env" .gitignore; then
        echo ".env" >> .gitignore
        echo "[+] Added .env to .gitignore"
    fi
    
    if ! grep -Fxq "!.env.enc" .gitignore; then
        echo "!.env.enc" >> .gitignore
        echo "[+] Whitelisted .env.enc in .gitignore"
    fi
    
    if ! grep -Fq "secrets/*" .gitignore; then
        echo "" >> .gitignore
        echo "secrets/*" >> .gitignore
        echo "!secrets/*.enc" >> .gitignore
        echo "[+] Added secrets/ security rules to .gitignore"
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
  - path_regex: secrets/.*\.enc$
    key_groups:
      - age:
          - "$pub_key"
  - path_regex: \.env\.enc$
    key_groups:
      - age:
          - "$pub_key"
EOF
        
        # Reminder for the user
        echo "    [*] Setup complete. To add a secret file:"
        echo "    1. sops .env.enc"
        echo "    2. mkdir secrets && sops secrets/any.json.enc"
    fi

    # --- 3. Decryption ---
    local age_key="$SOPS_AGE_KEY"
    local ref_file="$HOME/dotfiles/.age_key_ref"

    # A. Check Environment
    if [ -n "$age_key" ]; then
        echo "[*] Using SOPS_AGE_KEY from environment"
    
    # B. Check 1Password Reference
    elif [ -f "$ref_file" ] && command -v op >/dev/null 2>&1; then
        echo "[op] Fetching key from 1Password..."
        age_key=$(op read "$(cat "$ref_file")" 2>/dev/null)
        if [ -n "$age_key" ]; then
             export SOPS_AGE_KEY="$age_key"
        else
             echo "[!] Failed to read key from 1Password."
        fi
    fi

    # C. Interactive Prompt
    if [ -z "$age_key" ]; then
        if command -v op >/dev/null 2>&1; then
            echo "[?] 1Password CLI detected."
            read -r "op_ref?🔑 Paste your 1Password Item Reference (op://...) to save it: "
            # Strip all double quotes
            op_ref="${op_ref//\"/}"
            
            if [[ "$op_ref" == op://* ]]; then
                echo "[op] Validating reference..."
                local test_key=$(op read "$op_ref" 2>/dev/null)
                if [ -n "$test_key" ]; then
                    echo "$op_ref" > "$ref_file"
                    echo "[+] Reference verified and saved to $ref_file"
                    age_key="$test_key"
                    export SOPS_AGE_KEY="$age_key"
                else
                    echo "[!] Error: Could not read secret from provided reference. Not saving."
                fi
            else
                 echo "[!] Invalid reference format. Falling back to raw key."
            fi
        fi
        
        if [ -z "$age_key" ]; then
            read -rs "age_key?🔑 Paste your raw AGE Secret Key: "
            echo ""
            if [ -z "$age_key" ]; then
                echo "[!] Error: No key provided."
                return 1
            fi
            export SOPS_AGE_KEY="$age_key"
        fi
    fi

    echo "[*] Decrypting files..."
    local count=0
    while IFS= read -r encrypted_file; do
        local target_file="${encrypted_file%.enc}"
        if [ ! -f "$target_file" ] || [ "$encrypted_file" -nt "$target_file" ]; then
            echo "    [+] Decrypting $encrypted_file -> $target_file"
            if ! sops -d "$encrypted_file" > "$target_file"; then
                echo "    [!] Failed to decrypt $encrypted_file"
            else
                ((count++))
            fi
        else
            echo "    [*] Skipping $encrypted_file (Up to date)"
        fi
    done < <(find . -type f -name "*.enc")
    
    [ "$count" -eq 0 ] && echo "[*] No new secrets to decrypt." || echo "[*] Decrypted $count files."
}
