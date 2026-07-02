{ ... }:

{
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  programs.nix-index-database.comma.enable = true;
}
