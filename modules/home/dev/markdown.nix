{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # LSP
    # marksman # TODO: nixpkgs issue #483584 - Swift build failure on darwin

    # Linter
    markdownlint-cli2
  ];
}
