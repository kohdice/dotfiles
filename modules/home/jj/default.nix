{ user, ... }:

{
  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        name = user.fullName;
        email = user.email;
      };

      signing = {
        backend = "ssh";
        behavior = "own";
        key = "~/.ssh/id_ed25519_git_signing.pub";
      };

      ui = {
        editor = "nvim";
        pager = "delta";
        diff-formatter = ":git";
      };
    };
  };
}
