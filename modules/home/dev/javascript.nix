{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime
    nodejs
    bun
    deno

    # Package Managers
    nodePackages.pnpm
    nodePackages.npm

    # TypeScript
    nodePackages.typescript

    # LSP
    nodePackages.typescript-language-server

    # Formatter
    prettierd
  ];
}
