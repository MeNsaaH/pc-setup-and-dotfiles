[ -f ~/.fzf.bash ] && source ~/.fzf.bash
. "$HOME/.cargo/env"
source $HOME/.aliases

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init bash)"; fi
