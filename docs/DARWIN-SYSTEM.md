# Darwin System Settings (system.nix)

このドキュメントでは、`nix/modules/darwin/system.nix` で管理される macOS システム設定について説明します。

## 概要

### system.nix とは

`system.nix` は nix-darwin を使って macOS のシステムデフォルト設定を宣言的に管理するファイルです。macOS の「システム設定」アプリで行う設定の多くを、コードとして記述・管理できます。

### nix-darwin の system.defaults

nix-darwin の `system.defaults` は、macOS の `defaults` コマンドでアクセスできる設定項目を、Nix の設定ファイルとして管理します。これにより：

- **再現性**: 同じ設定を別のマシンでも簡単に再現できる
- **バージョン管理**: Git で設定の履歴を追跡できる
- **宣言的**: 「何をするか」ではなく「どうあるべきか」を記述

### 役割と位置づけ

```
flake.nix
  └─ darwinConfigurations
      └─ nix/modules/darwin/default.nix
          ├─ system.nix          ← システムデフォルト設定（このファイル）
          ├─ packages.nix        ← システムレベルパッケージ
          └─ homebrew.nix        ← Homebrew/Cask/MAS
```

`system.nix` は Darwin モジュールの一部として読み込まれ、macOS システム全体の動作を制御します。

---

## 現在の設定項目一覧

現在 `system.nix` で管理している設定項目：

| カテゴリ           | 設定項目数 | 概要                                                 |
| ------------------ | ---------- | ---------------------------------------------------- |
| **Dock**           | 6項目      | Dock の表示・動作設定                                |
| **Finder**         | 8項目      | Finder の表示・動作設定                              |
| **NSGlobalDomain** | 9項目      | システム全体の設定（キーボード、テキスト入力、外観） |
| **Trackpad**       | 3項目      | トラックパッドのジェスチャー設定                     |
| **Menu Bar Clock** | 4項目      | メニューバーの時計表示設定                           |
| **セキュリティ**   | 1項目      | Touch ID for sudo                                    |
| **フォント**       | 1項目      | システムフォント                                     |

**合計: 32項目**

---

## 各設定の詳細説明

### Dock 設定

macOS の Dock の表示と動作を制御します。

```nix
dock = {
  autohide = true;
  tilesize = 36;
  magnification = false;
  show-recents = false;
  minimize-to-application = false;
};
```

#### 設定項目の詳細

| 設定項目                  | 値      | 説明                                                                       |
| ------------------------- | ------- | -------------------------------------------------------------------------- |
| `autohide`                | `true`  | Dock を自動的に隠す。マウスカーソルを画面端に移動すると表示される          |
| `tilesize`                | `36`    | Dock のアイコンサイズ（ピクセル単位）。デフォルトは約 48                   |
| `magnification`           | `false` | Dock にマウスを合わせた時のアイコン拡大機能を無効化                        |
| `show-recents`            | `false` | Dock の右側に「最近使ったアプリケーション」を表示しない                    |
| `minimize-to-application` | `false` | ウィンドウ最小化時、アプリアイコンではなく Dock の右側の最小化エリアに表示 |

**システム設定での対応箇所:**
「システム設定」→「デスクトップと Dock」

---

### Finder 設定

Finder の表示と動作を制御します。

```nix
finder = {
  AppleShowAllFiles = true;
  ShowPathbar = true;
  ShowStatusBar = true;
  ShowExternalHardDrivesOnDesktop = true;
  ShowHardDrivesOnDesktop = false;
  ShowRemovableMediaOnDesktop = true;
  _FXSortFoldersFirst = true;
  NewWindowTarget = "PfHm";
};
```

#### 設定項目の詳細

| 設定項目                          | 値       | 説明                                                             |
| --------------------------------- | -------- | ---------------------------------------------------------------- |
| `AppleShowAllFiles`               | `true`   | 隠しファイル（ドットファイル）を表示する                         |
| `ShowPathbar`                     | `true`   | ウィンドウ下部にパスバーを表示                                   |
| `ShowStatusBar`                   | `true`   | ウィンドウ下部にステータスバーを表示（選択項目数、空き容量など） |
| `ShowExternalHardDrivesOnDesktop` | `true`   | デスクトップに外付けハードドライブのアイコンを表示               |
| `ShowHardDrivesOnDesktop`         | `false`  | デスクトップに内蔵ハードドライブのアイコンを表示しない           |
| `ShowRemovableMediaOnDesktop`     | `true`   | デスクトップにリムーバブルメディア（USB メモリなど）を表示       |
| `_FXSortFoldersFirst`             | `true`   | ファイル一覧で、フォルダを常に最初に表示（名前順ソート時）       |
| `NewWindowTarget`                 | `"PfHm"` | 新規 Finder ウィンドウで開く場所（"PfHm" = ホームフォルダ）      |

**システム設定での対応箇所:**

- 「システム設定」→「デスクトップと Dock」→「デスクトップとステージマネージャ」
- Finder メニュー →「表示」

**NewWindowTarget の値:**

- `"PfHm"` - ホームフォルダ（~/）
- `"PfDe"` - デスクトップ
- `"PfDo"` - 書類フォルダ
- `"PfLo"` - その他の場所
- `"file:///path/to/folder/"` - 任意のパス

---

### NSGlobalDomain 設定

システム全体に影響する設定です。

```nix
NSGlobalDomain = {
  KeyRepeat = 1;
  InitialKeyRepeat = 10;
  AppleInterfaceStyle = "Dark";
  ApplePressAndHoldEnabled = false;
  NSAutomaticCapitalizationEnabled = true;
  NSAutomaticDashSubstitutionEnabled = true;
  NSAutomaticPeriodSubstitutionEnabled = true;
  NSAutomaticQuoteSubstitutionEnabled = true;
  NSAutomaticSpellingCorrectionEnabled = true;
};
```

#### キーボード設定

| 設定項目                   | 値      | 説明                                                                                       |
| -------------------------- | ------- | ------------------------------------------------------------------------------------------ |
| `KeyRepeat`                | `1`     | キーリピート速度。1が最速、120が最遅（デフォルト: 6）                                      |
| `InitialKeyRepeat`         | `10`    | キーリピート開始までの遅延。10が最短、120が最長（デフォルト: 25）                          |
| `ApplePressAndHoldEnabled` | `false` | キーの長押しでアクセント文字メニューを無効化。開発者向け：長押しでキーリピートを有効にする |

**システム設定での対応箇所:**
「システム設定」→「キーボード」→「キーボード」→「キーのリピート」「リピート入力認識までの時間」

**KeyRepeat の値の目安:**

- `1-2`: 非常に速い（開発者向け）
- `2-6`: 標準的な速さ
- `6-15`: やや遅い

#### 外観設定

| 設定項目              | 値       | 説明                             |
| --------------------- | -------- | -------------------------------- |
| `AppleInterfaceStyle` | `"Dark"` | システム外観をダークモードに設定 |

**値の選択肢:**

- `"Dark"` - ダークモード
- 設定なし（または削除） - ライトモード

**システム設定での対応箇所:**
「システム設定」→「外観」

#### テキスト入力の自動補正設定

| 設定項目                               | 値     | 説明                                                     |
| -------------------------------------- | ------ | -------------------------------------------------------- |
| `NSAutomaticCapitalizationEnabled`     | `true` | 文の最初の文字を自動的に大文字にする                     |
| `NSAutomaticDashSubstitutionEnabled`   | `true` | ハイフン2つ（`--`）を em ダッシュ（`—`）に自動変換       |
| `NSAutomaticPeriodSubstitutionEnabled` | `true` | スペースを2回押すとピリオド（`.`）とスペースに変換       |
| `NSAutomaticQuoteSubstitutionEnabled`  | `true` | ストレート引用符（`" "`）をスマート引用符（`" "`）に変換 |
| `NSAutomaticSpellingCorrectionEnabled` | `true` | スペルミスを自動修正する                                 |

**システム設定での対応箇所:**
「システム設定」→「キーボード」→「テキスト入力」→「編集」

**開発者向けヒント:**
コードエディタでこれらの自動補正が邪魔な場合は、`false` に設定することをおすすめします。

---

### Trackpad 設定

トラックパッドのジェスチャー設定です。

```nix
trackpad = {
  Clicking = true;
  TrackpadRightClick = true;
  TrackpadThreeFingerTapGesture = 0;
};
```

#### 設定項目の詳細

| 設定項目                        | 値     | 説明                                                          |
| ------------------------------- | ------ | ------------------------------------------------------------- |
| `Clicking`                      | `true` | タップでクリック（Tap to Click）を有効化                      |
| `TrackpadRightClick`            | `true` | 2本指でクリックまたはタップで右クリック（副ボタンのクリック） |
| `TrackpadThreeFingerTapGesture` | `0`    | 3本指タップジェスチャーを無効化（0 = 無効）                   |

**システム設定での対応箇所:**
「システム設定」→「トラックパッド」

**TrackpadThreeFingerTapGesture の値:**

- `0` - 無効
- `2` - 調べる & データ検出

---

### Menu Bar Clock 設定

メニューバーの時計表示をカスタマイズします。

```nix
menuExtraClock = {
  Show24Hour = true;
  ShowDate = false;
  ShowDayOfWeek = true;
  ShowSeconds = true;
};
```

#### 設定項目の詳細

| 設定項目        | 値      | 説明                                                          |
| --------------- | ------- | ------------------------------------------------------------- |
| `Show24Hour`    | `true`  | 24時間表示（例: 13:45）。`false` で 12時間表示（例: 1:45 PM） |
| `ShowDate`      | `false` | 日付を表示しない（例: 12月29日 を非表示）                     |
| `ShowDayOfWeek` | `true`  | 曜日を表示（例: 日、月、火 など）                             |
| `ShowSeconds`   | `true`  | 秒を表示（例: 13:45:23）                                      |

**表示例:**

- 現在の設定: `日 13:45:23`
- すべて有効化: `12月29日(日) 13:45:23`

**システム設定での対応箇所:**
「システム設定」→「コントロールセンター」→「時計のオプション」

---

### セキュリティ設定

```nix
security.pam.enableSudoTouchIdAuth = true;
```

#### 設定項目の詳細

| 設定項目                | 値     | 説明                                                    |
| ----------------------- | ------ | ------------------------------------------------------- |
| `enableSudoTouchIdAuth` | `true` | `sudo` コマンド実行時に Touch ID で認証できるようにする |

**使用例:**

```bash
$ sudo apt install something
[Touch ID で認証]
```

これにより、ターミナルで `sudo` を実行する際、パスワード入力の代わりに Touch ID を使用できます。

---

### フォント設定

```nix
fonts.packages = with pkgs; [
  nerd-fonts.jetbrains-mono
];
```

#### 設定項目の詳細

システム全体で利用可能なフォントを追加します。

- **JetBrains Mono Nerd Font**: プログラミング用フォント。アイコングリフを含む Nerd Fonts パッチ版

**Nerd Fonts とは:**
開発者向けアイコンフォント（Font Awesome、Devicons、Octicons など）を統合したフォントコレクション。ターミナルやエディタで使用すると、Git ブランチアイコンやファイルタイプアイコンが表示されます。

---

## カスタマイズ方法

### 設定値の変更

`nix/modules/darwin/system.nix` を編集して、既存の設定値を変更します。

**例: Dock のアイコンサイズを変更**

```nix
dock = {
  tilesize = 48;  # 36 → 48 に変更
  # 他の設定...
};
```

### 新しい設定の追加

利用可能な設定オプションを調べて、`system.defaults` に追加します。

**例: Dock の位置を変更**

```nix
dock = {
  # 既存の設定...
  orientation = "left";  # Dock を左側に配置
};
```

**Dock の位置の値:**

- `"bottom"` - 画面下部（デフォルト）
- `"left"` - 画面左側
- `"right"` - 画面右側

### 利用可能な設定オプションの調べ方

#### 1. nix-darwin 公式ドキュメント

[nix-darwin Options - MyNixOS](https://mynixos.com/nix-darwin/options) で `system.defaults` を検索:

```
system.defaults.dock.*
system.defaults.finder.*
system.defaults.NSGlobalDomain.*
system.defaults.trackpad.*
```

#### 2. 現在の macOS 設定を確認

```bash
# Dock の設定を確認
defaults read com.apple.dock

# Finder の設定を確認
defaults read com.apple.finder

# NSGlobalDomain の設定を確認
defaults read NSGlobalDomain
```

#### 3. nix-darwin のソースコードを確認

[GitHub: nix-darwin/modules/system/defaults](https://github.com/LnL7/nix-darwin/tree/master/modules/system/defaults)

各ファイル（`dock.nix`, `finder.nix` など）で利用可能なオプションが定義されています。

---

## 設定の適用

### ビルド & 適用コマンド

設定を変更したら、以下のコマンドでビルド・適用します。

```bash
# 1. ビルドテスト（エラーがないか確認）
nix run .#build

# 2. 設定を適用
nix run .#switch

# 3. 変更を即座に反映（オプション）
killall Dock      # Dock を再起動
killall Finder    # Finder を再起動
```

**プロファイル別の適用:**

```bash
# kohdice プロファイル（個人用）
nix run .#switch

# work プロファイル（仕事用）
nix run .#switch-work
```

### 設定確認方法

適用後、設定が正しく反映されているか確認します。

```bash
# Dock の設定を確認
defaults read com.apple.dock autohide
defaults read com.apple.dock tilesize

# Finder の設定を確認
defaults read com.apple.finder AppleShowAllFiles
defaults read com.apple.finder ShowPathbar

# NSGlobalDomain の設定を確認
defaults read NSGlobalDomain KeyRepeat
defaults read NSGlobalDomain AppleInterfaceStyle

# Trackpad の設定を確認
defaults read com.apple.AppleMultitouchTrackpad Clicking

# Menu Bar Clock の設定を確認
defaults read com.apple.menuextra.clock Show24Hour
```

**期待される出力例:**

```bash
$ defaults read com.apple.dock autohide
1

$ defaults read NSGlobalDomain KeyRepeat
1
```

（`1` = `true`、`0` = `false`）

---

## トラブルシューティング

### 設定が反映されない

**原因 1: Dock/Finder が再起動されていない**

一部の設定は Dock や Finder の再起動が必要です。

```bash
killall Dock
killall Finder
```

**原因 2: 再ログインが必要**

NSGlobalDomain や外観設定など、一部の設定は再ログインまたは再起動が必要な場合があります。

```bash
# macOS を再起動
sudo reboot
```

**原因 3: 設定の優先順位**

macOS の「システム設定」で手動変更した設定が優先される場合があります。nix-darwin で管理する設定は、手動で変更しないようにしてください。

### ビルドエラーが発生する

**エラー例:**

```
error: attribute 'unknownOption' missing
```

**解決策:**

- オプション名のスペルミスを確認
- nix-darwin でサポートされていないオプションの可能性。公式ドキュメントで確認

**構文エラー:**

```nix
# ❌ 間違い
dock = {
  autohide = true  # セミコロンがない
};

# ✅ 正しい
dock = {
  autohide = true;
};
```

### 設定値をリセットしたい

特定の設定をデフォルト値に戻す場合、`system.nix` から該当行を削除または コメントアウトします。

```nix
dock = {
  autohide = true;
  # tilesize = 36;  # この設定を無効化（デフォルト値を使用）
};
```

その後、設定を再適用:

```bash
nix run .#switch
killall Dock
```

---

## 参考リソース

### 公式ドキュメント

- [nix-darwin 公式ドキュメント](https://daiderd.com/nix-darwin/)
- [nix-darwin GitHub リポジトリ](https://github.com/LnL7/nix-darwin)
- [nix-darwin Options - MyNixOS](https://mynixos.com/nix-darwin/options)

### system.defaults オプション一覧

- [system.defaults.dock オプション](https://mynixos.com/nix-darwin/options/system.defaults.dock)
- [system.defaults.finder オプション](https://mynixos.com/nix-darwin/options/system.defaults.finder)
- [system.defaults.NSGlobalDomain オプション](https://mynixos.com/nix-darwin/options/system.defaults.NSGlobalDomain)
- [system.defaults.trackpad オプション](https://mynixos.com/nix-darwin/options/system.defaults.trackpad)

### 関連ドキュメント

- [ARCHITECTURE.md](./ARCHITECTURE.md) - リポジトリ全体の構造
- [CUSTOMIZATION.md](./CUSTOMIZATION.md) - カスタマイズ方法
- [USAGE.md](./USAGE.md) - 使い方とコマンド
