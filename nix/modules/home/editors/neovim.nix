{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Dependencies for Neovim plugins
    extraPackages = with pkgs; [
      # Build tools
      tree-sitter
      gcc
      cmake

      # Clipboard support
      xclip
    ];
  };

  # Note: Neovim configuration is managed via xdg.configFile in default.nix
  # This allows using the existing Lua configuration as-is
}
