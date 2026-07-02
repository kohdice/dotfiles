{
  config,
  pkgs,
  lib,
  user,
  inputs,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;

  # Flake source in /nix/store — safe to readDir under pure evaluation.
  # NOTE: it only contains git-tracked files, so new entries under the
  # enumerated directories below must be `git add`ed before they are linked;
  # untracked entries are silently skipped.
  flakeSource = inputs.self.outPath;

  # Helper to create symlink
  mkSymlink = path: {
    source = config.lib.file.mkOutOfStoreSymlink "${user.dotfilesDir}/${path}";
  };

  # Enumerate each matching entry under `sourceRelPath` and map it to a
  # per-entry symlink under `targetDir`, so locally installed siblings can
  # coexist in the same target directory. Discovery uses the flake source
  # in the Nix store; the symlink itself still points at the live checkout.
  mkDirEntrySymlinks =
    {
      targetDir,
      sourceRelPath,
      entryTypes,
    }:
    let
      sourcePath = flakeSource + "/${sourceRelPath}";
      entries = if builtins.pathExists sourcePath then builtins.readDir sourcePath else { };
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

  # Claude Code only discovers ~/.claude/skills, so shared skills are linked
  # into both Claude Code and open-agent discovery paths.
  sharedSkillClaudeSymlinks = mkDirEntrySymlinks {
    targetDir = ".claude/skills";
    sourceRelPath = "config/agents/skills";
    entryTypes = [ "directory" ];
  };

  claudeCommandSymlinks = mkDirEntrySymlinks {
    targetDir = ".claude/commands";
    sourceRelPath = "config/claude/commands";
    entryTypes = [ "regular" ];
  };

  codexAgentSymlinks = mkDirEntrySymlinks {
    targetDir = ".codex/agents";
    sourceRelPath = "config/codex/agents";
    entryTypes = [ "regular" ];
  };

  agentsSkillSymlinks = mkDirEntrySymlinks {
    targetDir = ".agents/skills";
    sourceRelPath = "config/agents/skills";
    entryTypes = [ "directory" ];
  };

  # home.file symlinks (target -> source path in config/)
  homeSymlinks = {
    ".claude/CLAUDE.md" = "config/claude/CLAUDE.md";
    ".claude/settings.json" = "config/claude/settings.json";
    ".claude/statusline.sh" = "config/claude/statusline.sh";
    ".codex/AGENTS.md" = "config/agents/AGENTS.md";
    ".codex/config.toml" = "config/codex/config.toml";
  }
  // sharedSkillClaudeSymlinks
  // claudeSkillSymlinks # Claude-specific skills win on name collision.
  // claudeCommandSymlinks
  // codexAgentSymlinks
  // agentsSkillSymlinks;

  # xdg.configFile symlinks (target -> source path in config/)
  xdgSymlinks = {
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
