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

