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
    ./jj
    ./packages.nix
    ./programs
    ./ssh
  ];

  home = {
    username = user.name;
    homeDirectory = user.home;
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}
