#!/bin/bash

echo "[dotfiles.sh] Copy dotfiles..."

DOTFILES="${HOME}/dotfiles"
ZSH="${DOTFILES}/zsh"

cp -fR "${DOTFILES}/.config" "${DOTFILES}/.gitconfig" "${ZSH}/.zshrc" "${ZSH}/.p10k.zsh" ${HOME}
echo
