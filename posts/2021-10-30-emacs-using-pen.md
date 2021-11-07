---
title: Pen (pen.el) のセットアップ
author: nobiruwa
tags: Emacs, AI, AIx, OpenAI, pen.el
---

# インストール手順

この手順は[Pen Tutorial](https://mullikine.github.io/posts/pen-tutorial/)に従って、Docker上でEmacs + Pen (pen.el) を試した際の記録です。

## `pen.el`と`prompts`リポジトリのクローン

```bash
$ cd ~/repo
$ git clone "https://github.com/semiosis/pen.el" pen.el.git
$ git clone "https://github.com/semiosis/prompts" prompts.git
```

## `AIx` APIキーの取得

`AIx`の`GPT-J 6B by EleutherAI`エンジンを利用します。

<https://apps.aixsolutionsgroup.com/>にサインアップ、ログインします。メニューの`API Keys`からAPIキーを取得します。

## `OpenAI` APIキーの取得

`OpenAI`の`GPT-3`言語モデルを利用します。

<https://beta.openai.com/>で`JOIN THE WAITLIST`ボタンからフォーム画面に遷移し、必要な情報を入力します。

- `Which product are you interested in?`
  - `GPT-3 (language models)`ラジオボタンを選択します。
- `Are you primarily looking to:`
  - 今回の目的は`General exploration of capabilities`です。
- 他の項目も適当に入力します。

サインアップではなくあくまでwaitlistであるということでしばらく待ちます。

承認された後は<https://beta.openai.com/account/api-keys>からAPIキーを取得できます。

## Penのセットアップ

```bash
$ mkdir -p ~/.pen
$ echo "sk-<openai key here>" > ~/.pen/openai_api_key   # https://openai.com/
$ echo "<aix key here>" > ~/.pen/aix_api_key            # https://aixsolutionsgroup.com/
```

```bash
$ cat ~/.bash_env
...
# Pen configuration
PEN_AIX_KEY="$HOME/.pen/aix_api_key"
PEN_OPENAI_KEY="$HOME/.pen/openai_api_key"
PEN_REPO="$HOME/repo/pen.el.git"
if [ -f "$PEN_AIX_KEY" ] && [ -f "$PEN_OPENAI_KEY" ] && [ -d "$PEN_REPO" ] ; then
    export PATH="$PATH:$PEN_REPO/scripts"
    # Add this to prevent C-s from freezing the terminal
    stty stop undef 2>/dev/null
    stty start undef 2>/dev/null
fi
...
```

## Penの起動

`pen`コマンドを起動します。初回起動時にはDockerイメージをプルします。

```bash
$ pen
```

## Penを試す

[Acolyte minor mode](https://mullikine.github.io/posts/pen-tutorial/#acolyte-mode-key-bindings-for-emacs-noobs)を使って文章の補完を行えます。

Bindings                Description
----------------------- -------------------------------------------------------------------------------
Alt-a                   Change AIx API key
Alt-o                   Change OpenAI API key
Alt-p                   Open the prompts directory in dired
Alt-t                   Start writing in an empty file
Alt-s                   Save file
Alt-r                   Running a prompt function like this will not insert text or replace it.
Alt-TAB                 This completes the current line.
Alt-l (little L)        Multiline (long) completion.
Alt-g                   This reloads the prompt functions.
Alt-m                   Right click menu
Select text then Alt-f  This filters the text through a prompt function specifically designed for this.
Spacebar                When text is selected, will run with that text as first argument.
Alt-1                   Complete 1 word
Alt-2                   Complete 5 words
Alt-3                   Complete line
Alt-4                   Complete long (use Alt-l though, as you can see the multilines)
Alt-u Alt-2             Complete 5 words, but get a new completion (updates the cache)

