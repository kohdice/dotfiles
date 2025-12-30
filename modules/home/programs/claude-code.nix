{
  config,
  pkgs,
  dotfilesDir,
  ...
}:

let
  claudeDotfilesDir = "${dotfilesDir}/config/claude";
in
{
  home.packages = [ pkgs.claude-code ];

  home.file = {
    ".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/settings.json";
    ".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/commands";
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/CLAUDE.md";
  };
}
