# SOPS/AGE secrets management
command -v sops >/dev/null || return

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

_ensure_age_key() {
  local age_key="$SOPS_AGE_KEY"
  local ref_file="$DOTFILES_DIR/.age_key_ref"

  if [[ -n "$age_key" ]]; then
    return 0
  elif [[ -f "$ref_file" ]] && command -v op >/dev/null; then
    echo "[op] Fetching key from 1Password..."
    age_key=$(op read "$(cat "$ref_file")" 2>/dev/null)
    if [[ -n "$age_key" ]]; then
      export SOPS_AGE_KEY="$age_key"
      return 0
    else
      echo "[!] Failed to read key from 1Password."
    fi
  fi

  if [[ -z "$age_key" ]]; then
    if command -v op >/dev/null; then
      echo "[?] 1Password CLI detected."
      local op_ref
      if [[ -n "$ZSH_VERSION" ]]; then
        read -r "op_ref?Paste your 1Password Item Reference (op://...) to save it: "
      else
        read -r -p "Paste your 1Password Item Reference (op://...) to save it: " op_ref
      fi
      op_ref="${op_ref//\"/}"

      if [[ "$op_ref" == op://* ]]; then
        echo "[op] Validating reference..."
        local test_key=$(op read "$op_ref" 2>/dev/null)
        if [[ -n "$test_key" ]]; then
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

    if [[ -z "$SOPS_AGE_KEY" ]]; then
      local age_key
      if [[ -n "$ZSH_VERSION" ]]; then
        read -rs "age_key?Paste your raw AGE Secret Key: "
      else
        read -rs -p "Paste your raw AGE Secret Key: " age_key
      fi
      echo ""
      if [[ -z "$age_key" ]]; then
        echo "[!] Error: No key provided."
        return 1
      fi
      export SOPS_AGE_KEY="$age_key"
    fi
  fi
  return 0
}

_enc_name() {
  local file="$1"
  local dir=$(dirname "$file")
  local base=$(basename "$file")

  if [[ "$base" == .env* ]]; then
    echo "${dir}/.enc.${base#.}"
  else
    local name="${base%.*}"
    local ext="${base##*.}"
    echo "${dir}/${name}.enc.${ext}"
  fi
}

_plain_name() {
  local file="$1"
  local dir=$(dirname "$file")
  local base=$(basename "$file")

  if [[ "$base" == .enc.env* ]]; then
    echo "${dir}/.env${base#.enc.env}"
  else
    echo "${dir}/${base/.enc/}"
  fi
}

genc() {
  if [[ ! -f .gitignore ]]; then
    echo "[!] No .gitignore found. Run ginit first or create one."
    return 1
  fi

  # Add secrets patterns if missing
  if ! grep -Fq "secrets/*" .gitignore; then
    echo "" >> .gitignore
    echo "# Secrets (SOPS encrypted)" >> .gitignore
    echo ".env" >> .gitignore
    echo ".env.*" >> .gitignore
    echo "!.enc.env*" >> .gitignore
    echo "secrets/*" >> .gitignore
    echo "!secrets/*.enc.*" >> .gitignore
    echo "[+] Added secrets security rules to .gitignore"
  fi

  local pub_key_file="$DOTFILES_DIR/.age_public_key"

  if [[ ! -f "$pub_key_file" ]]; then
    echo -n "[?] Enter your Age Public Key (age1...) to initialize SOPS: "
    local user_pub_key
    read -r user_pub_key
    if [[ "$user_pub_key" == age1* ]]; then
      echo "$user_pub_key" > "$pub_key_file"
      echo "[+] Saved public key to $pub_key_file"
    else
      echo "[!] Invalid key format. Skipping config generation."
    fi
  fi

  if [[ ! -f ".sops.yaml" && -f "$pub_key_file" ]]; then
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

  _ensure_age_key || return 1

  echo "[*] Decrypting files..."
  local count=0
  while IFS= read -r encrypted_file; do
    local target_file=$(_plain_name "$encrypted_file")
    if [[ ! -f "$target_file" || "$encrypted_file" -nt "$target_file" ]]; then
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

  [[ "$count" -eq 0 ]] && echo "[*] No new secrets to decrypt." || echo "[*] Decrypted $count files."

  [[ -d ".git" ]] && genc_hook
}

enc() {
  _ensure_age_key || return 1

  local files=("$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    files=()
    [[ -f ".env" ]] && files+=(".env")
    if [[ -d "secrets" ]]; then
      for f in secrets/*; do
        [[ -f "$f" && ! "$f" =~ \.enc\. ]] && files+=("$f")
      done
    fi
    if [[ ${#files[@]} -eq 0 ]]; then
      echo "[*] No unencrypted secret files found"
      return 0
    fi
    echo "[*] Found ${#files[@]} file(s) to check"
  fi

  local encrypted_count=0 skipped_count=0 errors=0

  for plain in "${files[@]}"; do
    if [[ ! -f "$plain" ]]; then
      echo "[!] File not found: $plain"
      ((errors++))
      continue
    fi

    local encrypted=$(_enc_name "$plain")

    if [[ -f "$encrypted" ]]; then
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
      sops -d "$encrypted" > "$plain" 2>/dev/null
      ((encrypted_count++))
    else
      echo "[!] Failed to encrypt $plain"
      ((errors++))
    fi
  done

  [[ $encrypted_count -gt 0 ]] && echo "[*] Encrypted $encrypted_count file(s)"
  [[ $skipped_count -gt 0 ]] && echo "[*] Skipped $skipped_count unchanged file(s)"
  [[ $errors -gt 0 ]] && echo "[!] $errors error(s) occurred" && return 1
  return 0
}

genc_hook() {
  if [[ ! -d ".git" ]]; then
    echo "[!] Error: Not a git repository."
    return 1
  fi

  mkdir -p .git/hooks

  cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# Pre-commit hook: verify encrypted secrets are in sync

for f in "$HOME/.shell.d"/*.sh; do [[ -f "$f" ]] && . "$f"; done 2>/dev/null

command -v sops >/dev/null || exit 0

_ensure_age_key 2>/dev/null || {
  echo "[!] SOPS_AGE_KEY not available, skipping secrets check"
  exit 0
}

check_secret() {
  local plain="$1" encrypted="$2"

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
check_secret ".env" ".enc.env" || ((errors++))

if [[ -d "secrets" ]]; then
  for enc_file in secrets/*.enc.*; do
    [[ -f "$enc_file" ]] || continue
    plain=$(_plain_name "$enc_file")
    check_secret "$plain" "$enc_file" || ((errors++))
  done

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
