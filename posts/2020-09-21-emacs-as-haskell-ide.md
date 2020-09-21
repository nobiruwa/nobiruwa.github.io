---
title: EmacsでのHaskell開発
author: nobiruwa
tags: Haskell, Emacs, LSP
---

## tl;dr

[lsp-haskell](https://github.com/emacs-lsp/lsp-haskell)のバックエンドとして[haskell-language-server](https://github.com/haskell/haskell-language-server)を使うようにセットアップしました。

### 切っ掛け

[haskell-ide-engine](https://github.com/haskell/haskell-ide-engine)を使っていましたが、haskell-ide-engineと[ghcide](https://github.com/haskell/ghcide/)は統合されhaskell-language-serverによって置き換えられました。2020年9月21日時点のlsp-haskellはバックエンドがhaskell-language-serverに切り替わっていました。

## lsp-haskell + haskell-language-server の構築手順

### haskell-language-server

haskell-language-serverの[Installation](https://github.com/haskell/haskell-language-server#installation)に従ってバイナリをインストールします。

#### Prerequistes

```bash
$ sudo apt-get install libicu-dev libncurses-dev libgmp-dev zlib1g-dev
```

#### haskell-language-serverのビルド

```bash
$ cd ~/repo
$ git clone https://github.com/haskell/haskell-language-server --recurse-submodules haskell-language-server.git
$ cd haskell-language-server.git
```

```bash
$ stack ./install.hs help

Usage:
    stack install.hs <target> [options]
    or
    cabal v2-run install.hs --project-file install/shake.project -- <target> [options]

Targets:
    help                Show help message including all targets
                        
    hls                 Install haskell-language-server with the latest available GHC and the data files
    latest              Install haskell-language-server with the latest available GHC
    data                Get the required data-files for `haskell-language-server` (Hoogle DB)
    hls-8.10.1          Install haskell-language-server for GHC version 8.10.1
    hls-8.10.2          Install haskell-language-server for GHC version 8.10.2
    hls-8.6.4           Install haskell-language-server for GHC version 8.6.4
    hls-8.6.5           Install haskell-language-server for GHC version 8.6.5
    hls-8.8.2           Install haskell-language-server for GHC version 8.8.2
    hls-8.8.3           Install haskell-language-server for GHC version 8.8.3
    hls-8.8.4           Install haskell-language-server for GHC version 8.8.4
                        
    dev                 Install haskell-language-server with the default stack.yaml
                        
    icu-macos-fix       Fixes icu related problems in MacOS

Options:
    -s, --silent        Don't print anything.
    -q, --quiet         Print less (pass repeatedly for even less).
    -V, --verbose       Print more (pass repeatedly for even more).

Build completed in 0.07s
```

まずは最新のGHCバージョン(現時点は GHC version 8.8.4 でした)のビルドを行います。

```bash
$ stack ./install.hs hls
[...snip...]
Copied executables to /home/ein/.local/bin:
- haskell-language-server
- haskell-language-server-wrapper
# stack (for hls-8.8.4)
Build completed in 22m03s
```

次に、私が主に使用しているGHCバージョン(現時点は GHC version 8.6.5 です)のビルドを行います。

```bash
$ stack ./install.hs hls-8.6.5
[...snip...]
Copied executables to /home/ein/.local/bin:
- haskell-language-server
- haskell-language-server-wrapper
# stack (for hls-8.6.5)
Build completed in 20m46s
```

非力なマシンでは`-j`オプションで並列実行数を制限してください。

```bash
$ stack ./install.hs -j1 hls-8.6.5
$ stack ./install.hs -j1 hls-8.6.5
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

```lisp
;;;;;;;;
;; lsp-haskell
;;;;;;;;
(require 'lsp-haskell)
(add-hook 'haskell-mode-hook #'lsp)
```

### プロジェクトの作成

```bash
$ stack new --resolver=<resolver name> <project-name>
// example
$ stack new --resolver=lts-14.27 http-conduit-example
```

haskell-language-serverがプロジェクトのセットアップに失敗する場合はプロジェクトの設定ファイルを作成してみます。
設定に関する詳細は[haskell-language-serverのREADME](https://github.com/haskell/haskell-language-server#project-configuration)と[hie-biosのREADME](https://github.com/mpickering/hie-bios/blob/master/README.md#stack)の通りですが、以下に最小の設定を示します。

```yaml
cradle:
  stack:
```
