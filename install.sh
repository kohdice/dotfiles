#!/bin/bash

DOTFILES_DIR="${HOME}/dotfiles"

if [ ! -d ${DOTFILES_DIR} ]; then
  echo "Cloning dotfiles repository..."
  git clone https://github.com/kohdice/dotfiles.git ${DOTFILES_DIR}
  echo "=> Done"
  echo
fi

echo "Checking operating system..."
sleep 2

if [ "$(uname)" = "Darwin" ]; then
  echo "=> MacOS"
  sleep 1;echo
  echo "---------------------------------------------"
  echo "         Install dotfiles for MacOS.         "
  echo "---------------------------------------------"
  echo
  # Scripts for MacOS
  ${HOME}/dotfiles/scripts/macos/dotfiles.sh
elif [ "$(uname)" = "Linux" ]; then
  echo "=> Linux"
  sleep 1;echo
  echo "---------------------------------------------"
  echo "         Install dotfiles for Linux.         "
  echo "---------------------------------------------"
  echo
  # Scripts for Linux
  ${HOME}/dotfiles/scripts/linux/dotfiles.sh
  ${HOME}/dotfiles/scripts/linux/neovim.sh
  ${HOME}/dotfiles/scripts/linux/tools.sh
else
  echo "($(uname)) is not supported."
  exit 1
fi

echo "---------------------------------------------"
echo "  Dotfiles installation has been completed.  "
echo "---------------------------------------------"
