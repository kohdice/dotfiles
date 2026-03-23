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

  # Keep using config/nvim as the source of truth and suppress Home Manager's
  # generated init.lua, which would otherwise collide with the directory symlink.
  xdg.configFile."nvim/init.lua".enable = false;
}
