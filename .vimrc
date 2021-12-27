syntax enable
set wildmenu
set nocompatible
set ruler
set hidden
set ignorecase
set smartcase
set autoindent

" line numbers
set rnu
set nu

" Tabs
" tabstop         - how many spaces will tab character show up as visually
" shiftwidth     - how many spaces to shift < or > when you indent - should be
"                   same as tab stops
" expandtab     - replace tab character with spaces (as many as tabstop says)
" smarttab        - <BS> will remove 4 (=tabstop) spaces no just 1
" softabstop     -
" autoindent    -
set listchars=tab:>\ ,extends:>,precedes:<
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent

colorscheme slate

nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" move vertically by visual line
nnoremap j gj
nnoremap k gk

let mapleader=" "
nnoremap <leader>e :vsp $MYVIMRC<CR>

" allow undo between sessions
set undofile
set undodir=~/.vim/undodir


" VIM & TMUX navigation
" Source: https://gist.github.com/mislav/5189704#gistcomment-3312967
function! TmuxMove(direction)
        let wnr = winnr()
        silent! execute 'wincmd ' . a:direction
        " If the winnr is still the same after we moved, it is the last pane
        if wnr == winnr()
                call system('tmux select-pane -' . tr(a:direction, 'phjkl', 'lLDUR'))
        end
endfunction

nnoremap <silent> <C-h> :call TmuxMove('h')<cr>
nnoremap <silent> <C-j> :call TmuxMove('j')<cr>
nnoremap <silent> <C-k> :call TmuxMove('k')<cr>
nnoremap <silent> <C-l> :call TmuxMove('l')<cr>
