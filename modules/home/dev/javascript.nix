{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime
    nodejs_24 # LTS (current)
    bun
    deno

    # TypeScript
    typescript

    # LSP
    typescript-language-server

    # Formatter
    prettierd
  ];
}
