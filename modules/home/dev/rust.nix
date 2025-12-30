{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime & Toolchain Manager
    rustup
    # rust-analyzer は rustup component add rust-analyzer で管理
  ];
}
