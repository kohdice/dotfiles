{
  user,
  pkgs,
  lib,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "github.com" = {
        IdentityFile = "~/.ssh/id_ed25519_github_auth";
        IdentitiesOnly = "yes";
        AddKeysToAgent = "yes";
      }
      // lib.optionalAttrs isDarwin {
        IgnoreUnknown = "UseKeychain";
        UseKeychain = "yes";
      };
    };
  };

  services.ssh-agent.enable = isLinux;

  launchd.agents.load-git-signing-key = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          key=${lib.escapeShellArg "${user.home}/.ssh/id_ed25519_git_signing"}
          [ ! -f "$key" ] || exec /usr/bin/ssh-add --apple-load-keychain "$key"
        ''
      ];
      RunAtLoad = true;
    };
  };
}
