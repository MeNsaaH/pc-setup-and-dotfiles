#!/bin/bash
# install Script
# NOTE This has not being tested yet
# TODO add configurations from parameters
# TODO add NERDFonts config

echo "Installing Dependencies"

sudo apt install -y   tmux fonts-powerline xdotool
sudo pip3 install grip

echo "Setting Up Your Environment"

install_vim() {
  echo "Setting Up Your Vim"
  # copy Vim
  sudo apt install -y vim
  cp .vimrc ~/.vimrc
  # Install vim Plugins
  vim +PluginInstall +qall
  pip install grip
}

install_zsh() {
  echo "Setting up zsh"
  # Setup Zsh
  apt install -y zsh
  cp .zshrc ~/.zshrc
}

install_tmux(){
  # setup tmux
  echo "Setting up tmux"
  apt install -y tmux
  cp .tmux.conf ~/.tmux.conf
}

setup_bash(){
  echo "Setting up bash"
  cp .bashrc ~/.bashrc
}

setup_utilities(){
  echo "Installing a few utilities, fonts"
  apt install -y fonts-powerline xdotool
}


echo "Installation Complete"
