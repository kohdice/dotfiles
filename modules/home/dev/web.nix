{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # LSP (HTML, CSS, JSON, ESLint)
    vscode-langservers-extracted

    # Emmet
    emmet-ls

    # Linter
    stylelint
  ];
}
