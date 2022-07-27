---
title: Emacs 29を使ってみる
author: nobiruwa
tags: Emacs
---

Debian sidのEmacsパッケージのバージョンは現在27.1です。

Emacs 28から導入されるNative Compilationを体感してみたいと思い、GNU Emacsの最新のソースをコンパイルしてみました。

使っているELPAパッケージが読み込み時や使用時にエラーを起こしてしまい、今回は1, 2回試して満足してしまいました。

ここではコンパイル手順の記録に留めます。

```
$ git clone -b master git://git.sv.gnu.org/emacs.git emacs.git
$ cd emacs.git/
$ sudo apt install autoconf libjansson-dev libxpm-dev libgif-dev gnutls-dev libgccjit-11-dev libgtk-3-dev texinfo
$ ./autogen.sh
$ ./configure CFLAGS=-no-pie --prefix=/usr/local/xstow/emacs-29.0.50 --with-modules --with-native-compilation
$ make
$ sudo make install
$ sudo apt install xstow
$ cd /usr/local/xstow
$ sudo xstow emacs-29.0.50
```

