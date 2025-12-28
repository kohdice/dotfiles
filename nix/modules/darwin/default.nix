{
  config,
  pkgs,
  lib,
  user,
  ...
}:

{
  imports = [
    ./homebrew.nix
    ./packages.nix
    ./system.nix
  ];

  # Nix settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        user.name
      ];
    };
    gc = {
      automatic = true;
      interval = {
        Day = 7;
      };
      options = "--delete-older-than 7d";
    };
  };

  # System state version
  system.stateVersion = 5;

  # User configuration
  users.users.${user.name} = {
    home = user.home;
    shell = pkgs.zsh;
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;
}
