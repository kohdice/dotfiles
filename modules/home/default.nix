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

    # Defined once here rather than per shell so bash and zsh cannot drift.
    shellAliases = import ./shell/aliases.nix;
    sessionVariables = import ./shell/env.nix;
    sessionPath = import ./shell/paths.nix;
  };

  programs.home-manager.enable = true;
}
