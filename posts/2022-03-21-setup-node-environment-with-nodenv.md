---
title: nodenvを用いたNode.js環境のセットアップ
author: nobiruwa
tags: JavaScript, Node.js
---

## tl;dr

``` console
$ git clone https://github.com/nodenv/nodenv.git $HOME/.nodenv
$ NODENV_HOME="$HOME/.nodenv"
$ NODENV_BIN="$NODENV_HOME/bin"
$ PATH="$NODENV_BIN:$PATH"
$ eval "$(nodenv init -)"
$ mkdir -p $(nodenv root)/plugins
$ git clone https://github.com/nodenv/node-build.git "$(nodenv root)"/plugins/node-build
$ cat << EOF >> ~/.profile
NODENV_HOME="$HOME/.nodenv"
NODENV_BIN="$NODENV_HOME/bin"
if [ -d "$NODENV_BIN" ]; then
    export PATH="$NODENV_BIN:$PATH"
    # rehash after init, because my login shell is dash.
    eval "$(nodenv init --no-rehash -)"
    (nodenv rehash &) 2> /dev/null
fi
EOF
```

## 動機

[jEnvを用いたJava環境のセットアップ](2019-06-16-setup-java-environment-with-jenv.html)と同じく、プログラミング言語の開発環境を[rbenv/rbenv](https://github.com/rbenv/rbenv)のフォークである[nodenv/nodenv](https://github.com/nodenv/nodenv)によって構築したいと思いました。

## セットアップ

### nodenvのチェックアウト

`nodenv`リポジトリをチェックアウトします。

場所は公式に合わせて`~/.nodenv`とします。

さらに、`node-build`リポジトリをnodenvのプラグインとしてチェックアウトします。

```console
$ git clone https://github.com/nodenv/nodenv.git $HOME/.nodenv
# 一時的に`$HOME/.nodenv/bin`を`$PATH`に追加してnode-buildをインストールする
$ NODENV_HOME="$HOME/.nodenv"
$ NODENV_BIN="$NODENV_HOME/bin"
$ PATH="$NODENV_BIN:$PATH"
$ eval "$(nodenv init -)"
$ mkdir -p $(nodenv root)/plugins
$ git clone https://github.com/nodenv/node-build.git "$(nodenv root)"/plugins/node-build
```

### `~/.profile`の記述

`~/.profile`にて、環境変数`PATH`を設定します。

```bash
NODENV_HOME="$HOME/.nodenv"
NODENV_BIN="$NODENV_HOME/bin"
if [ -d "$NODENV_BIN" ]; then
    export PATH="$NODENV_BIN:$PATH"
    # rehash after init, because my login shell is dash.
    eval "$(nodenv init --no-rehash -)"
    (nodenv rehash &) 2> /dev/null
fi
```

## Node.jsのインストール

`nodenv install`コマンドで`~/.nodenv/versions`配下に特定のバージョンのNode.jsをインストールします。

```console
# インストール可能なバージョンを列挙する
$ nodenv install --list
# 16.14.2をインストールする場合
$ nodenv install 16.14.2
```

登録されたNode.jsは下記のコマンドで確認できます。

```console
$ nodenv versions
```

なお、`npm i -g`コマンドは`~/.nodenv/versions/<nodenv versionsで列挙されるバージョン文字列>`ディレクトリ配下にインストールされます。

これだけではコマンドを使用可能になりませんので、`nodenv rehash`コマンドを実行してください。

すべてのバージョンの`bin`ディレクトリを更新するので少々時間がかかります。

## グローバルのNode.js環境

グローバルのNode.js環境を指定します。

```console
$ nodenv global <nodenv versionsで列挙されるバージョン文字列>
```

## ローカルのNode.js環境

ローカルのNode.js環境を設定するには、以下のコマンドを実行します。

```console
$ cd <設定したいディレクトリ>
$ nodenv local <nodenv versionsで列挙されるバージョン文字列>
```

`nodenv local`を実行したディレクトリには`.node-version`ファイルが生成されます。

`nodenv local`を実行したディレクトリとその子孫ディレクトリで実行する`node`/`npm`コマンド等は、`.node-version`で指定されたNode.js環境のものが使用されます。
