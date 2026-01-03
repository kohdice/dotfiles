{
  config,
  pkgs,
  lib,
  dotfilesDir,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  dotfilesPath = "${dotfilesDir}";

  # Helper to create symlink
  mkSymlink = path: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
  };

  # home.file symlinks (target -> source path in config/)
  homeSymlinks = {
    ".claude/CLAUDE.md" = "config/claude/CLAUDE.md";
    ".claude/settings.json" = "config/claude/settings.json";
    ".claude/statusline.sh" = "config/claude/statusline.sh";
    ".codex/AGENTS.md" = "config/codex/AGENTS.md";
    ".codex/config.toml" = "config/codex/config.toml";
  };

  # xdg.configFile symlinks (target -> source path in config/)
  xdgSymlinks = {
    "ghostty" = "config/ghostty";
    "nvim" = "config/nvim";
    "starship.toml" = "config/starship/starship.toml";
    "tmux" = "config/tmux";
    "lazygit" = "config/lazygit";
  };

  # Darwin-only xdg.configFile symlinks
  darwinXdgSymlinks = {
    "karabiner/karabiner.json" = "config/karabiner/karabiner.json";
  };
in
{
  home.file = lib.mapAttrs (_: mkSymlink) homeSymlinks;

  xdg.enable = true;
  xdg.configFile =
    lib.mapAttrs (_: mkSymlink) xdgSymlinks
    // lib.optionalAttrs isDarwin (lib.mapAttrs (_: mkSymlink) darwinXdgSymlinks);
}
