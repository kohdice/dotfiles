#!/bin/bash

# Install Rosetta 2 for Apple Silicon
if [ "$(uname -m)" == "arm64" ] ; then
  echo "[init.sh] Install Rosetta 2..."
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license
  echo
fi

# Install xcode
echo "[init.sh] Install Xcode..."
xcode-select --install
echo

# Install Homebrew
echo "[init.sh] Install Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [ "$(uname -m)" == "arm64" ] ; then
  echo '# Homebrew' >> /Users/"$USER"/.zprofile
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/"$USER"/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo
fi
