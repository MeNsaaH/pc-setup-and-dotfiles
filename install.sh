# install Script
# TODO add configurations from parameters

sudo apt install -y  vim zsh tmux 

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
