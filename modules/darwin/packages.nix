{ pkgs, ... }:

{
  # macOS-only packages.
  environment.systemPackages = with pkgs; [
    # TODO: Re-enable container once the nixpkgs package reaches version 1.2.0 or later.
    # Homebrew is used in the meantime because the nixpkgs package lags behind upstream.
    # container
    numi
    raycast
    vlc-bin
  ];
}
