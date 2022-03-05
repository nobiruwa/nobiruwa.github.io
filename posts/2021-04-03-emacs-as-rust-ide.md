---
title: EmacsでのRust開発
author: nobiruwa
tags: Rust, Emacs, LSP
---

## tl;dr

[rust-mode](https://github.com/rust-lang/rust-mode), [lsp-mode](https://github.com/emacs-lsp/lsp-mode), [cargo.el](https://github.com/kwrooijen/cargo.el)と[rls](https://github.com/rust-lang/rls)を用いることで、十分に快適な環境を得ることができました。

## rust-mode + lsp-mode + cargo.el + rls の構築手順

開発のモードとしてrust-modeとlsp-modeとcargo.elのcargo-minor-modeを用い、バックエンドには`rls`を用います。


### rlsのインストール

[公式の手順](https://github.com/rust-lang/rls#setup)に従って`rls`をインストールします。

```console
$ rustup update
$ rustup component add rls rust-analysis rust-src
```

### Emacsパッケージのインストール

```emacs
M-x package-install
cargo
lsp-mode
lsp-ui
rust-mode
```

### Emacsパッケージの設定

lsp-modeとlsp-uiの設定は[過去の記事](2019-04-07-emacs-as-cpp-ide.html)で書いた通りなので省略します。

```lisp
;;;;;;;;
;; cargo-minor-mode
;;;;;;;;
(require 'rust-mode)

(add-hook 'rust-mode-hook 'cargo-minor-mode)
```

```lisp
;;;;;;;;
;; rust-mode
;;;;;;;;
(require 'rust-mode)

(add-hook 'rust-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)
            (lsp)))

;; Formatting is bound to C-c C-f.
;; The folowing enables automatic formatting on save.
(setq rust-format-on-save t)
```

## cargo-edit, cargo-featureのインストール

[cargo-edit](https://github.com/killercup/cargo-edit)は`cargo add/rm/upgrade/set-version`サブコマンドを追加します。また、[cargo-feature](https://github.com/Riey/cargo-feature)は`cargo feature`サブコマンドを追加します。

`cargo add`と`cargo feature`を使うと、`Cargo.toml`の`[dependencies]`セクションと`[dev-dependencies]`セクションを記述するかわりに、コマンドラインから編集できるようになります。私には合っていると思い導入することにします。

```bash
$ sudo apt install libssl-dev
$ cargo install cargo-edit
$ cargo install cargo-feature
```

ちなみに、サブコマンドの実体は`~/.cargo/bin`ディレクトリにあります。`cargo-add`, `cargo-feature`といったようにサブコマンドごとの実行ファイルが追加されます。
