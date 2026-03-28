{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime
    go_1_26

    # Tools
    golangci-lint
    delve

    # LSP
    gopls
  ];
}
