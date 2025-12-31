{
  config,
  pkgs,
  lib,
  user,
  dotfilesDir,
  ...
}:

{
  imports = [
    ./dev
    ./dotfiles.nix
    ./editors
    ./git
    ./packages.nix
    ./programs
  ];

  home = {
    username = user.name;
    homeDirectory = user.home;
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}
