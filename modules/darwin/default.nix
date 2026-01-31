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
    ./system.nix
  ];

  # Nix settings are managed by nix-installer (not nix-darwin)
  # See README.md for installation options
  nix.enable = false;

  # System state version
  system.stateVersion = 5;

  # Primary user (required for system.defaults)
  system.primaryUser = user.name;

  # User configuration
  users.users.${user.name} = {
    home = user.home;
    shell = pkgs.zsh;
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;
}
