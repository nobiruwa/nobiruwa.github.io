---
title: EmacsでのHaskell開発
author: nobiruwa
tags: Haskell, Emacs, LSP
---

## tl;dr

[GHCup](https://www.haskell.org/ghcup/)でHaskellのtoolchainをインストールできるようになりました。

## GHCupのインストールとセットアップ

まずは`~/.ghcup`に`ghcup`コマンドとほかのtoolchainをインストールします。

以下の1コマンドで終わります。

```console
$ curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
```

インストールの途中にシステム要件が表示されるので、その通りにパッケージをインストールします。

```console
$ sudo apt install build-essential curl libffi-dev libffi6 libgmp-dev libgmp10 libncurses-dev libncurses5 libtinfo5
```

`~/.profile`にて、環境変数`PATH`を設定します。

```bash
GHCUP_HOME="$HOME/.ghcup"
GHCUP_BIN="$GHCUP_HOME/bin"
if [ -d "$GHCUP_BIN" ]; then
    export PATH="$GHCUP_BIN:$PATH"
fi
```

あらゆるプロジェクトでのビルドで並列実行数を制限する場合はstackのグローバルな設定ファイルにGHCオプションを記述します。`~/.stack/config.yaml`に以下の行を追加するとよいでしょう。

```yaml
ghc-options:
  "$locals": -j1
```

### Emacs

#### Emacsパッケージのインストール

```emacs
M-x package-install
lsp-haskell
```

#### Emacsパッケージの設定

rust-modeを真似てバッファー全体にフォーマットを掛けてから保存されるようにしています。

```lisp
;;;;;;;;
;; lsp-haskell
;;;;;;;;
(require 'lsp-haskell)
(setq lsp-haskell-formatting-provider "brittany")

;; rust-modeを参考にバッファーを保存する時にフォーマットする
(defcustom haskell-format-on-save nil
  "Format future haskell buffers before saving using lsp-haskell-formatting-provider."
  :type 'boolean
  :safe #'booleanp
  :group 'lsp-haskell-mode)

(defun haskell-enable-format-on-save ()
  "Enable formatting using lsp-haskell-formatting-provider when saving buffer."
  (interactive)
  (setq-local haskell-format-on-save t))

(defun haskell-disable-format-on-save ()
  "Disable formatting using lsp-haskell-formatting-provider when saving buffer."
  (interactive)
  (setq-local haskell-format-on-save nil))

(defun haskell-format-save-hook ()
  "Enable formatting using lsp-haskell-formatting-provider when saving buffer."
  (when haskell-format-on-save
      (lsp-format-buffer)))

;; lsp-format-buffer, lsp-format-regionが使用するインデント幅を
;; haskell-modeのhaskell-indentation-layout-offsetに合わせる
(add-to-list 'lsp--formatting-indent-alist '(haskell-mode . haskell-indentation-layout-offset))

(add-hook 'before-save-hook #'haskell-format-save-hook)

(add-hook 'haskell-mode-hook
          (lambda ()
            (setq-local haskell-format-on-save t)
            (lsp)))
```

### プロジェクトの作成

```console
$ stack new --resolver=<resolver name> <project-name>
// example
$ stack new --resolver=lts-18.27 http-conduit-example
```

haskell-language-serverがプロジェクトのセットアップに失敗する場合はプロジェクトの設定ファイルを作成してみます。
設定に関する詳細は[haskell-language-serverのREADME](https://github.com/haskell/haskell-language-server#project-configuration)と[hie-biosのREADME](https://github.com/mpickering/hie-bios/blob/master/README.md#stack)の通りですが、以下に最小の設定を示します。

```yaml
cradle:
  stack:
```
