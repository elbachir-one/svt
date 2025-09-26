syntax on
set nu
set rnu
set noexpandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set incsearch
set hlsearch
set nohlsearch
set cursorline
set scrolloff=10
set mouse=a
set encoding=utf-8
set t_Co=256
set timeoutlen=50
set signcolumn=yes
set lazyredraw
set ignorecase
set cb=unnamedplus
set autoindent
set ai
set colorcolumn=80
set updatetime=300
set nobackup
set nowritebackup
set noswapfile
set undofile
set undodir=/tmp
set smartcase
set list
set listchars=nbsp:¬,tab:»·,trail:·,extends:>

hi CursorLine term=bold cterm=bold ctermbg=238
hi CursorLineNr term=none cterm=none ctermbg=238 ctermfg=1
hi CursorColumn ctermbg=238 ctermfg=230
hi SignColumn ctermbg=none cterm=bold term=bold
hi Search ctermfg=0 ctermbg=9 cterm=underline term=underline
hi VertSplit ctermbg=0 ctermfg=0
hi Visual ctermbg=14 ctermfg=232

vnoremap <C-c> "+y          " Copy to clipboard in visual mode
map <C-v> "+v               " Paste from clipboard

let mapleader ="!"
nnoremap <C-n> :tabnew<Space>
nnoremap <C-k> :vertical resize -2<CR>
nnoremap <C-l> :vertical resize +2<CR>
nnoremap <TAB> :bnext<CR>
nnoremap <C-f> :Files<CR>
nnoremap <C-s> :S<CR>
nnoremap <C-d> :Tags<CR>
nnoremap <C-v> :vs<CR>
nnoremap <C-c> :ba<CR>
nnoremap <C-t> :bel vert term<CR>
nnoremap <C-p> :MarkdownPreview<CR>
nnoremap <C-x> :NERDTreeToggle<CR>
nnoremap <C-g> :0Gclog<CR>
nnoremap J :bprev<CR>
nnoremap M :bnext<CR>
nnoremap L <C-u>
nnoremap K <C-d>
nnoremap <silent> <C-o> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar>:nohl<CR>
nnoremap <C-o> :G<CR>
nnoremap <C-d> :bd<CR>

noremap m l
noremap j h
noremap k j
noremap l k

if !filereadable(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.vim}/autoload/plug.vim"'))
	echo "Downloading junegunn/vim-plug to manage plugins..."
	silent !mkdir -p ${XDG_CONFIG_HOME:-$HOME/.vim}/autoload/
	silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ${XDG_CONFIG_HOME:-$HOME/.vim}/autoload/plug.vim
	autocmd VimEnter * PlugInstall
endif

call plug#begin(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.vim}/plugged"'))
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'dense-analysis/ale'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-surround'
Plug 'plasticboy/vim-markdown'
call plug#end()

autocmd FileType gitdiff noremap m l
autocmd FileType gitdiff noremap j h
autocmd FileType gitdiff noremap k j
autocmd FileType gitdiff noremap l k

let g:fzf_preview_window = ['right:50%', 'ctrl-/']

command! S call fzf#vim#grep(
	  \   'rg --vimgrep --hidden --smart-case '.shellescape(<q-args>),
	  \   1,
	  \   fzf#vim#with_preview(),
	  \   0)
