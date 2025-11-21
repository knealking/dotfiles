set encoding=utf-8    " Set UTF 8 encoding
set number            " Show line numbers

set expandtab         " Use spaces instead of tabs
set tabstop=4         " Number of spaces for a tab
set shiftwidth=4      " Number of spaces to use for autoindent
set softtabstop=4     " Number of spaces for <Tab> key

set autoindent        " Enable automatic indentation
set smartindent       " Smarter indentation based on the code structure
set smartcase

set nowrap            " Wrap off
set noswapfile        " Don't save swap file

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline'
call plug#end()

let &t_SI = "\<Esc>]50;CursorShape=1\x7" " Vertical bar in insert mode
let &t_EI = "\<Esc>]50;CursorShape=0\x7" " Block in normal mode

let mapleader = "\<Space>"

set rtp+=/opt/homebrew/opt/fzf

" NERDTree keymaps
nnoremap <C-n> :NERDTreeToggle<CR> " Toggle NERDTree

" Window keymaps
noremap <leader>sv :vsplit<CR>         " Toggle vertical split

" FZF keymaps
nnoremap <leader>f :FZF<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>l :Lines<CR>
nnoremap <leader>h :History<CR>