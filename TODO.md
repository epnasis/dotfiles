# TODO

## NEW FEATURES

1. Bug fixes and UX improvements

- Files that are already lined are automaticaly skipped without info why
- Little tick without color is not visible - maybe start with status as text (make status vs finame ident same vertically for easy read)
- Make EDITOR env variable `nvim` only if command exist. Otherwise fallback to `vim`
- Add colors to make selections easier - currently hard to distinguish diff
  from new file and between files as there is more focus on decision line than
  on the file name
- [S]kip is odd when paired with [y]es. Maybe Skip should become [N]o and there
  should be question to install / overwrite (if conflict)?

1. Review dotfiles from other branches and plan consolidation

- each branch has different system - review and prapear plan to integrate int single one system
- when making choice - choose best practise and valiadte. For exmple tmux start newest best one I recall is:

```
if [[ $- == *i* ]] && [[ -z "$TMUX" ]]; then  # missing check for SSH - inconsistent
   tmux new-session -A -s main && exit 0
fi
```

1. Dangling symlinks detection improvement

- Current: checks broken links in directories that exist in dotfiles/home
- Idea: smarter detection that's also performant - maybe scan shell.d specifically?

1. Install supports packages installation

- User to be abl to maintain list of packages across operating system package managers (brew, apt, dnf) for user to add new/remove - one line per tool
- Script checks OS and its package manager, compares installed packages vs. list and interactively ask it to install recommended package? Similarly to interactive dotfile install it shows [S]kip, [d]escription, [y]es, [a]ll (description of package from package manager).
