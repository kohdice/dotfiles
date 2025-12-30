{
  config,
  pkgs,
  dotfilesDir,
  ...
}:

let
  codexDotfilesDir = "${dotfilesDir}/config/codex";
in
{
  home.packages = [ pkgs.codex ];

  home.file = {
    ".codex/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/config.toml";
    ".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/AGENTS.md";
  };
}
