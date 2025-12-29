# Dependencies

このドキュメントでは、Nix の依存関係管理の仕組みを解説します。

## Nix Store とは

Nix はすべてのパッケージを `/nix/store/` に保存します:

```
/nix/store/
├── abc123def-nodejs-22.11.0/
├── ghi456jkl-python3-3.12.0/
├── mno789pqr-typescript-language-server-4.3.0/
└── stu012vwx-pyright-1.1.390/
```

各パッケージは**ハッシュ値**で一意に識別されます。ハッシュはパッケージの内容と依存関係から計算されるため、同じ入力なら必ず同じハッシュになります。

## 依存関係の自動解決

### 基本的な仕組み

Nix パッケージは、必要な依存関係を自動的に持ち込みます:

```
pyright (Nix パッケージ)
    │
    └── 依存: python3 → /nix/store/xxx-python3-3.12.0/
                         ↑
                  pyright 専用の Python（自動インストール）
```

- `pyright` は Python に依存していますが、Nix が自動で必要な Python を `/nix/store` にインストールします
- ユーザーが明示的に `python3` をインストールしなくても、`pyright` は動作します

### 依存関係の確認方法

```bash
# パッケージの直接の依存関係を表示
nix-store -q --references $(which pyright)

# パッケージの全依存関係をツリー表示
nix-store -q --tree $(which pyright)

# 特定のパッケージ（例: python）への依存を検索
nix path-info -r $(which pyright) | grep python
```

## バージョン共有の仕組み

### 同じバージョン → 共有される

```
ユーザーがインストール:     nodejs-22.11.0
typescript-language-server: nodejs-22.11.0
                                  ↓
                /nix/store/abc123-nodejs-22.11.0/  ← 同じパス（1 つだけ）
```

Nix はハッシュでパッケージを管理するため、同じバージョン・同じビルド設定なら同一のパスを共有します。

### 異なるバージョン → 別々に存在

```
typescript-language-server: nodejs-22.11.0 → /nix/store/abc123-nodejs-22.11.0/
eslint_d:                   nodejs-20.10.0 → /nix/store/def456-nodejs-20.10.0/
```

異なるバージョンが必要な場合、それぞれが `/nix/store` に存在します。これにより:

- **依存関係の競合が発生しない** - 各パッケージは自分の依存を持つ
- **再現性が保証される** - パッケージは常に同じ依存で動作する

## Flake による効率的な管理

### flake.lock による固定

```nix
# flake.nix
inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
```

`nix flake update` を実行すると `flake.lock` が生成され、nixpkgs の特定のリビジョンが固定されます。同じ `flake.lock` を使えば、すべてのパッケージが同じバージョンの依存を共有します:

```
flake.lock (固定されたリビジョン)
    │
    ├── typescript-language-server ─┐
    │                               ├→ nodejs-22.11.0 (共有)
    ├── nodePackages.pnpm ──────────┘
    │
    ├── pyright ────────────────────┐
    │                               ├→ python3-3.12.0 (共有)
    └── ruff ───────────────────────┘
```

### 利点

| 特徴   | 説明                                       |
| ------ | ------------------------------------------ |
| 再現性 | 同じ `flake.lock` なら同じ環境が再現される |
| 効率性 | 同じ依存は自動的に共有される               |
| 独立性 | 異なるバージョンが必要でも競合しない       |

## ランタイムマネージャーとの併用

### uv（Python）

```nix
# python.nix
home.packages = with pkgs; [
  uv      # Python version and package management
  ruff    # Linter & Formatter
  pyright # LSP
];
```

- **uv**: Python のバージョンとパッケージを管理（`~/.local/share/uv/` に保存）
- **ruff, pyright**: Nix から直接インストール（依存する Python は `/nix/store` に自動インストール）

uv を使う場合、Nix から `python3` を明示的にインストールする必要はありません:

```bash
# uv が Python をダウンロード・管理
uv python install 3.12
uv venv
uv pip install requests
```

### rustup（Rust）

```nix
# rust.nix
home.packages = with pkgs; [
  rustup         # Rust version management
  rust-analyzer  # LSP
];
```

- **rustup**: Rust ツールチェーンを管理（`~/.rustup/` に保存）
- **rust-analyzer**: Nix から直接インストール

```bash
# rustup が Rust をダウンロード・管理
rustup install stable
rustup default stable
```

### 使い分けの指針

| ツール                  | Nix で管理                 | ランタイムマネージャーで管理                   |
| ----------------------- | -------------------------- | ---------------------------------------------- |
| ランタイム本体          | 固定バージョンで十分な場合 | プロジェクトごとに異なるバージョンが必要な場合 |
| LSP                     | 推奨（システム全体で共通） | -                                              |
| リンター/フォーマッター | 推奨（システム全体で共通） | プロジェクト固有の設定が必要な場合             |

## ディスク容量の管理

### 使用量の確認

```bash
# Nix Store 全体のサイズ
du -sh /nix/store

# 現在のプロファイルが使用しているサイズ
nix path-info -Sh /run/current-system  # macOS (nix-darwin)
nix path-info -Sh ~/.nix-profile       # home-manager
```

### ガベージコレクション

古い世代や使われなくなったパッケージを削除:

```bash
# 古い世代をすべて削除してガベージコレクション
nix-collect-garbage -d

# 7 日以上前の世代のみ削除
nix-collect-garbage --delete-older-than 7d
```

### 最適化（重複排除）

```bash
# ハードリンクで重複ファイルを共有
nix-store --optimise
```

## よくある質問

### Q: パッケージ A と B が同じ依存を持つ場合、2 回インストールされる？

**A:** 同じバージョンなら 1 回だけです。Nix はハッシュで管理するため、同一のパッケージは自動的に共有されます。

### Q: 依存関係の競合は発生する？

**A:** 発生しません。各パッケージは `/nix/store` 内の独自のパスに依存するため、異なるバージョンが共存できます。

### Q: pyright を使うのに python3 をインストールする必要がある？

**A:** 不要です。pyright が依存する Python は Nix が自動的に `/nix/store` にインストールします。uv でプロジェクトの Python を管理する場合も、別途 `python3` をインストールする必要はありません。

### Q: ディスク容量が気になる

**A:** 定期的に `nix-collect-garbage -d` を実行してください。また、`nix-store --optimise` で重複ファイルを共有できます。

## 参考: 現在の構成

### Python 環境

```nix
# nix/modules/home/dev/python.nix
home.packages = with pkgs; [
  uv      # Python version and package management
  ruff    # Linter & Formatter
  pyright # LSP
];
```

- `python3` は Nix でインストールしていない
- プロジェクトの Python は uv で管理
- pyright, ruff は Nix から直接インストール（依存は自動解決）

### Node.js 環境

```nix
# nix/modules/home/dev/javascript.nix
home.packages = with pkgs; [
  nodejs
  bun
  deno
  nodePackages.pnpm
  nodePackages.npm
  nodePackages.typescript
  nodePackages.typescript-language-server
];
```

- 同じ nixpkgs リビジョンからインストールされるため、Node.js は共有される

### Rust 環境

```nix
# nix/modules/home/dev/rust.nix
home.packages = with pkgs; [
  rustup
  # rust-analyzer は rustup component add rust-analyzer で管理
];
```

- Rust ツールチェーンは rustup で管理
- rust-analyzer も rustup で管理（Rust バージョンとの整合性を保つため）

```bash
# 初回セットアップ
rustup default stable
rustup component add rust-analyzer
```
