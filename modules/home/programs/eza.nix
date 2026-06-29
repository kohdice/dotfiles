{ ... }:

{
  # Shell integration (enabled by default) provides ls/ll/la/lt/lla aliases
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };
}
