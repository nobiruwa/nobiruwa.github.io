---
title: jEnvを用いたJava環境のセットアップ
author: nobiruwa
tags: Java
---

## tl;dr

``` console
$ git clone https://github.com/gcuisinier/jenv.git ~/.jenv
$ cat << EOF >> ~/.profile
JENV_HOME="$HOME/.jenv"
JENV_BIN="$JENV_HOME/bin"
if [ -d "$JENV_BIN" ]; then
    export PATH="$JENV_BIN:$PATH"
    # rehash after init, because my login shell is dash.
    eval "$(jenv init --no-rehash -)"
    (jenv rehash &) 2> /dev/null
fi
EOF
```

## 動機

Java 8を使うことが多いのですが、Debian Unstableではデフォルトが11, 12とどんどんあがっていきます。そこで、Rubyの[rbenv/rbenv](https://github.com/rbenv/rbenv)のように一般ユーザーがJavaのバージョンを容易に変更できるようにしたいと思いました。

## セットアップ

### おおまかな手順

rbenvのフォークをセットアップする際は、おおむね以下の手順に従います。

ログインシェルにdashを使っているため公式では`eval $(jenv init -)`を実行しているところ、
`eval $(xxenv init --no-rehash -)`と`xxenv rehash`に分けています。

1. `xxenv`リポジトリを`~/.xxenv`にチェックアウトする。
2. `xxenv-build`リポジトリを`git clone`で`~/.xxenv/plugins/xxenv-build`にチェックアウトする。
3. `~/.profile`(Debian系の場合)に以下の記述を追加する。
   - `export PATH=$HOME/.xxenv/bin:$PATH`
   - `eval $(xxenv init --no-rehash -)`
   - `eval (xxenv rehash &) 2> /dev/null`

jenvのセットアップは以下の通りです。

### jEnvのチェックアウト

[jEnv](https://www.jenv.be/)の公式にある通りです。

`jenv`リポジトリをチェックアウトします。

場所は公式に合わせて`~/.jenv`とします。

```console
$ git clone https://github.com/gcuisinier/jenv.git ~/.jenv
```

### `~/.profile`の記述

`~/.profile`にて、環境変数`PATH`を設定します。

```bash
JENV_HOME="$HOME/.jenv"
JENV_BIN="$JENV_HOME/bin"
if [ -d "$JENV_BIN" ]; then
    export PATH="$JENV_BIN:$PATH"
    # rehash after init, because my login shell is dash.
    eval "$(jenv init --no-rehash -)"
    (jenv rehash &) 2> /dev/null
fi
```

## JDKの入手

OpenJDKのバイナリは[GitHub](https://github.com/ojdkbuild/ojdkbuild/releases)で配布しています。

好みのバージョンのzipファイルをダウンロードし、`~/opt`などに展開してください。

## JDKの登録

jEnvにJDKを登録します。

```console
$ jenv add <JDKのパス>
```

登録されたJDKは下記のコマンドで確認できます。

``` console
$ jenv versions
```

## グローバルのJava環境

グローバルのJava環境を指定します。

```console
$ jenv global <jenv versionsで列挙されるバージョン文字列>
```

## ローカルのJava環境

ローカルのJava環境を設定するには、以下のコマンドを実行します。

```console
$ cd <設定したいディレクトリ>
$ jenv local <jenv versionsで列挙されるバージョン文字列>
```

`jenv local`を実行したディレクトリには`.java-version`ファイルが生成されます。

`jenv local`を実行したディレクトリとその子孫ディレクトリで実行する`java`/`javac`コマンドは、`.java-version`で指定されたJava環境のものが使用されます。

## プラグインの有効化

いくつかのプラグインを有効にします。たとえば、`export`プラグインはグローバルのJava環境を`JAVA_HOME`に設定します。

```console
$ jenv enable-plugin export
$ jenv enable-plugin maven
$ jenv enable-plugin gradle
```

ログインシェルがdashである場合は`"$(jenv init -)"`が働かず便利なjenv関数を定義しません。

そのため、サブコマンドに`sh-`プリフィックスを付けて実行してください。

```console
$ jenv sh-enable-plugin export
$ jenv sh-enable-plugin maven
$ jenv sh-enable-plugin gradle
```
