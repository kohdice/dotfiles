{ config, pkgs, ... }:

{
  # Darwin-specific system packages
  # These require system-level installation (not home-manager)
  environment.systemPackages = with pkgs; [
    google-chrome
    slack
    scroll-reverser
    tableplus
  ];
}
