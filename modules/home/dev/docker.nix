{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # LSP
    dockerfile-language-server

    # Linter
    hadolint
  ];
}
