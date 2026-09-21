{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cmake-format
    cmake-lint
    neocmakelsp
  ];
}
