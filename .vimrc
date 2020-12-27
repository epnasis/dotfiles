" =====================
" NEW
" =====================

" add line numbers
set nu
set rnu

" =====================
" SYSTEM AGNOSTIC SETUP
" =====================

set nocompatible				" go into XXI century
set encoding=utf-8				" proper encoding
set cryptmethod=blowfish2		" stronger encryption
set clipboard=unnamed			" allow copy/paste with Windows/OSX
set wildmenu					" allows tab completion menu
set backspace=indent,eol,start	" allow changing indent w/ backspace
set undofile					" allow undo - TODO add 1000 undo
set visualbell					" silence! I kill ya! ;)
set hidden						" allow to :e new file w/out asking to write changes

" Initialize pathogen to load all plugins
execute pathogen#infect()

" Look & feel
syntax on
set t_Co=256
set background=dark				" make it fit the night! :)
"colorscheme solarized				" choose colors
colorscheme cobalt2				" choose colors
set laststatus=2				" allows show status line

" Airline theme
let g:airline_theme='murmur'
let g:airline_powerline_fonts = 1
" let g:airline#extensions#whitespace#enabled = 0
" let g:airline_symbols = {}
"let g:airline_symbols.crypt = '⚓'		" choose crypt char that is actually available in my fonts

" Enable the list of buffers
let g:airline#extensions#tabline#enabled = 1

" Show just the filename
let g:airline#extensions#tabline#fnamemod = ':t'

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

" Python
au BufNewFile,BufRead *.py
    \ set tabstop=4
    \ | set softtabstop=4
    \ | set shiftwidth=4
    \ | set textwidth=79
    \ | set expandtab
    \ | set autoindent
    \ | set fileformat=unix

" Web files
au BufNewFile,BufRead *.js, *.html, *.css
    \ set tabstop=2
    \ | set softtabstop=2
    \ | set shiftwidth=2

" folding - TBC
set foldmethod=indent
set foldlevel=99

" ====================
" My keyboard mappings
" ====================
" Note: norec - means non-recursive mapping
"
let mapleader=" "

" Search
nnoremap / /\v
vnoremap / /\v
set ignorecase
set smartcase
set gdefault
set incsearch 
nnoremap <leader><space> :noh<cr>

" Move up/down
" nnoremap <space> <c-f>
" nnoremap <s-space> <c-b>
" nnoremap <backspace> <c-b>
nnoremap <d-j> <c-e>
nnoremap <d-k> <c-y>

" Indenting with tab
nnoremap <tab> >>
nnoremap <s-tab> <<
vnoremap <tab> >gv
vnoremap <s-tab> <gv

" my shortcuts
nnoremap <leader>rc :e $MYVIMRC<CR>		" edit .vimrc file
nnoremap <leader>o <c-w>o				" make it only window
nnoremap <leader>n :NERDTree<CR>		" open NERDTree
map <Leader>bg :let &background = ( &background == "dark"? "light" : "dark" )<CR>
nnoremap <leader>d :o M:\vnotes\dry.epn<CR>

" compile/run
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
            set guifont=PragmataProMonoLiga-Regular:h13
			set path+=~/vnotes

			" Launch NERDTree at startup
			"au VimEnter * NERDTree ~/vnotes/
	else
		"Unix options
	endif
endif

" =============
" WINDOWS SETUP
" =============
if has('win32')
	" Directories
	" Note - you need sync all vimfiles under $HOME/vimfiles folder
	set path+=.\**,m:\vnotes,~\vimfiles
	set undodir=%temp%\vim
	set backupdir=%temp%\vim

	" GUI setup
	"set guifont=Consolas:h9:cEASTEUROPE:qDRAFT
	set guifont=Meslo_LG_M:h9:cEASTEUROPE:qDRAFT
	set guioptions-=m  "hide menu bar
	set guioptions-=T  "hide toolbar
	set guioptions-=r  "hide right scrollbar
	set guioptions-=L  "hide left scrollbar
	set lines=30 columns=120	" default window size

	" run NERDTree 
	"au VimEnter * NERDTree M:\vnotes\
endif

