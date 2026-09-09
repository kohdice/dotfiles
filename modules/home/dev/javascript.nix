{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime
    nodejs_24 # LTS (current)
    bun
    deno

    # TypeScript 7 native compiler and LSP
    typescript

    # Formatter
    prettierd
  ];
}
