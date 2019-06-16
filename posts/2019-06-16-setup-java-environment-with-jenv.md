---
title: jEnvを用いたJava環境のセットアップ
author: nobiruwa
tags: Java
---

## tl;dr

``` bash
$ git clone https://github.com/gcuisinier/jenv.git ~/.jenv
$ cat << EOF >> ~/.bash_profile
# jEnv configuration
JENVBIN=$HOME/.jenv/bin
if [ -d $JENVBIN ] ; then
    export PATH="$JENVBIN:$PATH"
    eval "$(jenv init -)"
fi
EOF
```

## 動機

Java 8を使うことが多いのですが、Debian Unstableではデフォルトが11, 12とどんどんあがっていきます。そこで、Rubyのvenv、Pythonのvirtualenvのように一般ユーザーがJavaのバージョンを容易に変更できるようにしたいと思いました。

## jEnvの入手

[jEnv](https://www.jenv.be/)の公式にある通りです。
まずは`~/.jenv`を用意します。

``` bash
$ git clone https://github.com/gcuisinier/jenv.git ~/.jenv
```

`~/.bash_profile`にて、環境変数`PATH`と`JAVA_HOME`を設定します。

``` bash
# jEnv configuration
JENVBIN=$HOME/.jenv/bin
if [ -d $JENVBIN ] ; then
    export PATH="$JENVBIN:$PATH"
    eval "$(jenv init -)"
fi
```

## JDKの入手

OpenJDKのバイナリは[GitHub](https://github.com/ojdkbuild/ojdkbuild/releases)で配布しています。

好みのバージョンのzipファイルをダウンロードし、`~/opt`などに展開してください。

## JDKの登録

jEnvにJDKを登録します。

``` bash
$ jenv add <JDKのパス>
```

登録されたJDKは下記のコマンドで確認できます。

``` bash
$ jenv versions
```

## グローバルのJava環境

グローバルのJava環境を指定します。

``` bash
$ jenv global <java versionsで列挙されるバージョン文字列>
```

## ローカルのJava環境

ローカルのJava環境を設定するには、以下のコマンドを実行します。

``` bash
$ cd <設定したいディレクトリ>
$ jenv local <java versionsで列挙されるバージョン文字列>
```

`java local`を実行したディレクトリには`.java-version`ファイルが生成されます。
`java local`を実行したディレクトリとその子孫ディレクトリで実行する`java`/`javac`コマンドは、`.java-version`で指定されたJava環境のものが使用されます。

## プラグインの有効化

いくつかのプラグインを有効にします。たとえば、`export`プラグインはグローバルのJava環境を`JAVA_HOME`に設定します。

``` bash
$ jenv enable-plugin export
$ jenv enable-plugin maven
$ jenv enable-plugin gradle
```

ログインシェルがdashで、`~/.bash_profile`の内容を`~/.profile`に記述した場合は`"$(jenv init -)"`が働かず便利なjenv関数を定義しません。
そのため、サブコマンドに`sh-`プリフィックスを付けて実行してください。

``` bash
$ jenv sh-enable-plugin export
$ jenv sh-enable-plugin maven
$ jenv sh-enable-plugin gradle
```
