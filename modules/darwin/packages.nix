{ pkgs, ... }:

{
  # macOS-only packages.
  environment.systemPackages = with pkgs; [
    container
    numi
    raycast
    vlc-bin
  ];
}
