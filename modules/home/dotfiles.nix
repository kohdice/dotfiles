{
  config,
  pkgs,
  lib,
  user,
  inputs,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Read the flake's store copy so discovery works during pure evaluation.
  # It contains only Git-tracked files: new entries in the enumerated
  # directories need `git add` before rebuilding or they are silently skipped.
  flakeSource = inputs.self.outPath;

  mkSymlink = path: {
    source = config.lib.file.mkOutOfStoreSymlink "${user.dotfilesDir}/${path}";
  };

  # Individual links let locally installed siblings coexist in the target
  # directory. Discovery uses the store copy; links use the live checkout.
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

  # Claude Code uses ~/.claude/skills for personal skills, so shared skills
  # also need links there alongside the ~/.agents/skills links.
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

  claudeAgentSymlinks = mkDirEntrySymlinks {
    targetDir = ".claude/agents";
    sourceRelPath = "config/claude/agents";
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

  homeSymlinks = {
    ".claude/CLAUDE.md" = "config/claude/CLAUDE.md";
    ".claude/rules" = "config/claude/rules";
    ".claude/hooks" = "config/agents/hooks";
    ".claude/settings.json" = "config/claude/settings.json";
    ".claude/statusline.sh" = "config/claude/statusline.sh";
    ".codex/AGENTS.md" = "config/agents/AGENTS.md";
    ".codex/config.toml" = "config/codex/config.toml";
    ".codex/hooks" = "config/agents/hooks";
    ".codex/rules" = "config/codex/rules";
  }
  // sharedSkillClaudeSymlinks
  // claudeSkillSymlinks # Claude-specific skills win on name collision.
  // claudeCommandSymlinks
  // claudeAgentSymlinks
  // codexAgentSymlinks
  // agentsSkillSymlinks;

  xdgSymlinks = {
    "ghostty" = "config/ghostty";
    "herdr/config.toml" = "config/herdr/config.toml";
    "nvim" = "config/nvim";
    "tmux" = "config/tmux";
    "lazygit" = "config/lazygit";
    "zsh-abbr/user-abbreviations" = "config/zsh-abbr/user-abbreviations";
  };

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
