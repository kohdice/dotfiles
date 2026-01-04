# Common shell aliases shared between zsh and bash
{
  # General
  cl = "clear";

  # Directory Navigation
  ".." = "cd ..";
  "..2" = "cd ../..";
  "..3" = "cd ../../..";
  "..4" = "cd ../../../..";

  # Enhanced ls (eza)
  ls = "eza --icons --git";
  la = "eza -A --icons --git";
  ll = "eza -l -g --icons";
  lla = "eza -l -a --icons";

  # Neovim
  v = "nvim";
  view = "nvim -R";

  # Git
  g = "git";

  # Docker
  d = "docker";
  dc = "docker compose";
  dce = "docker compose exec";
  dcu = "docker compose up";
  dcub = "docker compose up --build";
  dcud = "docker compose up -d";
  dcudb = "docker compose up -d --build";

  # Terraform
  tf = "terraform";

  # Ghostty
  gstcfg = "nvim ~/.config/ghostty/config";

  # Lazygit
  lg = "lazygit";
}
