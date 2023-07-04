#!/bin/bash

echo "[dotfiles.sh] Copy configuration files..."

DOTFILES="${HOME}/dotfiles"
ZSH="${DOTFILES}/zsh"
TMUX="${DOTFILES}/tmux"

cp -fR "${DOTFILES}/.config" "${DOTFILES}/.gitconfig" "${ZSH}/.zshrc" "${ZSH}/.p10k.zsh" "${TMUX}/.tmux.conf" "${TMUX}/.tmux.powerline.conf" ${HOME}

echo "=> Done."
echo
