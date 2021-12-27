#!/bin/bash

link () {
	echo "[+] Creating symbolic link for: $1"
	ln -svr $(dirname $0)/$1 ~
}

echo "[+] Making vim undo directory"
mkdir -p ~/.vim/undodir

link .gitconfig
link .inputrc
link .vimrc
link .tmux.conf

# setup .bashrc
grep -q '~/dotfiles/.localrc' ~/.bashrc &&
  echo "[*] Skippping .bashrc - already updated" \
|| (
  echo "[+] Updating .bashrc to include ~/dotfiles/.localrc"
  echo -e "\n\n# added by ~/dotfiles/install.sh" >> ~/.bashrc
  echo "[ -f ~/dotfiles/.localrc ] && . ~/dotfiles/.localrc" >> ~/.bashrc
)

# setup .zshrc
grep -q '~/dotfiles/.localrc' ~/.zshrc &&
  echo "[*] Skippping .zshrc - already updated" \
|| (
  echo "[+] Updating .zshrc to include ~/dotfiles/.localrc"
  echo -e "\n\n# added by ~/dotfiles/install.sh" >> ~/.zshrc
  echo "[ -f ~/dotfiles/.localrc ] && . ~/dotfiles/.localrc" >> ~/.zshrc
)

