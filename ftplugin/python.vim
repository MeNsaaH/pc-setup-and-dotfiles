" Check Python files with flake8 and pylint.
let b:ale_linters = ['pylint', "flake8"]
" Fix Python files with autopep8 and yapf.
let b:ale_fixers = ['autopep8', "yapf", "isort"]
" Disable warnings about trailing whitespace for Python files.
let b:ale_warn_about_trailing_whitespace = 0
setlocal tabstop=4
setlocal shiftwidth=4
setlocal expandtab
setlocal autoindent
setlocal smarttab
setlocal formatoptions=croql
