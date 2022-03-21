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

```console
$ sudo apt install npm
```

#### 追記

[nodenv/nodenv](https://github.com/nodenv/nodenv)を使って`npm`コマンドを準備するように[しました](2022-03-21-setup-node-environment-with-nodenv.html)。

また、Pythonも[pyenv/pyenv](https://github.com/pyenv/pyenv)を使うように[しました](2022-03-21-setup-python-environment-with-pyenv.html)。

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

私はしばしばvirtualenvを使います。virtualenvにしかないパッケージに対して補完を有効にするためには`pyrightconfig.json`を用意してvirtualenv環境のパスをpyrightに伝える必要があります(`pyright`コマンドの起動オプションで伝えることもできます)。

`pyrightconfig.json`の書式は[Pyright Configuration](https://github.com/microsoft/pyright/blob/main/docs/configuration.md)で確認できます。

最低限必要な設定オプジョンは`venvPath`と`venv`の2つです。

`pyrightconfig.json`を含むプロジェクトのリソースを複数のユーザーで共用したいので、`venvPath`には`~/.venvs`を指定したいです。

しかしながら、[pyrightの設計思想](https://github.com/microsoft/pyright/issues/1340#issuecomment-756243657)から`~`や環境変数は展開されません。

LSPクライアント、つまりEmacsで展開する必要があります。

そこで、`eval`を使って動的にローカル変数の値を設定できる仕組みを使って、`venvPath`オプションを設定することにします。

ホームディレクトリかPythonプロジェクトのワークスペースのルートディレクトリに`.dir-locals.el`を用意し`venvPath`オプションに対応する`lsp-pyright-venv-path`変数を設定します。

```lisp
((python-mode . ((eval . (setq-local lsp-pyright-venv-path (expand-file-name "~/.venvs"))))))
```

これだけだと、Pythonのソースコードを開くたびに`lsp-pyright-venv-path`変数が安全でないローカル変数であるとして警告が表示されます。

```
The local variables list in /home/ein/pythonprojects/
contains values that may not be safe (*).

Do you want to apply it?  You can type
y  -- to apply the local variables list.
n  -- to ignore the local variables list.
!  -- to apply the local variables list, and permanently mark these
      values (*) as safe (in the future, they will be set automatically.)

  * eval : (setq-local lsp-pyright-venv-path (expand-file-name "~/.venvs"))
```

`!`を選択して安全なローカル変数であると永続的にマークします。

すると、Emacsの`init.el`(あるいは`custom-file`変数が示すファイル)の`custom-set-variables`関数の呼び出しパラメータに`safe-local-variable-values`が追加されます。

```lisp
(custom-set-variables
 ...
 '(safe-local-variable-values
   '((eval setq-local lsp-pyright-venv-path
           (expand-file-name "~/.venvs")))))
```

この、`custom-set-variables`関数の呼び出しを`init.el`にベタ書きするか、`custom-file`変数が示すファイルに記載しておき`init.el`からロードするようにしておけば、警告が表示されなくなります。

各プロジェクトの`pyrightconfig.json`では、`~/.venvs`ディレクトリ配下にあるサブディレクトリ名を指定します。

`~/.venvs/sandbox`ディレクトリのvirtualenv環境を使う場合は以下の記載とします。

```json
{
  "venv": "sandbox"
}
```
