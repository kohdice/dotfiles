{ user, ... }:

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
    stateVersion = "26.05";

    # PATH additions shared by all shells; defined once here because
    # home.sessionPath is a list option and multiple definitions concatenate.
    sessionPath = import ./shell/paths.nix;
  };

  programs.home-manager.enable = true;
}
