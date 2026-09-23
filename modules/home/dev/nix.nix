{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nil

    # Keep this formatter aligned with treefmt in flake.nix.
    nixfmt
  ];
}
