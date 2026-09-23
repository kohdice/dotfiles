{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bun
    deno
    nodejs_24
    prettierd
    typescript
  ];
}
