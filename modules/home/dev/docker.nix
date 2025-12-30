{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # LSP
    dockerfile-language-server-nodejs

    # Linter
    hadolint
  ];
}
