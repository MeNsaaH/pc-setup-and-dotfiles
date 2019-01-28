# install Script
# TODO add configurations from parameters
# TODO add NERDFonts config

echo "Installing Dependencies"

sudo apt install -y  vim zsh tmux fonts-powerline xdotool
sudo pip3 install grip

echo "Setting Up Your Environment"
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

echo "Installation Complete"
