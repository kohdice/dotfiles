{ pkgs, ... }:

{
  # Claude Code CLI
  # Configuration files are managed in modules/home/dotfiles.nix
  # using mkOutOfStoreSymlink to enable direct editing
  home.packages = [ pkgs.claude-code ];
}
