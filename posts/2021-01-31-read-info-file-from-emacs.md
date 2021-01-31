---
title: Emacsでinfoファイルを読む
author: nobiruwa
tags: Emacs, Info
---

## tl;dr

infoコマンドにuniversal-argumentを渡します。

```
C-u M-x info
```

ヘルプから呼び出すこともできます。infoを呼び出すヘルプコマンドは`i`ですので、以下のようになります。

```
C-u C-h i
C-u F1 i
```

## 経緯

`/usr/share/info`に登録されていないinfoファイルを読みたいと思ったとき、`info -f MANUAL`に相当するEmacsの操作が分からなかったので調べました。

## 参考

- [info command in Linux with Examples - GeeksForGeeks](https://www.geeksforgeeks.org/info-command-in-linux-with-examples/)
- [EmacsWiki: Info Mode](https://www.emacswiki.org/emacs/InfoMode)
