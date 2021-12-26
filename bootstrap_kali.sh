#!/bin/bash

# Get rid of Python2 warning in Kali
[ -f ~/.hushlogin ] &&
  echo "[*] Skipping .hushlogin creating as it already exist." \
|| ( 
  echo "[+] Removing Kali's Python2 warning message in terminal"
  touch ~/.hushlogin
)

# Get dot files
[ -d ~/dotfiles ] &&
  echo "[*] Skipping dotfile download as it already exists" \
|| (
  echo "[+] Getting dotfiles from GitHub"
  cd ~
  git clone https://github.com/epnasis/dotfiles &&
  cd dotfiles &&
  git checkout kali &&
  cp -i .gitconfig ~ &&
  cp -i .inputrc ~ &&
  cp -i .tmux.conf ~ &&
  cp -i .vimrc ~ &&
  cd ~
)

# Prepare VIM undo directory
[ -d ~/.vim/undodir ] &&
  echo "[*] Skipping .vim/undodir creation as it already exist" \
|| (
  echo "[+] Creating ~/.vim/undodir"
  mkdir -p ~/.vim/undodir
)

# Get Pragmata fonts
[ -f ~/.fonts/PragmataPro_Mono.ttf ] &&
  echo "[*] Skipping PragmataPro Mono installation as it already exists" \
|| ( 
  echo "[+] Downloading PragmataPro Mono fonts from storage"
  mkdir -p ~/.fonts &&
  wget 'https://storage.googleapis.com/epnasis-bootstrap/.fonts/PragmataPro_Mono.ttf' -o ~/.fonts/PragmataPro_Mono.ttf
)

# Configure qTerminal
# get dofiles with Cobalt, config, terminal (for CTRL-H to work)

# Create SSH keys

# Enable VIM mode in zsh and bash
grep -q 'Added by bootstrap.sh' ~/.bashrc &&
  echo "[*] Skipping .zshrc and .bashrc config as it already exist." \
|| ( 
  echo "[+] Setting .zshrc and .bashrc"
  cat << 'EOF' | tee -a ~/.zshrc >> ~/.bashrc

#######################################
## Added by bootstrap.sh

# Enable VIM mode
set -o vi

# Run in tmux unless command run from Kali menu
if ! ps -f | grep -q "[e]xec-in-shell"; then
        if [ -z "$TMUX" ]; then
            tmux attach || tmux new
            tmux ls || exit
        fi
fi

EOF
)

# Tempororaly add mapping of backtick(grave) and tilde for Parallel
[ -f ~/.Xmodmap ] &&
  echo "[*] Skipping grave & tilde remappinng fro Parallels as .Xmodmap already exists." \
|| ( 
  echo "[+] Remapping grave & tilde for Parallels"
  xmodmap -e "keycode 94 = grave asciitilde grave asciitilde" &&
    xmodmap -pke > ~/.Xmodmap 
)

# Enable HiDPI mode in qTerminal
grep -q 'QT_SCALE_FACTOR=2' ~/.xsessionrc &&
  echo "[*] Skippping QT scaling factor change - already 2x set." \
|| ( 
  echo "[+] HiDPI - setting 2x scaling factor for QT"
  echo export QT_SCALE_FACTOR=2 >> ~/.xsessionrc
)

# Enable HiDPI mode in Kali
[ -f ~/.config/kali-HiDPI/xsession-settings ] &&
  echo "[*] Skipping kali-HiDPI mode - already enabled." \
|| ( 
  echo "[+] Launching HiDPI mode for Kali"
  kali-hidpi-mode
)

# Enable bigger font on login screen
grep -qE '^xft-dpi\s*=\s*192' /etc/lightdm/lightdm-gtk-greeter.conf &&
  echo "[*] Skippping bigger font on login (lightdm) - already set." \
|| ( 
  echo "[+] Enabling bigger font on logins screen (lightdm)"
  sudo sed -Ei 's/(^xft-dpi\s*=)(\s*[0-9]+)/\1 192/' /etc/lightdm/lightdm-gtk-greeter.conf
)

# Update packages and distro
echo "[+] Updating packages and dist"
sudo sh -c "
  apt-get update &&
  apt-get upgrade -y &&
  apt-get dist-upgrade -y &&
  apt-get autoremove -y "

