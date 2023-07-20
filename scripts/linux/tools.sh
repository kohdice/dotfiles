#!/bin/bash

cd ~

# git tools for bash
echo "[tools.sh] Install git-completion,prompt..."
curl -o .git-completion.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o .git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
echo

# Fisher
echo "[[tools.sh] Install Fisher..."
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
echo

# act
echo "[tools.sh] Install act..."
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
echo

# Lazygit
echo "[tools.sh] Install Lazygit..."

mkdir ${HOME}/tools
cd ${HOME}/tools

LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
install lazygit /usr/local/bin
echo
