---
title: libsecretをgitのcredential.helperとして使うには
author: nobiruwa
tags: Debian, Git, Gnome
---

## tl;dr

libsecret-1-devをインストール、`git-credential-libsecret`をコンパイルします。

```bash
$ sudo apt-get install libsecret-1-dev
$ sudo make --directory=/usr/share/doc/git/contrib/credential/libsecret
$ git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
```

## 経緯

GitHubに2段階認証を導入したことで、`git push`ではパスワードの代わりにprivate access tokenを入力するようになりました。
`git push`のたびに入力するのは面倒なので、省略する方法を調べると、GNOME環境ではlibsecretを使うとよいことが分かりました。
gitからlibsecretを使うには`git-credential-libsecret`が必要なのですが、Debianには該当するパッケージがなく、別途コンパイルする必要があることが分かりました。

## 参考

- [Creating a personal access token - GitHub Docs](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)
- [How to save username and password in Git?](https://stackoverflow.com/a/56898761)
- [What is the correct way to use git with gnome-keyring and http(s) repos?](https://askubuntu.com/questions/773455/what-is-the-correct-way-to-use-git-with-gnome-keyring-and-https-repos)
