# dotfiles

Nix Flake-based dotfiles for macOS and Linux.

Uses [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager) for declarative configuration.

## Setup

### Prerequisites

Install [Nix](https://github.com/NixOS/nix-installer):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://artifacts.nixos.org/nix-installer | sh -s -- install
```

### Installation

#### macOS

```bash
git clone https://github.com/kohdice/dotfiles.git ~/developments/dotfiles
cd ~/developments/dotfiles

# Initial setup (first time only)
sudo nix run nix-darwin -- switch --flake .#kohdice

# After initial setup
nix run .#switch
```

#### Linux

```bash
git clone https://github.com/kohdice/dotfiles.git ~/developments/dotfiles
cd ~/developments/dotfiles

# Apply home-manager configuration
nix run .#switch
```

### SSH Keys

After applying the profile for the first time, authenticate GitHub CLI and
create separate keys for GitHub authentication and Git commit signing:

```bash
gh auth login \
  --hostname github.com \
  --web \
  --git-protocol ssh \
  --skip-ssh-key \
  --scopes admin:public_key,admin:ssh_signing_key
nix run .#setup-ssh-keys
gh auth refresh \
  --hostname github.com \
  --remove-scopes admin:public_key,admin:ssh_signing_key
```

The setup supports macOS and Linux. It prompts for a key description and
passphrases, registers both public keys with GitHub, and verifies authentication
and signing. On macOS, it also stores the passphrases in Keychain. It requires
an authenticated GitHub CLI session and does not run automatically from the
switch or update apps. The temporary key-management scopes are removed after
the setup completes.

On Linux, Home Manager provides `ssh-agent`, and the setup adds both keys for
the current login session. After a new login, add the keys again when needed:

```bash
ssh-add ~/.ssh/id_ed25519_github_auth
ssh-add ~/.ssh/id_ed25519_git_signing
```

## Daily Usage

| Command                 | Description                     |
| ----------------------- | ------------------------------- |
| `nix run .#build`       | Build kohdice profile (dry-run) |
| `nix run .#build-work`  | Build work profile (dry-run)    |
| `nix run .#switch`      | Apply kohdice profile           |
| `nix run .#switch-work` | Apply work profile              |
| `nix run .#update`      | Update all packages and apply   |
| `nix fmt`               | Format Nix and Lua files        |
| `nix flake check`       | Validate flake configuration    |

## Module Structure

```
dotfiles/
├── flake.nix              # Entry point
├── lib/                   # Helper functions and runnable setup applications
├── modules/
│   ├── darwin/            # macOS system configuration
│   ├── home/              # home-manager configuration (cross-platform)
│   └── linux/             # Linux-specific configuration
├── users/                 # User profile definitions
└── config/                # Application configs (nvim, tmux, claude, codex, etc.)
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - Design decisions (Nix module vs symlink), symlink map, and profile creation
