set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
" call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-abolish'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" Git plugin not hosted on GitHub
Plugin 'git://git.wincent.com/command-t.git'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}
"Plugin 'ycm-core/YouCompleteMe'
Plugin 'w0rp/ale'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'scrooloose/nerdtree'
Plugin 'jistr/vim-nerdtree-tabs'
" Plugin 'powerline/powerline', {'rtp': 'powerline/bindings/vim/'}
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
Plugin 'ryanoasis/vim-devicons'
Plugin 'mattn/emmet-vim'
Plugin 'prettier/vim-prettier',
Plugin 'dracula/vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'luochen1990/rainbow'
Plugin 'tpope/vim-surround'
Plugin 'godlygeek/tabular'
Plugin 'preservim/vim-markdown'
Plugin 'JamshedVesuna/vim-markdown-preview'
Plugin 'haya14busa/incsearch.vim'
Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'
Plugin 'rust-lang/rust.vim'
Plugin 'kristijanhusak/vim-carbon-now-sh'
Plugin 'Glench/Vim-Jinja2-Syntax'
Plugin 'towolf/vim-helm'
Plugin 'hashivim/vim-terraform'
Plugin 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plugin 'junegunn/fzf.vim'
Plugin 'fatih/vim-go'
Plugin 'honza/vim-snippets'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'cespare/vim-toml'
Plugin 'davewongillies/vim-eyaml'
Plugin 'rodjek/vim-puppet'
Plugin 'tomasr/molokai'
Plugin 'airblade/vim-gitgutter'
Plugin 'pearofducks/ansible-vim'
Plugin 'elixir-editors/vim-elixir'
Plugin 'mg979/vim-visual-multi'
Plugin 'rhadley-recurly/vim-terragrunt'


" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
" for vim 8


set encoding=UTF-8
set fileencoding=utf8

set t_Co=256
if (has("termguicolors"))
  set termguicolors
endif

set hlsearch
syntax on
syntax enable
set background=dark
silent! colorscheme molokai
"let g:oceanic_next_terminal_bold = 1
"let g:oceanic_next_terminal_italic = 1

"colorscheme material
"let g:material_theme_style = 'dark'
"let g:material_terminal_italics = 1
" let g:airline_theme = 'night_owl'

" NERDTree Config
let g:NERDTreeIgnore = ['\.pyc$', '\.pyo$', '__pycache__[[dir]]']
let g:NERDTreeWinPos = "left"
autocmd vimenter * NERDTree
let g:nerdtree_tabs_open_on_console_startup=1
map <Leader><Tab> <plug>NERDTreeTabsToggle<CR>

" NERD commenter Config
let g:NERDDefaultAlign = 'start'

" Vim-nerdtree-syntax-highlight config
let g:NERDTreeFileExtensionHighlightFullName = 1
let g:NERDTreeExactMatchHighlightFullName = 1
let g:NERDTreePatternMatchHighlightFullName = 1
let g:NERDTreeHighlightFolders = 1 " enables folder icon highlighting using exact match
let g:NERDTreeHighlightFoldersFullName = 1 " highlights the folder name


" IncSearch Config
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

" vim emmet config
let g:user_emmet_leader_key='<Tab>'
let g:user_emmet_settings = {
  \  'javascript.jsx' : {
    \      'extends' : 'jsx',
    \  },
  \}

"" Ale Config
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\}

" Set this variable to 1 to fix files when you save them.
let g:ale_fix_on_save = 0

" Editor Configuration
set nu
" show existing tab with 4 spaces width
set tabstop=2
" when indenting with '>', use 4 spaces width
set shiftwidth=2
" On pressing tab, insert 4 spaces
set expandtab
set omnifunc=syntaxcomplete#Complete



" Vim Markdown Preview Config
let vim_markdown_preview_github=1

" Allow one by one replacement of highlighted words
vnoremap <C-r> "hy:%s/<C-r>h//gc<left><left><left>

" Fluid Edit my .vimrc
nnoremap <leader>ev :split $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" Some of my easy mistakes mapped as abbrev
iabbrev unistal uninstall
iabbrev isntance instance

" Quotation
nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel
vnoremap <leader>" di""<esc>hpgv

" Remap esc
inoremap jk <esc>
inoremap <esc> <nop>

" Capitalize word
vnoremap <c-u> <esc>viwU
nnoremap <c-u> <esc>viwU
" Turn words to lower case
vnoremap <leader>U <esc>viwu
nnoremap <leader>U <esc>viwu


" Use space to move
nnoremap <space><space> <c-w>

" Maintain block after indenting
"vnoremap < <gv
"vnoremap > >gv

" ALE to run only on save
"let g:ale_lint_on_text_changed = 'never'
"let g:ale_lint_on_insert_leave = 0
"" linters to run on opening a file
"let g:ale_lint_on_enter = 1
"
"let g:ale_fix_on_save = 0

noremap <Leader>y "*y
noremap <Leader>p "*p
noremap <Leader>Y "+y
noremap <Leader>P "+p

" Terraform configurations
let g:terraform_align=1
let g:terraform_fold_sections=1
let g:terraform_fmt_on_save=1

" Disable Folding
set nofoldenable


" Fugitive Conflict Resolution
nnoremap <leader>gd :Gvdiffsplit!<CR>
nnoremap gdh :diffget //2<CR>
nnoremap gdl :diffget //3<CR>
nnoremap <leader>gw :Gwrite<CR>


" GitGutter
highlight GitGutterAdd    guifg=#009900 ctermfg=2
highlight GitGutterChange guifg=#bbbb00 ctermfg=3
highlight GitGutterDelete guifg=#ff2222 ctermfg=1

" update on save
autocmd BufWritePost * GitGutter

" Use relativenumber
set relativenumber

" Search and replace highlited text
vnoremap <C-r> "hy:%s/<C-r>h//gc<left><left><left>
noremap <Leader>y "*y
noremap <Leader>p "*p
noremap <Leader>Y "+y
noremap <Leader>P "+p


let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all+accept'
let g:hcl_fmt_autosave = 1
