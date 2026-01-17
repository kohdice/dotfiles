{
  pkgs,
  user,
  ...
}:

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
        key = "~/.ssh/id_ed25519.pub";
      };

      ui = {
        editor = "nvim";
        pager = "delta";
        diff-formatter = ":git";
      };
    };
  };
}
