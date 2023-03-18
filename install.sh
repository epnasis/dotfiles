#!/bin/bash

link () {
	echo "[+] Creating symbolic link for: $1"
	ln -sv $(dirname $0)/$1 ~
    echo
}

echo "[+] Making vim undo directory"
mkdir -p ~/.vim/undodir
echo

for dotfile in $(dirname $0)/.*
do
    if [[ "$dotfile" =~ (\.git$|\.swp$|~|\.$) ]]; then
        continue # exclude files based on regex above
    fi
    link $dotfile
done

