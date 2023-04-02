#!/bin/bash

link () {
	echo "[+] Creating symbolic link for: $1"
	ln -sv $1 ~
    echo
}

echo "[+] Making vim undo directory"
mkdir -p ~/.vim/undodir
mkdir -p ~/.vim/swpdir
echo

for dotfile in $(dirname $0)/.*
do
    if [[ "$(basename $dotfile)" =~ (^\.git$|^\.gitignore$|\.swp$|~|\.$) ]]; then
        continue # exclude files based on regex above
    fi
    link $dotfile
done

