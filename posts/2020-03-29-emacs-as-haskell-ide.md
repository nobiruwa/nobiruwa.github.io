---
title: EmacsでのHaskell開発
author: nobiruwa
tags: Haskell, Emacs, LSP
---

## tl;dr

[lsp-haskell](https://github.com/emacs-lsp/lsp-haskell)と[haskell-ide-engine](https://github.com/haskell/haskell-ide-engine)を用いることで、十分に快適な環境を得ることができました。

## 切っ掛け

元々は[intero](https://github.com/chrisdone/intero)を愛用していましたが、lts-14.20(GHC 8.6.5)を使い始めた頃から、関数によっては補完が表示されなくなりなした。GitHubを見ると"The intero project has reached the end of its life cycle."とあり、代替のなかからLSPと簡単に統合が可能なhaskell-ide-engineを用いることにしました。

## lsp-haskell + haskell-ide-engine の構築手順

開発のモードとして[lsp-mode](https://github.com/emacs-lsp/lsp-mode)を用い、バックエンドにはhaskell-ide-engineを用います。そのために、lsp-haskellをインストールします。

### haskell-ide-engine

#### haskell-ide-engineのインストール

lsp-haskellには、interoのようなバックエンドの自動インストールは実装されていないので、ソースコードからインストールします。インストール手順の詳細は[haskell-ide-engineのREADME](https://github.com/haskell/haskell-ide-engine#installation-from-source)にあります。

私はGHC 8.6.5を使用しており、ソースコードのリポジトリを`~/repo/<project-name>.git`というディレクトリ体系で管理していることから、以下のコマンドで`hie`(または`hie-8.6.5`)と`hie-wrapper`を`~/.local/bin`ディレクトリにインストールしました。

```bash
$ mkdir -p ~/repo
$ cd ~/repo
$ git clone https://github.com/haskell/haskell-ide-engine.git --recurse-submodules haskell-ide-engine.git
$ cd haskell-ide-engine.git
$ stack ./install.hs hie # GHC 8.6.5がデフォルトのバージョンである場合
$ stack ./install.hs hie-8.6.5 # GHC 8.6.5がデフォルトのバージョンでない場合
$ stack ./install.hs -j1 hie-8.8.3 # 非力なPCではビルド時のジョブ数を制限する
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

HIEがプロジェクトのセットアップに失敗する場合はプロジェクトの設定ファイルを作成してみます。
設定に関する詳細は[README](https://github.com/haskell/haskell-ide-engine#project-configuration)の通りですが、以下に最小の設定を示します。

```yaml
cradle:
  stack:
```
