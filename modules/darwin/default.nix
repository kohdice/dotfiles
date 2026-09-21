{ user, ... }:

{
  imports = [
    ./homebrew.nix
    ./packages.nix
    ./system.nix
  ];

  # Nix settings are managed by nix-installer (not nix-darwin)
  # See README.md for installation options
  nix.enable = false;

  system.stateVersion = 5;

  # Primary user (required for system.defaults)
  system.primaryUser = user.name;

  users.users.${user.name} = {
    home = user.home;
  };

  programs.zsh.enable = true;
}
