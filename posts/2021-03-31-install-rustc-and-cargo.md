---
title: rustupを使ったRust開発環境のインストール
author: nobiruwa
tags: Rust
---

## 切っ掛け

Raspberry Piへも簡単に導入できそうな、新しい言語は何かと考えてRustを試してみようと考えました。

## 用語の勉強

[Glossary](https://doc.rust-lang.org/cargo/appendix/glossary.html) をほんの少し読みました。

- `crate`
  - Rustではライブラリあるいは実行可能なプログラムを`crate[s]`と呼びます。
- `cargo`
  - Rustのパッケージマネージャであり、ビルドシステムです。リポジトリとして[crates.io](https://crates.io/)を使います。
  - プロジェクトのマニフェストは`Cargo.toml`です。
  - プロジェクトが依存するパッケージのバージョンは`Cargo.lock`で管理されます。
- `rustc`
  - Rustのコンパイラです。
- `rustup`
  - Rustのツールチェインのインストーラーです。`cargo`や`rustc`をまとめてインストールできます。

## インストール手順

[rustup.rs](https://rustup.rs/) の手順に従います。

```console
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
info: downloading installer
Warning: Not enforcing strong cipher suites for TLS, this is potentially less secure
Warning: Not enforcing TLS v1.2, this is potentially less secure

Welcome to Rust!

This will download and install the official compiler for the Rust
programming language, and its package manager, Cargo.

Rustup metadata and toolchains will be installed into the Rustup
home directory, located at:

  /home/ein/.rustup

This can be modified with the RUSTUP_HOME environment variable.

The Cargo home directory located at:

  /home/ein/.cargo

This can be modified with the CARGO_HOME environment variable.

The cargo, rustc, rustup and other commands will be added to
Cargo's bin directory, located at:

  /home/ein/.cargo/bin

This path will then be added to your PATH environment variable by
modifying the profile files located at:

  /home/ein/.profile
  /home/ein/.bashrc
  /home/ein/.zshenv

You can uninstall at any time with rustup self uninstall and
these changes will be reverted.

Current installation options:


   default host triple: x86_64-unknown-linux-gnu
     default toolchain: stable (default)
               profile: default
  modify PATH variable: yes

1) Proceed with installation (default)
2) Customize installation
3) Cancel installation
>1

info: profile set to 'default'
info: default host triple is x86_64-unknown-linux-gnu
info: syncing channel updates for 'stable-x86_64-unknown-linux-gnu'
info: latest update on 2021-03-25, rust version 1.51.0 (2fd73fabe 2021-03-23)
info: downloading component 'cargo'
info: downloading component 'clippy'
info: downloading component 'rust-docs'
info: downloading component 'rust-std'
info: downloading component 'rustc'
 50.4 MiB /  50.4 MiB (100 %)  45.9 MiB/s in  1s ETA:  0s
info: downloading component 'rustfmt'
info: installing component 'cargo'
info: using up to 500.0 MiB of RAM to unpack components
info: installing component 'clippy'
info: installing component 'rust-docs'
 14.9 MiB /  14.9 MiB (100 %)   4.9 MiB/s in  3s ETA:  0s
info: installing component 'rust-std'
 24.9 MiB /  24.9 MiB (100 %)  10.4 MiB/s in  3s ETA:  0s
info: installing component 'rustc'
 50.4 MiB /  50.4 MiB (100 %)  12.2 MiB/s in  4s ETA:  0s
info: installing component 'rustfmt'
info: default toolchain set to 'stable-x86_64-unknown-linux-gnu'

  stable-x86_64-unknown-linux-gnu installed - rustc 1.51.0 (2fd73fabe 2021-03-23)


Rust is installed now. Great!

To get started you need Cargo's bin directory ($HOME/.cargo/bin) in your PATH
environment variable. Next time you log in this will be done
automatically.

To configure your current shell, run:
source $HOME/.cargo/env
```

`~/.profile`にて、環境変数`PATH`を設定します。

```bash
CARGO_HOME="$HOME/.cargo"
CARGO_BIN="$CARGO_HOME/bin"
if [ -d "$CARGO_BIN" ]; then
    export PATH="$CARGO_BIN:$PATH"
fi
```
