{ pkgs, lib, ... }:

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

    # Load Home Manager-generated Lua via wrapper args instead of a generated
    # init.lua, which would collide with the config/nvim directory symlink.
    sideloadInitLua = true;
  };
}
