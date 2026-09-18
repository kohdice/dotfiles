# Architecture

Repo-specific design decisions and procedures that cannot be derived from the
code itself. For the directory layout, commands, and module overview, see
[README.md](../README.md).

## Config Management Policy: Nix Module vs Symlink

Criteria for deciding whether an application config is managed as a Nix module
(`programs.*`) or as a symlink to `config/`.

### Prefer a Nix module when

1. **Dynamic value injection is needed** - profile-dependent values such as
   `user.email`, `user.fullName`
2. **home-manager integration is needed** - `home.sessionPath`,
   `home.sessionVariables`
3. **It interacts with other Nix modules** - e.g. `programs.delta` +
   `programs.git`
4. **Most of the config is expressible declaratively** - `extraConfig` stays
   below 50%

### Prefer a symlink when

1. **The config is complex and mostly `extraConfig`** - 50% or more
2. **The format natively supports file splitting / conditionals** - `source`,
   `if-shell`, etc.
3. **Syntax highlighting for a dedicated language matters** - Lua, tmux config
4. **No home-manager integration is needed** - env vars and PATH are inherited
   from the shell

### Current Layout

| App           | Method  | Reason                                      |
| ------------- | ------- | ------------------------------------------- |
| git, jj       | Nix     | `user.*` injection, 100% declarative        |
| zsh, bash     | Nix     | `home.sessionPath` integration is required  |
| ssh           | Nix     | host entries fit declarative management     |
| claude, codex | Symlink | config files are edited directly and often  |
| tmux          | Symlink | only ~20% declarative, needs file splitting |
| neovim        | Symlink | Lua language, no home-manager integration   |
| ghostty       | Symlink | no home-manager integration                 |
| herdr         | Symlink | no home-manager integration                 |
| pure          | Nix     | Zsh prompt integration, packaged by nixpkgs |
| lazygit       | Symlink | no home-manager integration                 |
| karabiner     | Symlink | JSON config, macOS only                     |

## GUI Application Policy: Homebrew Cask vs nixpkgs

Criteria for deciding whether a macOS GUI application is installed from
nixpkgs or Homebrew Cask.

### Prefer nixpkgs when

1. **The package supports Darwin and works normally** - use nixpkgs first when
   the package is available and not broken on macOS.
2. **The application is cross-platform** - put shared GUI applications in
   `modules/home/packages.nix`.
3. **The application is macOS-only but works from nixpkgs** - put macOS-only
   nixpkgs applications in `modules/darwin/packages.nix`.

### Prefer Homebrew Cask when

1. **The package is missing from nixpkgs** - use Cask when nixpkgs does not
   provide the application.
2. **The Darwin package is broken or unsuitable** - use Cask when the nixpkgs
   package does not work well on macOS.
3. **The application needs vendor-style updates** - use Cask for applications
   where the vendor distribution is the expected macOS installation path.

### Prefer profile-specific casks when

1. **The application belongs to only one profile** - put profile-only GUI
   applications in `users/<name>/darwin.nix` under `homebrew.casks`.

### Current Layout

| Location                      | Current applications                                                                               |
| ----------------------------- | -------------------------------------------------------------------------------------------------- |
| `modules/darwin/homebrew.nix` | formula: container / casks: coteditor, ghostty, google-chrome, karabiner-elements, scroll-reverser |
| `modules/darwin/packages.nix` | numi, raycast, vlc-bin                                                                             |
| `modules/home/packages.nix`   | slack, zoom-us                                                                                     |
| `modules/linux/packages.nix`  | ghostty, google-chrome (installed via Cask on macOS)                                               |
| `users/<name>/darwin.nix`     | kohdice: discord / work: elasticvue, tableplus                                                     |

## Symlinks

All symlinks are defined in `modules/home/dotfiles.nix`.

Agent-related files are split by runtime ownership:

- `config/claude/` stores Claude Code-specific configuration: `CLAUDE.md`,
  rules, settings, the status line script, custom commands, and custom agents.
  A `config/claude/skills/` directory is optional and absent today.
- `config/codex/` stores Codex-specific runtime configuration and Codex custom
  agent TOML files.
- `config/agents/` stores runtime-neutral agent assets: shared guidance
  (`AGENTS.md`), hooks used by both runtimes, and open agent skills. They are
  linked into runtime-specific discovery paths.
- Shared skills under `config/agents/skills/` are linked into both
  `~/.agents/skills/` and `~/.claude/skills/` because Claude Code does not
  discover `~/.agents/skills/`.

### Home directory (home.file)

| Source                        | Target                                        |
| ----------------------------- | --------------------------------------------- |
| `config/agents/AGENTS.md`     | `~/.codex/AGENTS.md`                          |
| `config/agents/hooks/`        | `~/.claude/hooks/` and `~/.codex/hooks/`      |
| `config/agents/skills/*`      | `~/.agents/skills/*` and `~/.claude/skills/*` |
| `config/claude/CLAUDE.md`     | `~/.claude/CLAUDE.md`                         |
| `config/claude/agents/*`      | `~/.claude/agents/*`                          |
| `config/claude/commands/*`    | `~/.claude/commands/*`                        |
| `config/claude/rules/`        | `~/.claude/rules/`                            |
| `config/claude/settings.json` | `~/.claude/settings.json`                     |
| `config/claude/statusline.sh` | `~/.claude/statusline.sh`                     |
| `config/codex/agents/*`       | `~/.codex/agents/*`                           |
| `config/codex/config.toml`    | `~/.codex/config.toml`                        |
| `config/codex/rules/`         | `~/.codex/rules/`                             |

### ~/.config (xdg.configFile)

| Source                               | Target                                            |
| ------------------------------------ | ------------------------------------------------- |
| `config/ghostty`                     | `~/.config/ghostty`                               |
| `config/herdr/config.toml`           | `~/.config/herdr/config.toml`                     |
| `config/nvim`                        | `~/.config/nvim`                                  |
| `config/tmux`                        | `~/.config/tmux`                                  |
| `config/lazygit`                     | `~/.config/lazygit`                               |
| `config/zsh-abbr/user-abbreviations` | `~/.config/zsh-abbr/user-abbreviations`           |
| `config/karabiner/karabiner.json`    | `~/.config/karabiner/karabiner.json` (macOS only) |

Directories under `config/agents/skills/` are linked entry-by-entry into both
`~/.agents/skills/` and `~/.claude/skills/`. Directories under
`config/claude/skills/` are linked entry-by-entry into `~/.claude/skills/`
after the shared skill links, so a Claude Code-specific skill wins when it has
the same name as a shared skill. Files under `config/claude/commands/`,
`config/claude/agents/`, and `config/codex/agents/` are linked entry-by-entry
into `~/.claude/commands/`, `~/.claude/agents/`, and `~/.codex/agents/`. The
enumeration is based on the flake source, so **new entries are not linked until
they are `git add`ed**.

> **Backup files**: `config/zsh/`, `config/bash/`, `config/git/`, and
> `config/jj/` are not linked anywhere. They are kept as backups for non-Nix
> environments after the migration to home-manager modules; editing them has
> no effect. The live configs are the home-manager modules
> (`modules/home/programs/zsh.nix`, `modules/home/programs/bash.nix`,
> `modules/home/git/`, `modules/home/jj/`). Sync the backups manually when
> changing the modules.

### Adding a Symlink

```nix
# homeSymlinks - link directly under the home directory
homeSymlinks = {
  ".your-config" = "config/your-app/.your-config";
};

# xdgSymlinks - link under ~/.config
xdgSymlinks = {
  "your-app" = "config/your-app";
};

# darwinXdgSymlinks - macOS-only links under ~/.config
darwinXdgSymlinks = {
  "your-macos-app" = "config/your-macos-app";
};
```

## Creating a New Profile

### 1. Add the user definition

Create a new profile under `users/` (three files plus the export):

```nix
# users/newprofile/info.nix - user info
# `home` and `dotfilesDir` are derived from `name` in lib/mkSystem.nix.
{
  name = "username";
  fullName = "Your Name";
  email = "your@email.com";
}
```

```nix
# users/newprofile/home.nix - home-manager overrides (may be empty)
{ ... }:
{ }
```

```nix
# users/newprofile/darwin.nix - Darwin-specific overrides (may be empty)
{ ... }:
{ }
```

```nix
# users/newprofile/default.nix - profile export
{
  info = import ./info.nix;
  home = ./home.nix;
  darwin = ./darwin.nix;
}
```

### 2. Register it in flake.nix

Add the profile to `darwinConfigurations`, `homeConfigurations`, and `checks`.
The `checks` attribute lists profiles by name, so a profile that is missing
there is never built by `nix flake check`.

```nix
# macOS
darwinConfigurations = {
  kohdice = mkSystem "darwin" { system = darwinSystem; user = "kohdice"; };
  work = mkSystem "darwin" { system = darwinSystem; user = "work"; };
  newprofile = mkSystem "darwin" { system = darwinSystem; user = "newprofile"; };
};

# Linux
homeConfigurations = {
  kohdice = mkSystem "linux" { system = "x86_64-linux"; user = "kohdice"; };
  work = mkSystem "linux" { system = "x86_64-linux"; user = "work"; };
  newprofile = mkSystem "linux" { system = "x86_64-linux"; user = "newprofile"; };
};

# Checks
// nixpkgs.lib.optionalAttrs (system == darwinSystem) {
  kohdice = self.darwinConfigurations.kohdice.system;
  work = self.darwinConfigurations.work.system;
  newprofile = self.darwinConfigurations.newprofile.system;
}
// nixpkgs.lib.optionalAttrs (builtins.elem system linuxSystems) {
  kohdice-home = self.homeConfigurations.kohdice.activationPackage;
  work-home = self.homeConfigurations.work.activationPackage;
  newprofile-home = self.homeConfigurations.newprofile.activationPackage;
}
```

### 3. Add matching apps (optional)

Add `build-newprofile` / `switch-newprofile` / `update-newprofile` entries to
`lib/apps.nix`, following the existing `build-work` / `switch-work` /
`update-work` definitions.
