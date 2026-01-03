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
        sign-all = true;
      };
    };
  };
}
