#!/bin/bash

echo "[neovim.sh] Install Neovim..."

cd ~
git clone https://github.com/neovim/neovim
cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo
make install

echo "=> Done"
echo
