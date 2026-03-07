{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime
    go_1_26
    tinygo

    # Tools
    golangci-lint
    delve

    # LSP
    gopls
  ];
}
