#!/bin/bash
# install Script
# NOTE This has not being tested yet
# TODO add NERDFonts config

PROJECT_ROOT=$(pwd -P)
export verbose=0
export success=1

# Logging
touch install.log

showHelp() {
# `cat << EOF` This means that cat should stop reading when EOF is detected
  cat << EOF  
  Usage: ./install <options>
  setups Specific dotfiles 

  -h, -help,  --help              Display help

  -all,       --all               Installs all configs
  -vim,       --vim               Installs vim and all vim configurations
  -zsh,       --zsh               Installs zsh and all zsh configurations
  -tmux,       --tmux             Installs tmux and all tmux configurations

  -V, -verbose, --verbose         Run script in verbose mode. Will print out each step of execution.

EOF
}

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

install_deps() {
  # Installs APT Dependencies
  status=$(sudo apt install -y $1)
  if [ status != 0 ]; then
    export success=0
  fi
}

run_playbook() {
  local status = "$(ansible-playbook $1 -vvv)"
  if [[ $status != 0 ]]
  then
    fail "Could not configure $1"
  fi
}

setup_vim() {
  info "Setting Up Your Vim"
  # TODO check if vim is installed

  local t=
  user "Do You want to install Terminal Vim or GUI Vim?\n\
  [t]erminal, [g]ui, [a]ll?"
  read -n 1 action

  # Pass this extra vars to Playbook
  case "$action" in
    T|t )
      t="vim";;
    G|g )
      t="vim-gtk";;
    a|A )
      t="vim vim-gtk";;
    * )
      ;;
  esac

  run_playbook plays/playbooks/setup_vim.yml
  # Install vim Plugins
  vim +PluginInstall +qall
} 

setup_zsh() {
  info "Setting up zsh"
  # Setup Zsh
  # Set ZSH as default shell
  sudo chsh $(which zsh)
  #TODO install Zsh plugins and theme from github
}

setup_tmux(){
  # setup tmux
  info "Setting up Tmux"
  install_deps tmux
  install_dotfiles tmux
  # TODO install TMUX plugins and theme from github
}

setup_utilities(){
  info "Installing a few utilities, fonts"
  apt install -y fonts-powerline xdotool
}

install_all() {
  setup_vim
  setup_tmux
  setup_zsh
  setup_bash
}

link_file () {
  local src=$1 dst=$2

  local overwrite= backup= skip=
  local action=

  if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]
  then

    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]
    then

      local currentSrc="$(readlink $dst)"

      if [ "$currentSrc" == "$src" ]
      then

        skip=true;

      else
        user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -n 1 action

        case "$action" in
          o )
            overwrite=true;;
          O )
            overwrite_all=true;;
          b )
            backup=true;;
          B )
            backup_all=true;;
          s )
            skip=true;;
          S )
            skip_all=true;;
          * )
            ;;
        esac

      fi

    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]
    then
      rm -rf "$dst"
      success "removed $dst"
    fi

    if [ "$backup" == "true" ]
    then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" == "true" ]
    then
      success "skipped $src"
    fi
  fi

  if [ "$skip" != "true" ]  # "false" or empty
  then
    ln -s "$1" "$2"
    success "linked $1 to $2"
  fi
}

install_dotfiles () {
  info "installing $1 dotfiles"

  local overwrite_all=false backup_all=false skip_all=false

  for src in $(find -H "$1" -maxdepth 2 -name '*.symlink' -not -path '*.git*')
  do
    dst="$HOME/.$(basename "${src%.*}")"
    link_file "$src" "$dst"
  done
}


# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "help,vim,verbose,zsh,tmux,all" -o "hV" -a -- "$@")

# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters 
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

while true
do
  case $1 in
  -h|--help) 
      showHelp
      exit 0
      ;;
  -V|--verbose)
      export verbose=1
      set -xv  # Set xtrace and verbose mode.
      ;;
  --all)
      # TODO if `all` and other params are specified, throw error
      info "installing all configs"
      install_all
      ;;
  --tmux)
      info "setting up tmux" 
      setup_tmux
      ;;
  --zsh)
      info "setting up zsh" 
      setup_zsh
      ;;
  --vim)
      info "setting up vim" 
      setup_vim
      ;;
  --)
      shift
      break;;
  esac
shift
done

if [[ $success == 1 ]];then
  success "Installation Complete"
else
  fail "Installation Failed. Check install.log for more details"
fi
