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
link .zshrc
link .bashrc

# setup .bashrc
grep -q '~/dotfiles/.bashrc' ~/.bashrc &&
  echo "[*] Skippping .bashrc - already updated" \
|| (
  echo "[+] Updating .bashrc to include ~/dotfiles/.bashrc"
  echo -e "\n\n# added by ~/dotfiles/install.sh" >> ~/.bashrc
  echo "[ -f ~/dotfiles/.bashrc ] && . ~/dotfiles/.bashrc" >> ~/.bashrc
)

# setup .zshrc
grep -q '~/dotfiles/.bashrc' ~/.zshrc &&
  echo "[*] Skippping .zshrc - already updated" \
|| (
  echo "[+] Updating .zshrc to include ~/dotfiles/.bashrc"
  echo -e "\n\n# added by ~/dotfiles/install.sh" >> ~/.zshrc
  echo "[ -f ~/dotfiles/.bashrc ] && . ~/dotfiles/.bashrc" >> ~/.zshrc
)

