{ pkgs, ... }:

{
  # macOS-only GUI applications.
  # Cross-platform GUI apps live in modules/home/packages.nix.
  environment.systemPackages = with pkgs; [
    numi
    raycast
    scroll-reverser
    vlc-bin
  ];
}
