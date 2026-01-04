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
├── modules/
│   ├── darwin/                   # macOS 固有モジュール
│   │   ├── default.nix           # Darwin モジュールのインポート
│   │   ├── system.nix            # システム設定
│   │   ├── packages.nix          # Nix パッケージ
│   │   └── homebrew.nix          # Homebrew, Cask, Mac App Store
│   ├── home/                     # home-manager モジュール（クロスプラットフォーム）
│   │   ├── default.nix           # モジュールインポートのみ
│   │   ├── dotfiles.nix          # XDG シンボリックリンク、home.file 設定
│   │   ├── packages.nix          # ユーザーパッケージ
│   │   ├── dev/                  # 言語別開発ツール
│   │   ├── editors/              # エディタ設定 (neovim.nix)
│   │   ├── git/                  # Git 設定 (default.nix, aliases.nix)
│   │   ├── jj/                   # Jujutsu VCS 設定
│   │   ├── programs/             # アプリ固有設定 (zsh.nix, bash.nix, gh.nix)
│   │   ├── shell/                # 共通シェル設定 (aliases.nix, env.nix, paths.nix)
│   │   └── ssh/                  # SSH 設定
│   └── linux/
│       ├── default.nix           # Linux 固有設定
│       └── packages.nix          # Linux 固有パッケージ
├── users/                        # ユーザープロファイル定義
│   ├── kohdice/                  # 個人用プロファイル
│   │   ├── default.nix           # プロファイルエクスポート
│   │   ├── info.nix              # ユーザー情報 (name, email, home, dotfilesDir)
│   │   ├── home.nix              # home-manager オーバーライド
│   │   └── darwin.nix            # Darwin 固有オーバーライド
│   └── work/                     # 業務用プロファイル (同様の構造)
├── config/                       # アプリケーション設定（シンボリックリンク経由）
│   ├── nvim/                     # Neovim 設定
│   ├── tmux/                     # tmux 設定
│   ├── ghostty/                  # Ghostty ターミナル設定
│   ├── lazygit/                  # lazygit 設定
│   ├── starship/                 # Starship プロンプト設定
│   ├── karabiner/                # Karabiner-Elements 設定 (macOS のみ)
│   ├── git/                      # Git 設定
│   ├── jj/                       # Jujutsu VCS 設定
│   ├── zsh/                      # Zsh 設定
│   ├── bash/                     # Bash 設定
│   ├── claude/                   # Claude Code 設定
│   └── codex/                    # OpenAI Codex 設定
└── docs/                         # ドキュメント
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

# パッケージの更新
nix run .#update         # 全入力を更新して適用

# コードフォーマット
nix fmt                  # Nix と Lua ファイルをフォーマット
```

## 含まれるツール

### 開発言語

| 言語        | パッケージ                          |
| ----------- | ----------------------------------- |
| **Go**      | go, golangci-lint, delve            |
| **Rust**    | rustup (rust-analyzer は rustup で) |
| **Python**  | uv, ruff, pyright                   |
| **Node.js** | nodejs_24, bun, deno, typescript    |
| **Lua**     | lua, luajit                         |
| **C/C++**   | gcc, clang-tools                    |
| **Zig**     | zig, zls                            |

### LSP サーバー

| 言語                  | LSP サーバー               | 管理方法 |
| --------------------- | -------------------------- | -------- |
| Go                    | gopls                      | Nix      |
| Rust                  | rust-analyzer              | rustup   |
| Python                | pyright                    | Nix      |
| TypeScript/JavaScript | typescript-language-server | Nix      |
| Lua                   | lua-language-server        | Nix      |
| C/C++                 | clangd                     | Nix      |
| JSON                  | vscode-langservers-json    | Nix      |
| YAML                  | yaml-language-server       | Nix      |
| TOML                  | taplo                      | Nix      |
| Nix                   | nil                        | Nix      |
| Zig                   | zls                        | Nix      |
| Markdown              | marksman                   | Nix      |

### CLI ツール

| カテゴリ       | ツール                                                   |
| -------------- | -------------------------------------------------------- |
| **コアツール** | bat, curl, dust, eza, fd, fzf, htop, jq, ripgrep, tree   |
| **Git ツール** | gh, ghq, delta, lazygit                                  |
| **ターミナル** | fastfetch, navi, starship, yazi, zoxide                  |
| **開発ツール** | protobuf, typos, tree-sitter                             |
| **AI ツール**  | claude-code, codex                                       |

### macOS GUI アプリケーション

**Nix パッケージ（システムレベル）:**

- Karabiner-Elements
- Scroll Reverser

**Nix パッケージ（ユーザーレベル）:**

- Discord (macOS / x86_64-linux のみ)
- Google Chrome
- Slack
- TablePlus
- VS Code

**Homebrew Cask:**

- ChatGPT
- Claude
- CotEditor
- Docker Desktop
- Ghostty
- Google Japanese IME
- Numi
- Postman
- Raycast
- VLC
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
│   ├── plugins/                  # 個別プラグイン設定
│   └── utils/                    # ユーティリティ関数
└── lsp/                          # LSP サーバー設定
    ├── clangd.lua
    ├── gopls.lua
    ├── jsonls.lua
    ├── lua_ls.lua
    ├── rust_analyzer.lua
    ├── taplo.lua
    ├── ts_ls.lua
    └── yamlls.lua
```

## AI コーディングツール連携

`modules/home/dotfiles.nix` で設定ファイルのシンボリックリンクを管理しています。

### Claude Code

`config/claude/` ディレクトリに Claude Code の設定があります:

- **CLAUDE.md** - プロジェクト固有の指示
- **settings.json** - Claude Code の設定
- **statusline.sh** - ステータスライン用スクリプト
- **mcp.json** - MCP サーバー設定テンプレート

シンボリックリンク先: `~/.claude/`

### OpenAI Codex

`config/codex/` ディレクトリに OpenAI Codex の設定があります:

- **AGENTS.md** - エージェント設定
- **config.toml** - Codex 設定

シンボリックリンク先: `~/.codex/`

## シンボリックリンク

`modules/home/dotfiles.nix` で以下のシンボリックリンクが設定されます:

### ホームディレクトリ直下 (home.file)

| ソース                        | リンク先                  |
| ----------------------------- | ------------------------- |
| `config/claude/CLAUDE.md`     | `~/.claude/CLAUDE.md`     |
| `config/claude/settings.json` | `~/.claude/settings.json` |
| `config/claude/statusline.sh` | `~/.claude/statusline.sh` |
| `config/codex/AGENTS.md`      | `~/.codex/AGENTS.md`      |
| `config/codex/config.toml`    | `~/.codex/config.toml`    |

### ~/.config 配下 (xdg.configFile)

| ソース                            | リンク先                                          |
| --------------------------------- | ------------------------------------------------- |
| `config/ghostty`                  | `~/.config/ghostty`                               |
| `config/nvim`                     | `~/.config/nvim`                                  |
| `config/starship/starship.toml`   | `~/.config/starship.toml`                         |
| `config/tmux`                     | `~/.config/tmux`                                  |
| `config/lazygit`                  | `~/.config/lazygit`                               |
| `config/karabiner/karabiner.json` | `~/.config/karabiner/karabiner.json` (macOS のみ) |

## 設定ファイル管理の方針

アプリケーション設定を Nix モジュール（`programs.*`）で管理するか、シンボリンクで管理するかの判断基準：

### Nix 管理が適切な条件

1. **動的な値の注入が必要** - `user.email`, `user.fullName` 等のプロファイル依存値
2. **home-manager との統合が必要** - `home.sessionPath`, `home.sessionVariables`
3. **他の Nix モジュールとの連携** - 例: `programs.delta` + `programs.git`
4. **宣言的オプションで大部分を表現可能** - `extraConfig` が 50% 未満

### シンボリンクが適切な条件

1. **設定が複雑で extraConfig が大部分** - 50% 以上
2. **ファイル分割・条件分岐がネイティブに可能** - `source`, `if-shell` 等
3. **独自言語でシンタックスハイライトが重要** - Lua, tmux 設定等
4. **home-manager との統合が不要** - 環境変数や PATH はシェルから継承

### 現在の構成

| アプリ         | 管理方法     | 理由                                     |
| -------------- | ------------ | ---------------------------------------- |
| git, jj        | Nix          | `user.*` 注入、100% 宣言的               |
| zsh, bash      | Nix          | `home.sessionPath` 統合が必須            |
| ssh            | Nix          | ホスト設定など宣言的管理が適切           |
| claude, codex  | シンボリンク | 設定ファイルの直接編集が多い             |
| tmux           | シンボリンク | 20% しか宣言的でない、ファイル分割が必要 |
| neovim         | シンボリンク | Lua 言語、home-manager 統合不要          |
| ghostty        | シンボリンク | home-manager 統合不要                    |
| starship       | シンボリンク | home-manager 統合不要                    |
| lazygit        | シンボリンク | home-manager 統合不要                    |
| karabiner      | シンボリンク | JSON 設定、macOS のみ                    |
