{ pkgs, ... }:

{
  # Disable programs.zsh to use dotfiles symlink instead
  programs.zsh.enable = false;

  # Install zsh plugins as packages
  home.packages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];
}
