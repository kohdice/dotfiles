# dotfiles

Nix Flake-based dotfiles for macOS and Linux.

Uses [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager) for declarative configuration.

## Setup

### Prerequisites

Install [Determinate Nix](https://github.com/DeterminateSystems/nix-installer):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Installation

#### macOS

```bash
git clone https://github.com/kohdice/dotfiles.git ~/developments/dotfiles
cd ~/developments/dotfiles

# Initial setup (first time only)
nix run nix-darwin -- switch --flake .#kohdice

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

## Daily Usage

| Command                                | Description                   |
| -------------------------------------- | ----------------------------- |
| `nix run .#build`                      | Build configuration (dry-run) |
| `nix run .#switch`                     | Apply configuration           |
| `nix flake update && nix run .#switch` | Update all packages           |
| `nix fmt`                              | Format Nix and Lua files      |
| `nix flake check`                      | Validate flake configuration  |

## Module Structure

```
dotfiles/
├── flake.nix              # Entry point
├── nix/
│   ├── overlays/          # Custom package overlays
│   └── modules/
│       ├── darwin/        # macOS system configuration
│       ├── home/          # home-manager configuration (cross-platform)
│       └── linux/         # Linux-specific configuration
├── config/                # Application configs (nvim, tmux, etc.)
├── claude/                # Claude Code settings
└── codex/                 # OpenAI Codex settings
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - Project structure and included tools
- [Customization](docs/CUSTOMIZATION.md) - Adding packages and creating profiles

## License

MIT
