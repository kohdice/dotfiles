# Customization

このドキュメントでは、dotfiles のカスタマイズ方法を説明します。

## パッケージの追加

### Nix パッケージ（クロスプラットフォーム）

ユーザーパッケージは `modules/home/packages.nix` に追加:

```nix
home.packages = with pkgs; [
  # 既存のパッケージ
  bat
  curl
  # 新しいパッケージを追加
  your-package
];
```

### 開発言語の追加

`modules/home/dev/` に言語ごとのファイルを作成:

```nix
# modules/home/dev/your-language.nix
{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    your-language
    your-language-tools
    your-language-lsp  # LSP サーバーも含める
  ];
}
```

`modules/home/dev/default.nix` でインポート:

```nix
{
  imports = [
    ./go.nix
    ./rust.nix
    ./your-language.nix  # 追加
  ];
}
```

### macOS 専用パッケージ

`modules/darwin/packages.nix` に追加:

```nix
environment.systemPackages = with pkgs; [
  your-macos-package
];
```

### Homebrew パッケージ（macOS のみ）

`modules/darwin/homebrew.nix` を編集:

```nix
homebrew = {
  # CLI ツール
  brews = [
    "your-brew-package"
  ];

  # GUI アプリケーション
  casks = [
    "your-cask-app"
  ];

  # Mac App Store アプリ
  masApps = {
    "App Name" = 123456789;  # App Store ID
  };
};
```

### カスタム Overlay の追加

`overlays/` にカスタムパッケージを定義できます:

```nix
# overlays/my-tools.nix
final: prev: {
  my-tool-bundle = final.symlinkJoin {
    name = "my-tool-bundle";
    paths = with final; [
      tool1
      tool2
    ];
  };
}
```

`overlays/default.nix` でインポート:

```nix
final: prev:
{
}
// (import ./ai-tools.nix final prev)
// (import ./my-tools.nix final prev)  # 追加
```

## 新しいプロファイルの作成

### 1. ユーザー定義を追加

`users/` ディレクトリに新しいプロファイルを作成:

```nix
# users/newprofile/default.nix
{
  user = {
    name = "username";
    fullName = "Your Name";
    email = "your@email.com";
    home = "/Users/username";  # macOS の場合
    # home = "/home/username";  # Linux の場合
  };
}
```

### 2. flake.nix に設定を追加

`flake.nix` で新しいプロファイルを追加:

```nix
# macOS の場合
darwinConfigurations = {
  kohdice = mkSystem "darwin" { system = darwinSystem; user = "kohdice"; };
  work = mkSystem "darwin" { system = darwinSystem; user = "work"; };
  newprofile = mkSystem "darwin" { system = darwinSystem; user = "newprofile"; };  # 追加
};

# Linux の場合
homeConfigurations = {
  kohdice = mkSystem "linux" { system = "x86_64-linux"; user = "kohdice"; };
  work = mkSystem "linux" { system = "x86_64-linux"; user = "work"; };
  newprofile = mkSystem "linux" { system = "x86_64-linux"; user = "newprofile"; };  # 追加
};
```

### 3. 対応するコマンドを追加（オプション）

`lib/apps.nix` に新しいプロファイル用コマンドを追加:

```nix
# Build configuration (newprofile)
build-newprofile = {
  type = "app";
  program = toString (
    pkgs.writeShellScript "build-newprofile" (
      if isDarwin then
        ''
          nix build .#darwinConfigurations.newprofile.system
        ''
      else
        ''
          nix build .#homeConfigurations.newprofile.activationPackage
        ''
    )
  );
  meta.description = "Build newprofile profile";
};

# Apply configuration (newprofile)
switch-newprofile = {
  type = "app";
  program = toString (
    pkgs.writeShellScript "switch-newprofile" (
      if isDarwin then
        ''
          darwin-rebuild switch --flake .#newprofile
        ''
      else
        ''
          home-manager switch --flake .#newprofile
        ''
    )
  );
  meta.description = "Apply newprofile profile";
};
```

## シンボリックリンクの追加

`modules/home/dotfiles.nix` でシンボリックリンクを管理しています:

```nix
# ホームディレクトリ直下へのリンク
home.file = {
  ".your-config".source = "${dotfilesDir}/config/your-app/.your-config";
};

# ~/.config 配下へのリンク
xdg.configFile = {
  "your-app".source = "${dotfilesDir}/config/your-app";
};
```

## アプリケーション設定の変更

### シェル設定

- **Zsh**: `config/zsh/.zshrc`, `config/zsh/.zshenv`
- **Bash**: `config/bash/.bashrc`, `config/bash/.bash_profile`

### ターミナル設定

- **Ghostty**: `config/ghostty/config`
- **tmux**: `config/tmux/tmux.conf`

### エディター設定

- **Neovim**: `config/nvim/` 配下
  - オプション: `lua/config/options.lua`
  - キーマップ: `lua/config/keymaps.lua`
  - プラグイン: `lua/plugins/` 配下
  - LSP: `lsp/` 配下

### その他ツール

- **Starship**: `config/starship/starship.toml`
- **lazygit**: `config/lazygit/config.yml`
- **Git**: `config/git/` 配下

## 設定変更のワークフロー

### 1. 編集

関連する `.nix` ファイルまたは設定ファイルを編集

### 2. フォーマット

```bash
nix fmt
```

### 3. ビルド（検証）

```bash
# kohdice プロファイル
nix run .#build

# work プロファイル
nix run .#build-work
```

### 4. 適用

```bash
# kohdice プロファイル
nix run .#switch

# work プロファイル
nix run .#switch-work
```

## Flake の検証

```bash
# Flake 全体の検証
nix flake check

# 詳細なエラー出力
nix run .#build 2>&1 | less
```

## トラブルシューティング

### ビルドエラー

```bash
# 詳細なエラー出力を確認
nix run .#build 2>&1 | less

# Flake の評価を検証
nix flake check

# 特定の出力をデバッグ
nix eval .#darwinConfigurations.work.system --show-trace
```

### ロールバック

macOS では以前の世代に戻すことができます:

```bash
# 世代一覧を表示
darwin-rebuild --list-generations

# 前の世代に戻す
darwin-rebuild switch --rollback

# 特定の世代に切り替え
darwin-rebuild switch --switch-generation <番号>
```

Linux (home-manager) の場合:

```bash
# 世代一覧を表示
home-manager generations

# 前の世代に戻す
home-manager switch --rollback
```

### キャッシュ問題

```bash
# 古い世代をガベージコレクション
nix-collect-garbage -d

# Nix ストアの検証と修復
nix-store --verify --check-contents --repair
```

### Homebrew 同期問題

```bash
# Homebrew パッケージを強制的に同期
brew bundle cleanup --force

# Homebrew をアップデート
brew update && brew upgrade
```
