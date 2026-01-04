# Usage

このドキュメントでは、dotfiles の使用方法とコマンドの動作を詳しく説明します。

## `nix run .#switch` とは

**仮想環境やコンテナを作成するのではなく、現在の PC 上に直接設定やツールをインストール・適用するコマンドです。**

## コマンド一覧

| コマンド                | 説明                                 |
| ----------------------- | ------------------------------------ |
| `nix run .#build`       | kohdice プロファイルをビルド（検証） |
| `nix run .#build-work`  | work プロファイルをビルド（検証）    |
| `nix run .#switch`      | kohdice プロファイルを適用           |
| `nix run .#switch-work` | work プロファイルを適用              |
| `nix run .#update`      | 全入力を更新して適用                 |
| `nix fmt`               | Nix と Lua ファイルをフォーマット    |
| `nix flake check`       | Flake 全体を検証                     |

## プラットフォーム別の動作

### macOS の場合

`nix run .#switch` は内部で以下を実行します:

```bash
sudo nix run nix-darwin -- switch --flake .#kohdice
```

### Linux の場合

`nix run .#switch` は内部で以下を実行します:

```bash
nix run nixpkgs#home-manager -- switch --flake .#kohdice
```

## 具体的に何が起こるか

### 1. システム設定の適用（macOS のみ）

`modules/darwin/` で定義された設定:

- Dock、Finder、キーボードなどの macOS システム設定
- システム全体の Nix パッケージインストール

### 2. Homebrew の管理（macOS のみ）

`modules/darwin/homebrew.nix` で定義:

- CLI ツール（brews）
- GUI アプリケーション（casks）
- Mac App Store アプリ（masApps）

### 3. ユーザー環境の構築

`modules/home/` で定義:

- CLI ツールのインストール（git, ripgrep, fzf など）
- 開発言語とツールのセットアップ（Go, Rust, Python など）
- シェル設定（zsh, bash）
- エディタ設定（Neovim）
- dotfiles のシンボリックリンク作成

## 処理の流れ

```
nix run .#switch
       │
       ▼
sudo nix run nix-darwin -- switch --flake .#kohdice  (macOS)
nix run nixpkgs#home-manager -- switch --flake .#kohdice    (Linux)
       │
       ▼
┌───────────────────────────────────────────────┐
│ 1. Nix Store にパッケージをダウンロード       │
│    (/nix/store/...)                           │
│                                               │
│ 2. シンボリックリンクで有効化                 │
│    (~/.nix-profile, /run/current-system)      │
│                                               │
│ 3. 設定ファイルを配置                         │
│    (~/.config/nvim, ~/.zshrc など)            │
│                                               │
│ 4. macOS システム設定を適用 (macOS のみ)      │
│    (Dock, Finder, キーボードなど)             │
└───────────────────────────────────────────────┘
```

## コンテナ/仮想環境との違い

| 項目     | `nix run .#switch`       | コンテナ（Docker 等）      |
| -------- | ------------------------ | -------------------------- |
| 実行場所 | 現在の PC 上             | 隔離された仮想環境         |
| 影響範囲 | ホストシステムを直接変更 | ホストに影響しない         |
| 永続性   | 設定は永続的に残る       | コンテナ停止で消える       |
| 目的     | 開発環境の構築・管理     | アプリケーションの隔離実行 |

## Nix の仕組み

### Nix Store

すべてのパッケージは `/nix/store/` に保存されます:

```
/nix/store/
├── abc123-git-2.43.0/
├── def456-ripgrep-14.0.0/
└── ghi789-neovim-0.9.0/
```

各パッケージはハッシュ値で一意に識別され、異なるバージョンを同時に保持できます。

### シンボリックリンクによる有効化

実際にパッケージを使用可能にするのはシンボリックリンクです:

```
~/.nix-profile/bin/git → /nix/store/abc123-git-2.43.0/bin/git
~/.nix-profile/bin/rg  → /nix/store/def456-ripgrep-14.0.0/bin/rg
```

### 世代管理

設定を適用するたびに新しい「世代」が作成されます。これにより以前の状態にロールバック可能です。

## 安全性について

### 可逆性

Nix は `/nix/store` にパッケージを保存し、シンボリックリンクで管理するため、以前の状態にロールバック可能です:

```bash
# macOS: 世代一覧を表示
darwin-rebuild --list-generations

# macOS: 前の世代に戻す
darwin-rebuild switch --rollback

# Linux: 世代一覧を表示
home-manager generations

# Linux: 前の世代に戻す
home-manager switch --rollback
```

### 副作用の明確化

`flake.nix` と各モジュールに定義された内容のみが適用されます。予期しない変更は行われません。

### 既存設定への影響

既存の設定ファイル（`~/.zshrc` 等）がある場合、home-manager が警告を出すか、バックアップを作成します。

## プロファイルの選択

このリポジトリには 2 つのプロファイルがあります:

| プロファイル | ユーザー名 | ホームディレクトリ | コマンド                |
| ------------ | ---------- | ------------------ | ----------------------- |
| `kohdice`    | kohdice    | `/Users/kohdice`   | `nix run .#switch`      |
| `work`       | karei      | `/Users/karei`     | `nix run .#switch-work` |

## 初回セットアップ

### 1. Nix のインストール

```bash
# Determinate Systems の Nix インストーラーを使用（推奨）
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. リポジトリのクローン

```bash
git clone https://github.com/kohdice/dotfiles.git ~/developments/dotfiles
cd ~/developments/dotfiles
```

### 3. 設定の適用

```bash
# kohdice プロファイル
nix run .#switch

# work プロファイル
nix run .#switch-work
```

## 設定変更後のワークフロー

### 1. ファイルを編集

関連する `.nix` ファイルまたは設定ファイルを編集

### 2. フォーマット

```bash
nix fmt
```

### 3. ビルド（検証）

```bash
nix run .#build       # kohdice プロファイル
nix run .#build-work  # work プロファイル
```

エラーがあればここで検出されます。

### 4. 適用

```bash
nix run .#switch       # kohdice プロファイル
nix run .#switch-work  # work プロファイル
```
