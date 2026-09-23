{ pkgs, ... }:

{
  home.packages = with pkgs; [
    emmet-ls
    stylelint
    vscode-langservers-extracted
  ];
}
