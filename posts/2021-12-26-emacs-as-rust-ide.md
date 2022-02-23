---
title: EmacsでのRust開発(rust-analyzer)
author: nobiruwa
tags: Rust, Emacs, LSP
---

## tl;dr

[2021年4月3日の記事](2021-04-03-emacs-as-rust-ide.html)では[rls](https://github.com/rust-lang/rls)を使いましたが、[rust-analyzer](https://github.com/rust-analyzer/rust-analyzer)を使うように手順を変更しました。`rls`と`rust-analyzer`の両方が存在する環境では`rust-analyzer`が優先されるようで、[rust-analyzerのインストール](#rust-analyzerのインストール)以外は[2021年4月3日の記事](2021-04-03-emacs-as-rust-ide.html)の内容そのままです。

[rust-mode](https://github.com/rust-lang/rust-mode), [lsp-mode](https://github.com/emacs-lsp/lsp-mode), [cargo.el](https://github.com/kwrooijen/cargo.el)と[rust-analyzer](https://github.com/rust-analyzer/rust-analyzer)を用いることで、十分に快適な環境を得ることができました。

## rust-mode + lsp-mode + cargo.el + rust-analyzer の構築手順

開発のモードとしてrust-modeとlsp-modeとcargo.elのcargo-minor-modeを用い、バックエンドには`rust-analyzer`を用います。

### rust-analyzerのインストール

[公式の手順](https://rust-analyzer.github.io/manual.html#rust-analyzer-language-server-binary)に従って`rust-analyzer`をインストールします。

[rustup](https://rustup.rs/)を使って`rust-src`をインストールします。

```bash
$ rustup component add rust-src
```

次に`rust-analyzer`をインストールします。

```bash
$ mkdir -p ~/.local/bin
$ curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > ~/.local/bin/rust-analyzer
$ chmod +x ~/.local/bin/rust-analyzer
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

[過去の記事](2019-04-07-emacs-as-cpp-ide.html)でのlsp-mode, lsp-uiに加えて、lsp-mode, cargo-minor-mode, rust-modeのそれぞれに設定を行います。

#### lsp-mode

```lisp
;;;;;;;;
;; lsp-mode
;;;;;;;;
[...snip...]
;; rust
(setq lsp-rust-analyzer-proc-macro-enable t)
```

#### cargo-minor-mode

```lisp
;;;;;;;;
;; cargo-minor-mode
;;;;;;;;
(require 'rust-mode)

(add-hook 'rust-mode-hook 'cargo-minor-mode)
```

#### rust-mode

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
$ cargo install cargo-edit
$ cargo install cargo-feature
```

ちなみに、サブコマンドの実体は`~/.cargo/bin`ディレクトリにあります。`cargo-add`, `cargo-feature`といったようにサブコマンドごとの実行ファイルが追加されます。
