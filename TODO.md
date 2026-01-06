# TODO

## NEW FEATURES

1. Bug fixes and UX improvements

- Files that are already lined are automaticaly skipped without info why
- Little tick without color is not visible - maybe start with status as text (make status vs finame ident same vertically for easy read)

1. Review dotfiles from other branches and plan consolidation

- each branch has different system - review and prapear plan to integrate int single one system
- when making choice - choose best practise and valiadte. For exmple tmux start newest best one I recall is:

```
if [[ $- == *i* ]] && [[ -z "$TMUX" ]]; then  # missing check for SSH - inconsistent
   tmux new-session -A -s main && exit 0
fi
```

1. Enhance install.sh to support files arugment - multiple files or any glob pattern. It has different effect depending on file location:

- If files are from dotfiles path (its directory or subdirs) then install dotfiles as if all-yes options - install but handle conflicts.
- If outside of dotfiles but inside $HOME path then add these files to dotfiles by moving files with path relative to home to dotfiles/home and installing it to create symlink so that as of that moment dotfile is used via symlink. When successful add reminder to add & commit changes to git repo (brief)

1. Install supports packages installation

- User to be abl to maintain list of packages across operating system package managers (brew, apt, dnf) for user to add new/remove - one line per tool
- Script checks OS and its package manager, compares installed packages vs. list and interactively ask it to install recommended package? Similarly to interactive dotfile install it shows [S]kip, [d]escription, [y]es, [a]ll (description of package from package manager).
