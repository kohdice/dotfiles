{
  config,
  pkgs,
  user,
  ...
}:

{
  programs.git = {
    enable = true;
    userName = user.fullName;
    userEmail = user.email;

    extraConfig = {
      core = {
        editor = "nvim";
        excludesfile = "~/.gitignore";
        ignorecase = false;
      };

      diff.tool = "nvimdiff";
      "difftool \"nvimdiff\"".cmd = ''nvim -d "$LOCAL" "$REMOTE"'';

      "mergetool \"nvimdiff\"" = {
        cmd = ''nvim -d "$LOCAL" "$REMOTE" -ancestor "$BASE" -merge "$MERGED"'';
        trustExitCode = true;
      };

      ghq.root = "~/developments";
    };

    aliases = import ./aliases.nix;

    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        syntax-theme = "Solarized (dark)";
      };
    };
  };
}
