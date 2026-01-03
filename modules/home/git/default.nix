{
  config,
  pkgs,
  user,
  ...
}:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = user.fullName;
        email = user.email;
      };

      alias = import ./aliases.nix;

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

    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
      format = "ssh";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "Solarized (dark)";
    };
  };
}
