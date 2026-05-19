{
  pkgs,
  lib,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "github.com" = {
        IdentityFile = "~/.ssh/id_ed25519";
        AddKeysToAgent = "yes";
      }
      // lib.optionalAttrs isDarwin {
        UseKeychain = "yes";
      };
    };
  };
}
