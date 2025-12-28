{
  config,
  pkgs,
  lib,
  dotfilesDir,
  ...
}:

{
  home.file = {
    ".zshenv".source = "${dotfilesDir}/config/zsh/.zshenv";
    ".zshrc".source = "${dotfilesDir}/config/zsh/.zshrc";
    ".bash_profile".source = "${dotfilesDir}/config/bash/.bash_profile";
    ".bashrc".source = "${dotfilesDir}/config/bash/.bashrc";
  };

  xdg.enable = true;
  xdg.configFile = {
    "ghostty".source = "${dotfilesDir}/config/ghostty";
    "nvim".source = "${dotfilesDir}/config/nvim";
    "starship.toml".source = "${dotfilesDir}/config/starship/starship.toml";
    "tmux".source = "${dotfilesDir}/config/tmux";
    "lazygit".source = "${dotfilesDir}/config/lazygit";
  };
}
