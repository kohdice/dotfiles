{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime
    zig

    # LSP
    zls
  ];
}
