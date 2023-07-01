---
title: goenvを用いたGo環境のセットアップ
author: nobiruwa
tags: Go
---

## tl;dr

``` console
$ git clone https://github.com/syndbg/goenv.git $HOME/.goenv
$ cat << EOF >> ~/.profile
GOENV_HOME="$HOME/.goenv"
GOENV_BIN="$GOENV_HOME/bin"
if [ -d "$GOENV_BIN" ]; then
    export PATH="$GOENV_BIN:$PATH"
    eval "$(goenv init --no-rehash -)"
    (goenv rehash &) 2> /dev/null
fi
EOF
```

## 動機

[ory/hydra](https://github.com/ory/hydra)を試すためにGo言語の環境が必要でした。Goを[goenv/goenv](https://github.com/syndbg/goenv)によって管理したいと思いました。

## セットアップ

### goenvのチェックアウト

`goenv`リポジトリをチェックアウトします。

場所は公式に合わせて`~/.goenv`とします。

```console
$ git clone https://github.com/syndbg/goenv.git $HOME/.goenv
```

### `~/.profile`の記述

`~/.profile`にて、環境変数`PATH`を設定します。

```bash
GOENV_HOME="$HOME/.goenv"
GOENV_BIN="$GOENV_HOME/bin"
if [ -d "$GOENV_BIN" ]; then
    export PATH="$GOENV_BIN:$PATH"
    eval "$(goenv init --no-rehash -)"
    (goenv rehash &) 2> /dev/null
fi
```

## Goのインストール

`goenv install`コマンドで`~/.goenv/versions`配下に特定のバージョンのGoをインストールします。

```console
# インストール可能なバージョンを列挙する
$ goenv install --list
# 1.20.5をインストールする場合
$ goenv install 1.20.5
```

登録されたGoは下記のコマンドで確認できます。

```console
$ goenv versions
```

## グローバルのGo環境

グローバルのGo環境を指定します。

```console
$ goenv global <goenv versionsで列挙されるバージョン文字列>
```

## ローカルのGo環境

ローカルのGo環境を設定するには、以下のコマンドを実行します。

```console
$ cd <設定したいディレクトリ>
$ goenv local <goenv versionsで列挙されるバージョン文字列>
```

`goenv local`を実行したディレクトリには`.go-version`ファイルが生成されます。

`goenv local`を実行したディレクトリとその子孫ディレクトリで実行する`go`/`gofmt`コマンド等は、`.go-version`で指定されたGo環境のものが使用されます。
