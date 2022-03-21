---
title: pyenvを用いたPython環境のセットアップ
author: nobiruwa
tags: Python
---

## tl;dr

``` console
$ git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
$ PYENV_HOME="$HOME/.pyenv"
$ PYENV_BIN="$PYENV_HOME/bin"
$ PATH="$PYENV_BIN:$PATH"
$ eval "$(pyenv init --path)"
$ eval "$(pyenv init -)"
$ mkdir -p $(pyenv root)/plugins
$ git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
$ cat << EOF >> ~/.profile
PYENV_HOME="$HOME/.pyenv"
PYENV_BIN="$PYENV_HOME/bin"
if [ -d "$PYENV_BIN" ]; then
    export PATH="$PYENV_BIN:$PATH"
    # rehash after init, because my login shell is dash.
    eval "$(pyenv init --path)"
    eval "$(pyenv init --no-rehash -)"
    (pyenv rehash &) 2> /dev/null
fi
EOF
```

## 動機

[jEnvを用いたJava環境のセットアップ](2019-06-16-setup-java-environment-with-jenv.html)、[nodenvを用いたNode.js環境のセットアップ](2022-03-21-setup-node-environment-with-nodenv.html)と同じく、プログラミング言語の開発環境を[rbenv/rbenv](https://github.com/rbenv/rbenv)のフォークである[pyenv/pyenv](https://github.com/pyenv/pyenv)によって構築したいと思いました。

## セットアップ

### pyenvのチェックアウト

`pyenv`リポジトリをチェックアウトします。

場所は公式に合わせて`~/.pyenv`とします。

さらに、`pyenv-virtualenv`リポジトリをpyenvのプラグインとしてチェックアウトします。

```console
$ git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
# 一時的に`$HOME/.pyenv/bin`を`$PATH`に追加してpyenv-virtualenvをインストールする
$ PYENV_HOME="$HOME/.pyenv"
$ PYENV_BIN="$PYENV_HOME/bin"
$ PATH="$PYENV_BIN:$PATH"
$ eval "$(pyenv init --path)"
$ eval "$(pyenv init -)"
$ mkdir -p $(pyenv root)/plugins
$ git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
```

### `~/.profile`の記述

`~/.profile`にて、環境変数`PATH`を設定します。

```bash
PYENV_HOME="$HOME/.pyenv"
PYENV_BIN="$PYENV_HOME/bin"
if [ -d "$PYENV_BIN" ]; then
    export PATH="$PYENV_BIN:$PATH"
    # rehash after init, because my login shell is dash.
    eval "$(pyenv init --path)"
    eval "$(pyenv init --no-rehash -)"
    (pyenv rehash &) 2> /dev/null
fi
```

## Pythonのインストール

`pyenv install`コマンドで`~/.pyenv/versions`配下に特定のバージョンのPythonをインストールします。

```console
# インストール可能なバージョンを列挙する
$ pyenv install --list
# 3.10.3をインストールする場合
$ pyenv install 3.10.3
```

登録されたPythonは下記のコマンドで確認できます。

```console
$ pyenv versions
```

なお、`pip install`コマンドは`~/.pyenv/versions/<pyenv versionsで列挙されるバージョン文字列>`ディレクトリ配下にインストールされます。

これだけではコマンドを使用可能になりませんので、`pyenv rehash`コマンドを実行してください。

すべてのバージョンの`bin`ディレクトリを更新するので少々時間がかかります。

## グローバルのPython環境

グローバルのPython環境を指定します。

```console
$ pyenv global <pyenv versionsで列挙されるバージョン文字列>
```

## ローカルのPython環境

ローカルのPython環境を設定するには、以下のコマンドを実行します。

```console
$ cd <設定したいディレクトリ>
$ pyenv local <pyenv versionsで列挙されるバージョン文字列>
```

`pyenv local`を実行したディレクトリには`.python-version`ファイルが生成されます。

`pyenv local`を実行したディレクトリとその子孫ディレクトリで実行する`python`/`pip`/`virtualenv`コマンド等は、`.python-version`で指定されたPython環境のものが使用されます。
