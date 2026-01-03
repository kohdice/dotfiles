{
  config,
  pkgs,
  lib,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  # mkOutOfStoreSymlink requires absolute path for direct symlinks
  # This allows edits to reflect immediately without running switch
  dotfilesPath = "${config.home.homeDirectory}/developments/dotfiles";
in
{
  home.file = {
    # Shell
    ".zshenv".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/zsh/.zshenv";
    ".zshrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/zsh/.zshrc";
    ".bash_profile".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/bash/.bash_profile";
    ".bashrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/bash/.bashrc";

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
    "ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/ghostty";
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/nvim";
    "starship.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/starship/starship.toml";
    "tmux".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/tmux";
    "lazygit".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/lazygit";
  }
  // lib.optionalAttrs isDarwin {
    "karabiner/karabiner.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/karabiner/karabiner.json";
  };
}
