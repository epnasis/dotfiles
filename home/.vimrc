" =====================
" NEW
" =====================

let mapleader=" "

" Enable project drawer mode by default
let g:fern#default_drawer_width = 30

" Map toggle
nnoremap <silent> <Leader>f :Fern . -drawer -reveal=% -toggle<CR>

" add line numbers
set nu
set rnu

language messages en_US

" =====================
" Curor type per mode
" =====================
" Set cursor to vertical bar in Insert Mode
let &t_SI = "\e[5 q"
" Set cursor to block in Normal Mode
let &t_SR = "\e[3 q"
" Set cursor to block when leaving Insert Mode
let &t_EI = "\e[2 q"

" =====================
" SYSTEM AGNOSTIC SETUP
" =====================

set nocompatible				" go into XXI century
set encoding=utf-8				" proper encoding
set cryptmethod=blowfish2		" stronger encryption
set wildmenu					" allows tab completion menu
set backspace=indent,eol,start	" allow changing indent w/ backspace
set visualbell					" silence! I kill ya! ;)
set hidden						" allow to :e new file w/out asking to write changes

" allow undo between sessions
set undofile
set undodir=~/.vim/undodir,.
set dir=~/.vim/swpdir,.

" allow copy/paste with macOS clipboard
"set clipboard=unnamedplus

"
" Look & feel
syntax on
set t_Co=256
if has("termguicolors")
	set termguicolors
endif
set background=dark				" make it fit the night! :)
colorscheme catppuccin_mocha
set laststatus=2				" allows show status line

" Airline theme
let g:airline_powerline_fonts = 1
" let g:airline#extensions#whitespace#enabled = 0
" let g:airline_symbols = {}
"let g:airline_symbols.crypt = '⚓'		" choose crypt char that is actually available in my fonts

" Enable the list of buffers
let g:airline#extensions#tabline#enabled = 1

" Show just the filename
let g:airline#extensions#tabline#fnamemod = ':t'

" For git gutter
set updatetime=100

" Wrapping
set wrap			" wrap by default
set linebreak		" break full words
set breakindent		" visually same indent after break

" Wrapping - jump between displayed not physical lines
noremap  <silent> k gk
noremap  <silent> j gj
noremap  <silent> 0 g0
noremap  <silent> $ g$

" Tabs
" tabstop 		- how many spaces will tab character show up as visually
" shiftwidth 	- how many spaces to shift < or > when you indent - should be
" 				  same as tab stops
" expandtab 	- replace tab character with spaces (as many as tabstop says)
" smarttab		- <BS> will remove 4 (=tabstop) spaces no just 1
" softabstop 	-
" autoindent	-
set listchars=tab:>\ ,extends:>,precedes:<
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent

" Recognize file types
filetype plugin indent on

" Copy without line numbers
set mouse+=a

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %

" markdown files
au BufRead *.md
    \ set tw=79
    \ | set formatoptions+=t
    \ | set formatoptions-=ro
    \ | set scrolloff=5

" Python
au FileType python
    \ set tabstop=2                 " how many spaces to represent tab when displaying
    \ | set softtabstop=2           " how many space tab represent when editing (using backspace & tab)
    \ | set shiftwidth=2            " shifting with > and < moves by shiftwidth
    \ | set textwidth=79            " break lines when line length increases
    \ | set expandtab               " enter spaces when tab is pressed
    \ | set autoindent
    \ | set fileformat=unix

" Web files
au BufNewFile,BufRead *.js,*.html,*.css
    \ set tabstop=2
    \ | set softtabstop=2
    \ | set shiftwidth=2

" folding - TBC
set foldmethod=indent
set foldlevel=99

" vim-terraform
let g:terraform_align=1
let g:terraform_fold_sections=1
let g:terraform_fmt_on_save=1


" ====================
" My keyboard mappings
" ====================
" Note: norec - means non-recursive mapping
"

" Search
" nnoremap / /\v
" vnoremap / /\v
set ignorecase
set smartcase
"set gdefault
set incsearch
nnoremap <leader><space> :noh<cr>

" Move up/down
" nnoremap <space> <c-f>
" nnoremap <s-space> <c-b>
" nnoremap <backspace> <c-b>
nnoremap <d-j> <c-e>
nnoremap <d-k> <c-y>

" Explorer
nnoremap <leader>e :Ex<CR>

" Indenting with tab
nnoremap <tab> >>
nnoremap <s-tab> <<
vnoremap <tab> >gv
vnoremap <s-tab> <gv

" my shortcuts
nnoremap <leader>ev :tabe $MYVIMRC<CR>	" edit .vimrc file
nnoremap <leader>sv :source $MYVIMRC<CR>	" reload .vimrc file
nnoremap <leader>rc :tabe $MYVIMRC<CR>	" edit .vimrc file
nnoremap <leader>o <c-w>o				" make it only window
nnoremap <leader>n :NERDTree<CR>		" open NERDTree
map <Leader>bg :let &background = ( &background == "dark"? "light" : "dark" )<CR>

nnoremap <C-p> :<C-u>FZF<CR>
nnoremap <M-p> :<C-u>FZF<CR>

" compile/run
nnoremap <leader>rp :w<CR>:!python %<CR>
nnoremap <leader>cc :w<CR>:make %<<CR>
nnoremap <leader>cm :w<CR>:make<CR>
nnoremap <leader>co :!./%<<CR>

" toggle fold
nnoremap <leader>, za
" ---------------
" ASCII underline
" ---------------
nnoremap <leader>- yypllv$r-k						" Create underline with '-'
nnoremap <leader>_ yypllv$r-yykPjll					" Create upper/bottom '-'
nnoremap <leader>= yypllv$r=k						" Create underline with '='
nnoremap <leader>+ yypllv$r=yykPjll					" Create upper/bottom '='

" Split new window
set splitbelow
set splitright

" Split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Auto replace
iabbrev <expr> cd; strftime("%Y-%m-%d")		" replaced cd; with current date

" Autochange dir to current buffer
autocmd BufEnter * silent! lcd %:p:h

" ====================
" MAC OSX / UNIX setup
" ====================
if has("unix")
	let s:uname = system("uname")
	if s:uname == "Darwin\n"
		"Mac options
			if has("gui_running")
				set guifont=PragmataProMonoLiga-Regular:h14
			endif
			set path+=~/vnotes

			" Launch NERDTree at startup
			"au VimEnter * NERDTree ~/vnotes/
	else
		"Unix options
	endif
endif
