{
  config,
  pkgs,
  lib,
  dotfilesDir,
  inputs,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  dotfilesPath = "${dotfilesDir}";

  # Flake source in /nix/store — safe to readDir under pure evaluation.
  flakeSource = inputs.self.outPath;

  # Helper to create symlink
  mkSymlink = path: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
  };

  # Enumerate each matching entry under `sourceRelPath` and map it to a
  # per-entry symlink under `targetDir`, so plugin-installed siblings can
  # coexist in the same ~/.claude target. Discovery uses the flake source
  # in the Nix store; the symlink itself still points at the live checkout.
  mkDirEntrySymlinks =
    {
      targetDir,
      sourceRelPath,
      entryTypes,
    }:
    let
      entries = builtins.readDir (flakeSource + "/${sourceRelPath}");
      names = builtins.attrNames (lib.filterAttrs (_: type: builtins.elem type entryTypes) entries);
    in
    lib.listToAttrs (
      map (name: lib.nameValuePair "${targetDir}/${name}" "${sourceRelPath}/${name}") names
    );

  claudeSkillSymlinks = mkDirEntrySymlinks {
    targetDir = ".claude/skills";
    sourceRelPath = "config/claude/skills";
    entryTypes = [ "directory" ];
  };

  claudeCommandSymlinks = mkDirEntrySymlinks {
    targetDir = ".claude/commands";
    sourceRelPath = "config/claude/commands";
    entryTypes = [ "regular" ];
  };

  # home.file symlinks (target -> source path in config/)
  homeSymlinks = {
    ".claude/CLAUDE.md" = "config/claude/CLAUDE.md";
    ".claude/settings.json" = "config/claude/settings.json";
    ".claude/statusline.sh" = "config/claude/statusline.sh";
    ".codex/AGENTS.md" = "config/codex/AGENTS.md";
    ".codex/config.toml" = "config/codex/config.toml";
  }
  // claudeSkillSymlinks
  // claudeCommandSymlinks;

  # xdg.configFile symlinks (target -> source path in config/)
  xdgSymlinks = {
    "cage/presets.yml" = "config/cage/presets.yml";
    "ghostty" = "config/ghostty";
    "nvim" = "config/nvim";
    "starship.toml" = "config/starship/starship.toml";
    "tmux" = "config/tmux";
    "lazygit" = "config/lazygit";
    "zsh-abbr/user-abbreviations" = "config/zsh-abbr/user-abbreviations";
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
