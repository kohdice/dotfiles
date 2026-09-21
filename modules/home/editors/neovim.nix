{ pkgs, lib, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages =
      with pkgs;
      lib.optionals isLinux [
        xclip
      ];

    # Load Home Manager-generated Lua via wrapper args instead of a generated
    # init.lua, which would collide with the config/nvim directory symlink.
    sideloadInitLua = true;
  };
}
