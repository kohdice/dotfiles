{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # LSP
    nil

    # Formatter
    nixpkgs-fmt
  ];
}
