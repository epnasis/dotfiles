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
