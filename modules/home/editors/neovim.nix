{
  config,
  pkgs,
  lib,
  ...
}:

let
  isLinux = pkgs.stdenv.isLinux;
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Dependencies for Neovim plugins
    extraPackages =
      with pkgs;
      lib.optionals isLinux [
        xclip # Clipboard support (Linux only)
      ];
  };

  # Note: Neovim configuration is managed via xdg.configFile in default.nix
  # This allows using the existing Lua configuration as-is
}
