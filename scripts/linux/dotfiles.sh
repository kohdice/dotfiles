#!/bin/bash

echo "[dotfiles.sh] Copy dotfiles..."

mkdir ${HOME}/.config
cd ${HOME}/.config

cp -fR ${HOME}/dotfiles/.bashrc ${HOME}/
cp -fR ${HOME}/dotfiles/.config/fish ${HOME}/.config/
cp -fR ${HOME}/dotfiles/.config/nvim ${HOME}/.config/
cp -fR ${HOME}/dotfiles/.config/tmux ${HOME}/.config/
echo
