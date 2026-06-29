{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # LSP
    nil

    # Formatter (official RFC 166 style; matches treefmt's nixfmt in flake.nix)
    nixfmt
  ];
}
