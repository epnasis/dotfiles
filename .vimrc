syntax enable
set wildmenu
set nocompatible
set ruler
set hidden
set ignorecase
set smartcase
set autoindent
set rnu
set nu

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

