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
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/CLAUDE.md";
    ".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/settings.json";
    ".claude/statusline.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/statusline.sh";
  };
}
