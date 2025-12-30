# Architecture

このリポジトリは Nix Flake をベースとした macOS/Linux の開発環境設定です。

## 概要

- **macOS**: nix-darwin + home-manager による宣言的システム設定
- **Linux**: home-manager のみによるユーザー環境設定
- **フォーマッター**: treefmt-nix (nixfmt, stylua)

## ディレクトリ構造

```
dotfiles/
├── flake.nix                     # エントリーポイント - Nix Flake 定義
├── lib/
│   ├── mkSystem.nix              # 統合システムビルダー (darwin/linux)
│   └── apps.nix                  # App 定義 (`nix run .#<app>`)
├── overlays/                     # カスタムパッケージ overlay
│   ├── default.nix               # Overlay エントリーポイント
│   └── ai-tools.nix              # AI ツールバンドル (claude-code, codex)
├── modules/
│   ├── darwin/                   # macOS 固有モジュール
│   │   ├── default.nix           # Darwin モジュールのインポート
│   │   ├── system.nix            # システム設定
│   │   ├── packages.nix          # Nix パッケージ
│   │   └── homebrew.nix          # Homebrew, Cask, Mac App Store
│   ├── home/                     # home-manager モジュール（クロスプラットフォーム）
│   │   ├── default.nix           # モジュールインポートのみ（アルファベット順）
│   │   ├── dotfiles.nix          # XDG シンボリックリンク、home.file 設定
│   │   ├── packages.nix          # ユーザーパッケージ
│   │   ├── dev/                  # 言語別開発ツール (go.nix, rust.nix 等)
│   │   ├── editors/              # エディタ設定 (neovim.nix)
│   │   ├── git/                  # Git 設定 (default.nix, aliases.nix)
│   │   └── programs/             # アプリ固有設定 (claude-code.nix, codex.nix, gh.nix)
│   └── linux/
│       └── default.nix           # Linux 固有設定
├── users/                        # ユーザープロファイル定義
│   ├── kohdice/default.nix       # 個人用プロファイル
│   └── work/default.nix          # 業務用プロファイル
├── config/                       # アプリケーション設定（~/.config へシンボリックリンク）
│   ├── nvim/                     # Neovim 設定
│   ├── tmux/                     # tmux 設定
│   ├── ghostty/                  # Ghostty ターミナル設定
│   ├── lazygit/                  # lazygit 設定
│   ├── starship/                 # Starship プロンプト設定
│   ├── karabiner/                # Karabiner-Elements 設定
│   ├── git/                      # Git 設定テンプレート
│   ├── zsh/                      # Zsh 設定
│   ├── bash/                     # Bash 設定
│   ├── claude/                   # Claude Code 設定テンプレート
│   │   ├── CLAUDE.md             # ベース設定
│   │   ├── settings.json
│   │   ├── commands/             # カスタムスラッシュコマンド
│   │   └── go/, rust/, zig/      # 言語別プロジェクト設定
│   └── codex/                    # OpenAI Codex 設定テンプレート
└── docs/                         # ドキュメント
    ├── ARCHITECTURE.md           # このファイル
    ├── CUSTOMIZATION.md          # カスタマイズガイド
    ├── DARWIN-SYSTEM.md          # macOS システム設定ガイド
    ├── DEPENDENCIES.md           # 依存関係管理ガイド
    └── USAGE.md                  # 使い方ガイド
```

## ユーザープロファイル

`users/` ディレクトリで定義された 2 つのプロファイル:

| プロファイル | ユーザー名 | ホームディレクトリ | 用途   |
| ------------ | ---------- | ------------------ | ------ |
| `kohdice`    | kohdice    | `/Users/kohdice`   | 個人用 |
| `work`       | karei      | `/Users/karei`     | 業務用 |

## コマンド

```bash
# 設定のビルド（検証）
nix run .#build          # kohdice プロファイルをビルド
nix run .#build-work     # work プロファイルをビルド

# 設定の適用
nix run .#switch         # kohdice プロファイルを適用
nix run .#switch-work    # work プロファイルを適用

# コードフォーマット
nix fmt                  # Nix と Lua ファイルをフォーマット
```

## 含まれるツール

### 開発言語

| 言語        | パッケージ                    |
| ----------- | ----------------------------- |
| **Go**      | go, golangci-lint, delve      |
| **Rust**    | rustup (rust-analyzer は別途) |
| **Python**  | python3, uv, ruff             |
| **Node.js** | nodejs, pnpm, npm             |
| **Lua**     | lua, luajit                   |
| **Zig**     | zig                           |

### LSP サーバー

| 言語                  | LSP サーバー               | 管理方法 |
| --------------------- | -------------------------- | -------- |
| Go                    | gopls                      | Nix      |
| Rust                  | rust-analyzer              | rustup   |
| Python                | pyright                    | Nix      |
| TypeScript/JavaScript | typescript-language-server | Nix      |
| Lua                   | lua-language-server        | Nix      |
| Nix                   | nil                        | Nix      |
| Zig                   | zls                        | Nix      |

### CLI ツール

| カテゴリ       | ツール                                      |
| -------------- | ------------------------------------------- |
| **コアツール** | bat, curl, eza, fd, htop, jq, ripgrep, tree |
| **Git ツール** | gh, ghq, delta, lazygit, peco               |
| **ターミナル** | fastfetch, yazi, zoxide                     |
| **開発ツール** | protobuf, stylua, typos, tree-sitter, gcc   |

### macOS GUI アプリケーション（Homebrew 経由）

**Cask アプリケーション:**

- CotEditor
- Docker Desktop
- Google Japanese IME
- Karabiner-Elements
- MySQL Workbench
- Numi
- Postman
- Raycast
- Scroll Reverser
- TablePlus
- Zoom

**Mac App Store:**

- 1Password 7
- iMovie
- LINE
- RunCat
- Spark
- Xcode

## Neovim 設定

Neovim は [Lazy.nvim](https://github.com/folke/lazy.nvim) でプラグイン管理しています。

```
config/nvim/
├── init.lua                      # エントリーポイント
├── stylua.toml                   # Lua フォーマッター設定
├── lua/
│   ├── config/
│   │   ├── lazy.lua              # プラグインマネージャー設定
│   │   ├── keymaps.lua           # キーマッピング
│   │   └── options.lua           # Neovim オプション
│   └── plugins/                  # 個別プラグイン設定
└── lsp/                          # LSP サーバー設定
    ├── gopls.lua
    ├── lua_ls.lua
    ├── rust_analyzer.lua
    └── ts_ls.lua
```

## AI コーディングツール連携

### Claude Code

`config/claude/` ディレクトリに Claude Code の設定テンプレートがあります:

- **ベース設定** (`config/claude/`) - カスタムコマンドやベース CLAUDE.md
- **カスタムコマンド** (`config/claude/commands/`) - 共通のスラッシュコマンド
- **言語別設定** (`config/claude/go/`, `config/claude/rust/`, `config/claude/zig/`) - プロジェクト固有の設定

言語別設定をプロジェクトで使用するには:

```bash
# Go プロジェクトの場合
cp -r ~/developments/dotfiles/config/claude/go/.claude .
cp ~/developments/dotfiles/config/claude/go/.mcp.json .

# Rust プロジェクトの場合
cp -r ~/developments/dotfiles/config/claude/rust/.claude .
cp ~/developments/dotfiles/config/claude/rust/.mcp.json .

# Zig プロジェクトの場合
cp -r ~/developments/dotfiles/config/claude/zig/.claude .
cp ~/developments/dotfiles/config/claude/zig/.mcp.json .
```

### OpenAI Codex

`config/codex/` ディレクトリに OpenAI Codex の設定テンプレートがあります:

- **ベース設定** (`config/codex/`) - AGENTS.md など
- **言語別設定** (`config/codex/go/`, `config/codex/rust/`, `config/codex/zig/`)

## Overlays

`overlays/` でカスタムパッケージを定義し、`flake.nix` で適用します:

- **default.nix**: 全 overlay のエントリーポイント
- **ai-tools.nix**: AI 開発ツールのバンドル（claude-code, codex）

Overlay は `flake.nix` の `overlays` 変数で定義され、Darwin/Linux 両方の設定に適用されます。

## XDG シンボリックリンク

`modules/home/dotfiles.nix` で以下のシンボリックリンクが設定されます:

### ホームディレクトリ直下

| ソース                      | リンク先          |
| --------------------------- | ----------------- |
| `config/zsh/.zshenv`        | `~/.zshenv`       |
| `config/zsh/.zshrc`         | `~/.zshrc`        |
| `config/bash/.bash_profile` | `~/.bash_profile` |
| `config/bash/.bashrc`       | `~/.bashrc`       |

### ~/.config 配下

| ソース                            | リンク先                                          |
| --------------------------------- | ------------------------------------------------- |
| `config/ghostty`                  | `~/.config/ghostty`                               |
| `config/nvim`                     | `~/.config/nvim`                                  |
| `config/starship/starship.toml`   | `~/.config/starship.toml`                         |
| `config/tmux`                     | `~/.config/tmux`                                  |
| `config/lazygit`                  | `~/.config/lazygit`                               |
| `config/karabiner/karabiner.json` | `~/.config/karabiner/karabiner.json` (macOS のみ) |
