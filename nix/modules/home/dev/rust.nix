{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime
    rustup

    # LSP
    rust-analyzer
  ];
}
