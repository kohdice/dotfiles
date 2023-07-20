#!/bin/bash

DOTFILES_DIR="${HOME}/dotfiles"
TARBALL="https://github.com/kohdice/dotfiles/archive/refs/heads/main.tar.gz"

# Clone repository
if [ ! -d ${DOTFILES_DIR} ]; then
  echo "Cloning dotfiles repository..."
  sleep 1; echo
  curl -L ${TARBALL} -o main.tar.gz
  tar -zxvf main.tar.gz
  rm -f main.tar.gz
  mv -f dotfiles-main "${DOTFILES_DIR}"
  echo
fi

echo "Checking operating system..."
sleep 1

if [ "$(uname)" = "Darwin" ]; then
  echo "=> macOS"
  sleep 1;echo
  echo "---------------------------------------------"
  echo "         Install dotfiles for macOS.         "
  echo "---------------------------------------------"
  echo
  # Scripts for macOS
  ${HOME}/dotfiles/scripts/macos/dotfiles.sh
  ${HOME}/dotfiles/scripts/macos/init.sh
  ${HOME}/dotfiles/scripts/macos/defaults.sh
  ${HOME}/dotfiles/scripts/macos/brew.sh
elif [ "$(uname)" = "Linux" ]; then
  echo "=> Linux"
  sleep 1;echo
  echo "---------------------------------------------"
  echo "         Install dotfiles for Linux.         "
  echo "---------------------------------------------"
  echo
  # Scripts for Linux
  ${HOME}/dotfiles/scripts/linux/dotfiles.sh
  ${HOME}/dotfiles/scripts/linux/tools.sh
else
  echo "($(uname)) is not supported."
  exit 1
fi

echo "---------------------------------------------"
echo "  Dotfiles installation has been completed.  "
echo "---------------------------------------------"
