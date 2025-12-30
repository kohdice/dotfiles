{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime
    go
    tinygo

    # Tools
    golangci-lint
    delve

    # LSP
    gopls
  ];
}
