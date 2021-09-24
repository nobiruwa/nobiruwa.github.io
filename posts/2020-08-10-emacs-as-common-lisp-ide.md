---
title: EmacsでのCommon Lisp開発
author: nobiruwa
tags: Emacs, Common Lisp, Roswell
---

## tl;dr

```console
$ sudo apt-get -y install git build-essential automake libcurl4-openssl-dev
$ git clone -b release https://github.com/roswell/roswell.git $HOME/repo/roswell.git
$ cd $HOME/repo/roswell.git
$ sh bootstrap
$ ./configure --prefix=$HOME/opt/roswell
$ make
$ make install

// $HOME/opt/roswell/binをPATHに通した後:
$ ros setup
```

## 動機

QuickLispを使っていたのですが、cronで動作するスクリプトを作成するためにQuickLispのディレクトリをスクリプト内に埋め込んだり、イマイチ使いこなせている気がしなかったので、環境を管理するユーティリティがないかを探してRoswellに辿り着きました。

[Roswell](https://github.com/roswell/roswell)はCommon Lispの実装のインストーラー兼マネージャー兼ランチャー兼etc.です。

丁寧な[Wiki](https://github.com/roswell/roswell/wiki)があり、使い方を学ぶことができます。

## インストール

[Wiki](https://github.com/roswell/roswell/wiki/Installation#building-from-source)で十分に説明されています。が、私はユーザーディレクトリの`opt`ディレクトリにインストールしてPATHを通すスタイルが好きなので、実行するコマンドを少し変更しました。ソースコードリポジトリのローカルディレクトリ名も`<プロジェクト名>.<コマンド名>`(ex: `roswell.git`、`rxvt-unicode.svn`など)と独特の管理をしています。

```console
$ sudo apt-get -y install git build-essential automake libcurl4-openssl-dev
$ git clone -b release https://github.com/roswell/roswell.git $HOME/repo/roswell.git
$ cd $HOME/repo/roswell.git
$ sh bootstrap
$ ./configure --prefix=$HOME/opt/roswell
$ make
$ make install

// $HOME/opt/roswell/binをPATHに通した後:
$ ros setup
```

## Emacsのセットアップ

Wikiの[for Emacs](https://github.com/roswell/roswell/wiki/Initial-Recommended-Setup#for-emacs)の通りです。

```console
$ ros install slime
```

私はddskkを使って日本語入力をしており、SKKの変換ができるようキーバインドを変更しています。

```lisp
(let ((slime-helper (expand-file-name "~/.roswell/helper.el")))
  (when (file-exists-p slime-helper)
    (load slime-helper)

    ;; SLIMEとSKKとの衝突を回避する設定
    ;; 特定の場面で、SLIMEとSKKとの間でスペースキーのキーバインドが競合して、SKKでの変換ができなくなります。
    ;; https://lisphub.jp/common-lisp/cookbook/index.cgi?SLIME#H-33uy3rfpe0845
    (defun my-slime-space (n)
      (interactive "p")
      (if (and (boundp 'skk-henkan-mode) skk-henkan-mode)
          (skk-insert n)
        (slime-autodoc-space n)))
    (define-key slime-autodoc-mode-map " " 'my-slime-space)
    (setq inferior-lisp-program "ros -Q run")))
```

## サンプルスクリプト

Wikiの[Scripting with Roswell](https://github.com/roswell/roswell/wiki#scripting-with-roswell)の通りです。

```console
$ cd $HOME
$ ln -s .roswell/local-projects lispprojects
$ cd lispprojects
$ mkdir scripting-with-roswell
$ cd scripting-with-roswell
$ ros init fact

// fact.rosが生成されるので、次のように編集する:
$ cat fact.ros
#!/bin/sh
#|-*- mode:lisp -*-|#
#|
exec ros -Q -- $0 "$@"
|#

(defun fact (n)
  (if (zerop n)
      1
      (* n (fact (1- n)))))

(defun main (n &rest argv)
  (declare (ignore argv))
  (format t "~&Factorial ~D = ~D~%" n (fact (parse-integer n))))
$ ./fact.ros 10
Factorial 10 = 3628800
```
