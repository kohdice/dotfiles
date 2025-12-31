{
  config,
  pkgs,
  lib,
  dotfilesDir,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  # mkOutOfStoreSymlink requires absolute path
  # dotfilesDir from flake is in /nix/store, so we need to use actual repo path
  dotfilesPath = "${config.home.homeDirectory}/developments/dotfiles";
in
{
  home.file = {
    # Shell
    ".zshenv".source = "${dotfilesDir}/config/zsh/.zshenv";
    ".zshrc".source = "${dotfilesDir}/config/zsh/.zshrc";
    ".bash_profile".source = "${dotfilesDir}/config/bash/.bash_profile";
    ".bashrc".source = "${dotfilesDir}/config/bash/.bashrc";

    # Claude Code
    ".claude/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/claude/CLAUDE.md";
    ".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/claude/settings.json";
    ".claude/statusline.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/claude/statusline.sh";

    # Codex
    ".codex/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/codex/AGENTS.md";
    ".codex/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/codex/config.toml";
  };

  xdg.enable = true;
  xdg.configFile = {
    "ghostty".source = "${dotfilesDir}/config/ghostty";
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/nvim";
    "starship.toml".source = "${dotfilesDir}/config/starship/starship.toml";
    "tmux".source = "${dotfilesDir}/config/tmux";
    "lazygit".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/lazygit";
  }
  // lib.optionalAttrs isDarwin {
    "karabiner/karabiner.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/karabiner/karabiner.json";
  };
}
