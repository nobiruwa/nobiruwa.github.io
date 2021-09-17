---
title: EmacsでのPython開発
author: nobiruwa
tags: Python, Emacs, LSP
---

## tl;dr

[lsp-mode](https://github.com/emacs-lsp/lsp-mode), [lsp-pyright](https://github.com/emacs-lsp/lsp-pyright)と[pyright](https://github.com/Microsoft/pyright)を用いることで、十分に快適な環境を得ることができました。

## lsp-mode + lsp-pyright + pyright の構築手順

### npmのインストール

pyrightはNode.jsパッケージです。よって、はじめに`npm`コマンドをインストールします。

```bash
$ sudo apt install npm
```

### Emacsパッケージのインストール

```emacs
M-x package-install
lsp-mode
lsp-pyright
```

lsp-modeの設定は[過去の記事](2019-04-07-emacs-as-cpp-ide.md)で書いた通りなので省略します。

```lisp
;;;;;;;;
;; lsp-pyright
;;;;;;;;
(require 'lsp-pyright)
(add-hook 'python-mode-hook #'lsp)
```

### pyrightのインストール

pyrightはEmacsにlsp-pyrightを入れた後、Pythonのソースコードを開いたときにインストールのミニプロンプトでインストールことができます。
選択肢は`pyright`しかありませんので迷うことはないでしょう。

```
Unable to find installed server supporting this file. The following servers could be installed automatically: pyright[Enter]
```

この手順により`pyright`コマンドは`~/.emacs.d/.cache/lsp/npm/pyright/bin/pyright`にインストールされます。

## virtualenvを使うプロジェクトの設定

私はしばしばvirtualenvを使います。virtualenvにしかないパッケージに対して補完を有効にするために、プロジェクトディレクトリに以下の内容を含む`pyrightconfig.json`を用意します。

```json
{
  "venvPath": "~/.venvs",
  "venv": "sandbox"
}
```

この場合、`~/.venvs/sandbox`ディレクトリのvirtualenv環境が使われます。

`pyrightconfig.json`の書式は[Pyright Configuration](https://github.com/microsoft/pyright/blob/main/docs/configuration.md)で確認できます。
