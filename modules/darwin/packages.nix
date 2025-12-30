{ config, pkgs, ... }:

{
  # Darwin-specific system packages
  # These require system-level installation (not home-manager)
  environment.systemPackages = with pkgs; [
    # System Utilities (macOS only)
    karabiner-elements
    raycast
    scroll-reverser
  ];
}
