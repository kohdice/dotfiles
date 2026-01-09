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

  # Nix settings
  # Note: nix.enable is set to false because Determinate Nix is used
  # Determinate manages Nix installation with its own daemon
  nix = {
    enable = false;
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
    # gc configuration is not available when nix.enable = false
    # Use Determinate's built-in GC settings instead
  };

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
