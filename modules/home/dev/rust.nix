{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Rust stable toolchain
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
  ];
}
