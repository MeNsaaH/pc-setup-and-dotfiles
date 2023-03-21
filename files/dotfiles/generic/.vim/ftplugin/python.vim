" Check Python files with flake8 and pylint.
let b:ale_linters = ['flake8', 'pylint']

" Fix Python files with autopep8 and yapf.
let b:ale_fixers = ['black', 'autopep8', 'yapf', 'isort']

" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
