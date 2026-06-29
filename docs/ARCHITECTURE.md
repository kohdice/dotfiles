# Architecture

Repo-specific design decisions and procedures that cannot be derived from the
code itself. For the directory layout, commands, and module overview, see
[AGENTS.md](../AGENTS.md) and [README.md](../README.md).

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
| starship      | Symlink | no home-manager integration                 |
| lazygit       | Symlink | no home-manager integration                 |
| karabiner     | Symlink | JSON config, macOS only                     |

## Symlinks

All symlinks are defined in `modules/home/dotfiles.nix`.

### Home directory (home.file)

| Source                        | Target                    |
| ----------------------------- | ------------------------- |
| `config/claude/CLAUDE.md`     | `~/.claude/CLAUDE.md`     |
| `config/claude/settings.json` | `~/.claude/settings.json` |
| `config/claude/statusline.sh` | `~/.claude/statusline.sh` |
| `config/codex/AGENTS.md`      | `~/.codex/AGENTS.md`      |
| `config/codex/config.toml`    | `~/.codex/config.toml`    |

### ~/.config (xdg.configFile)

| Source                               | Target                                            |
| ------------------------------------ | ------------------------------------------------- |
| `config/ghostty`                     | `~/.config/ghostty`                               |
| `config/nvim`                        | `~/.config/nvim`                                  |
| `config/starship/starship.toml`      | `~/.config/starship.toml`                         |
| `config/tmux`                        | `~/.config/tmux`                                  |
| `config/lazygit`                     | `~/.config/lazygit`                               |
| `config/zsh-abbr/user-abbreviations` | `~/.config/zsh-abbr/user-abbreviations`           |
| `config/karabiner/karabiner.json`    | `~/.config/karabiner/karabiner.json` (macOS only) |

Directories under `config/claude/skills/` and files under
`config/claude/commands/` are linked entry-by-entry into `~/.claude/skills/`
and `~/.claude/commands/`. The enumeration is based on the flake source, so
**new entries are not linked until they are `git add`ed**.

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
{
  name = "username";
  fullName = "Your Name";
  email = "your@email.com";
  home = "/Users/username"; # /home/username for Linux
  dotfilesDir = "/Users/username/developments/dotfiles";
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
```

### 3. Add matching apps (optional)

Add `build-newprofile` / `switch-newprofile` entries to `lib/apps.nix`,
following the existing `build-work` / `switch-work` definitions.
