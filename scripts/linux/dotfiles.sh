#!/bin/bash

echo "[dotfiles.sh] Copy configuration files..."

mkdir ${HOME}/.config
cd ${HOME}/.config

cp -fR ${HOME}/dotfiles/.bashrc ${HOME}/
cp -fR ${HOME}/dotfiles/.config/fish ${HOME}/.config/
cp -fR ${HOME}/dotfiles/.config/nvim ${HOME}/.config/
cp -fR ${HOME}/dotfiles/tmux/.tmux.conf ${HOME}/
cp -fR ${HOME}/dotfiles/tmux/.tmux.powerline.conf ${HOME}/

echo "=> Done"
echo
