# install Script
# TODO add configurations from parameters
# TODO add NERDFonts config

sudo apt install -y  vim zsh tmux fonts-powerline

# Setup Vim
# copy Vim 
cp .vimrc ~/.vimrc
# Install vim Plugins
vim +PluginInstall +qall

# Setup Zsh
cp .zshrc ~/.zshrc

# setup tmux
cp .bashrc ~/.bashrc

# setup tmux
cp .tmux.conf ~/.tmux.conf
