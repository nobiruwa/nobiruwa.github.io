---
title: Emacs 26.3 でのフォント設定
author: nobiruwa
tags: Emacs, Font
---

## tl;dr

以下の設定となりました。

- 日本語とASCII文字には[VL Gothic](http://vlgothic.dicey.org/)を使います。
- それ以外には[Noto Sans](https://fonts.google.com/specimen/Noto+Sans)を使います。
- ベンガル語の文字([Bengali alphabet (Wikipedia)](https://en.wikipedia.org/wiki/Bengali_alphabet))には[Free Sans](https://en.wikipedia.org/wiki/GNU_FreeFont)を使います。
  - Noto Sansだと[libm17nのlibotf](https://www.nongnu.org/m17n/)がクラッシュするため、その回避のためです。

```lisp
;;;
;; customize font
;;;
;; Ref: https://www.shimmy1996.com/en/posts/2018-06-24-fun-with-fonts-in-emacs/
;; Ref: https://qiita.com/melito/items/238bdf72237290bc6e42
;; Ref: http://misohena.jp/blog/2017-09-26-symbol-font-settings-for-emacs25.html
;; Ref: https://www.reddit.com/r/emacs/comments/ggd90c/color_emoji_in_emacs_27/
(defvar user--cjk-font "VL Gothic"
  "Default font for CJK characters")

(defvar user--latin-font "VL Gothic"
  "Default font for Latin characters")

(defvar user--cjk-proportional-font "VL PGothic"
  "Default font for Latin characters")

(defvar user--unicode-font "Noto Sans Mono CJK JP"
  "Default font for Unicode characters. including emojis")

(defvar user--unicode-emoji-font "Noto Color Emoji"
  "Default font for Unicode emoji characters.")

;; Notoフォントでベンガル語(charset名はbengali)を表示するとクラッシュする。
;; バックトレースを見るとlibm17n/libotf0でクラッシュしているようだ。
;; $ fc-list :lang=bn
;; を実行してベンガル語をサポートするフォント一覧を出力すると、
;; Notoフォント以外にFreeSansがある。
;; ので、FreeSansをフォールバックフォントとして用いる。
(defvar user--unicode-font-fallback "FreeSans"
  "Fallback font for Unicode characters.")

(defvar user--standard-fontset "fontset-user"
  "Standard fontset for user.")

(defun user--set-font ()
  "Set Unicode, Latin and CJK font for user--standard-fontset."
  ;; 記号にはデフォルトのフォントではなく指定のフォントを使いたい
  (setq use-default-font-for-symbols nil)
  (create-fontset-from-ascii-font user--cjk-font nil (replace-regexp-in-string "fontset-" "" user--standard-fontset))
  ;; unicodeに対してuser--cjk-fontがグリフを持っていればそれを使い、
  ;; 持っていない場合にはuser--unicode-fontで補完する
  (set-fontset-font user--standard-fontset 'unicode
                    (font-spec :family user--cjk-font)
                    nil)
  (set-fontset-font user--standard-fontset 'unicode
                    (font-spec :family user--unicode-font)
                    nil 'append)
  ;; latinに対してuser--latin-fontを使う
  (set-fontset-font user--standard-fontset 'latin
                    (font-spec :family user--latin-font)
                    nil 'prepend)
  ;; CJKに対してuser--cjk-fontを使う
  (dolist (charset '(kana han cjk-misc hangul kanbun bopomofo))
    (set-fontset-font user--standard-fontset charset
                  (font-spec :family user--cjk-font)
                  nil 'prepend))
  ;; symbolに対してuser--unicode-emoji-fontを使う
  (set-fontset-font t 'symbol user--unicode-emoji-font nil 'append)
  ;; TODO 日本語フォントではU+2018とU+2019は全角幅だがWeb上の英文ではアポストロフィに使われていて
  ;; 見栄えが悪い。現状は全角で表示し必要に応じてU+0027に置換する。よい方法はないものか。
  (dolist (charset '((#x2018 . #x2019)    ;; Curly single quotes "‘’"
                     (#x201c . #x201d)))  ;; Curly double quotes "“”"
    (set-fontset-font user--standard-fontset charset
                      (font-spec :family user--cjk-font)
                      nil)) ; 上書きするために第5引数ADDは省略する
  ;; フォールバックフォントを用いる言語(charsetは C-u C-x = のscriptセクションの名前を用いる)
  (dolist (charset '(bengali bengali-akruti bengali-cdac))
    (set-fontset-font user--standard-fontset charset
                      (font-spec :family user--unicode-font-fallback)
                      nil 'prepend)))

(when window-system
  ;; create fontset-user
  (user--set-font)
  ;; Ensure user--standard-fontset gets used for new frames.
  (add-to-list 'default-frame-alist `(font . ,user--standard-fontset))
  (add-to-list 'initial-frame-alist `(font . ,user--standard-fontset)))
```

## PROBLEMSの抜粋

libotfに関する問題の存在は`PROBLEMS`ファイルにしっかりと書かれていました。
Emacsのよいところは公式がドキュメント化をしっかりしているところで、`PROBLEMS`ファイルにしっかり目を通しましょう、という教訓になりました。

```org
** Emacs crashes when you try to view a file with complex characters.

One possible reason for this could be a bug in the libotf or the
libm17n-flt/m17n-db libraries Emacs uses for displaying complex
scripts.  Make sure you have the latest versions of these libraries
installed.  If the problem still persists with the latest released
versions of these libraries, you can try building these libraries from
their CVS repository:

  cvs -z3 -d:pserver:anonymous@cvs.savannah.nongnu.org:/sources/m17n co libotf
  cvs -z3 -d:pserver:anonymous@cvs.savannah.nongnu.org:/sources/m17n co m17n-db
  cvs -z3 -d:pserver:anonymous@cvs.savannah.nongnu.org:/sources/m17n co m17n-lib

One known problem that causes such crashes is with using Noto Serif
Kannada fonts.  To work around that, force Emacs not to select these
fonts, by adding the following to your ~/.emacs init file:

  (push "Noto Serif Kannada" face-ignored-fonts)

You can try this interactively in a running Emacs session like this:

  M-: (push "Noto Serif Kannada" face-ignored-fonts) RET

Another set of problems is caused by an incompatible libotf library.
In this case, displaying the etc/HELLO file (as shown by C-h h)
triggers the following message to be shown in the terminal from which
you launched Emacs:

  symbol lookup error: /usr/bin/emacs: undefined symbol: OTF_open

This problem occurs because unfortunately there are two libraries
called "libotf".  One is the library for handling OpenType fonts,
http://www.m17n.org/libotf/, which is the one that Emacs expects.
The other is a library for Open Trace Format, and is used by some
versions of the MPI message passing interface for parallel
programming.

For example, on RHEL6 GNU/Linux, the OpenMPI rpm provides a version
of "libotf.so" in /usr/lib/openmpi/lib.  This directory is not
normally in the ld search path, but if you want to use OpenMPI,
you must issue the command "module load openmpi".  This adds
/usr/lib/openmpi/lib to LD_LIBRARY_PATH.  If you then start Emacs from
the same shell, you will encounter this crash.
Ref: <URL:https://bugzilla.redhat.com/show_bug.cgi?id=844776>

There is no good solution to this problem if you need to use both
OpenMPI and Emacs with libotf support.  The best you can do is use a
wrapper shell script (or function) "emacs" that removes the offending
element from LD_LIBRARY_PATH before starting emacs proper.
Or you could recompile Emacs with an -Wl,-rpath option that
gives the location of the correct libotf.
```

## 切っ掛け

tarから`~/opt/firefox`に展開して使っているFirefoxをユーザーのデフォルトのWebブラウザに設定しようと、
Firefoxのdesktopファイルを作ることにしました。一方でchromiumをパッケージとしてインストールしてあり、
`/usr/share/applications/chromium.desktop`を参考に`~/.local/share/applications/firefox.desktop`を
作ることにしました。しかし、Emacsで`/usr/share/applications/chromium.desktop`を開こうとするとクラッシュします。
Emacsで開けないテキストファイルがあるのは非常に困るので、問題を調査することにしました。

## 解決までにやったこと

1. 別のエディタ、`vi`や`gedit`で開いてみる
   - クラッシュしない
   - `chromium.desktop`を見ると様々な言語でコメントが書かれており、文字表示のバグだと推測する
1. `~/.xsession-errors`を見る
   - Emacsのバックトレースがあり、`libotf.so.0`と`libm17n-flt.so.0`が原因だと推測する
1. `chromium.desktop`を1行ずつファイルに分けて出力し、問題が起きる行を特定する
   - `GenericName[bn]=ওয়েব ব্রাউজার`で落ちる
   - アルファベット2文字コード`bn`はブルネイであり、使用言語はベンガル語(`Bangla`または`Bengali language`)、使用文字はベンガル文字(`Bangla lipi`または`Bengali alphabet`または`Bengali script`)と呼ばれることを知る
1. ベンガル文字のどの文字が落ちる原因となるのかを詳しく調べるために`ওয়েব ব্রাউজার`を1文字または2文字ずつ別のファイルに分けて出力し、1ファイルずつ開く
   - クラッシュしない
1. `M-x view-hello-file`で`HELLO`ファイルを開く
   - ベンガル語のあいさつ`নমস্কার`ではクラッシュしない
   - `C-u C-x =`を実行し、ベンガル文字にはNotoフォントを使っていることを確認する
     - `script`セクションの出力からcharsetは`bengali`であることを知る
1. `fc-list :lang=bn`でベンガル文字を含むフォントを探す
   - Notoフォント以外にはFreeSansとFreeSerifがインストールされていることを確認する
1. [Fun With Fonts in Emacs](https://www.shimmy1996.com/en/posts/2018-06-24-fun-with-fonts-in-emacs/)を元にしたフォント設定の書式で、ベンガル語にはFreeSansを使う設定をする
1. [tl;dr](#tldr)の設定で[ベンガル語の辞書ファイル](https://github.com/MinhasKamal/BengaliDictionary/blob/master/BengaliDictionary_17.txt)や`chromium.desktop`を開き、クラッシュしなくなることを確認する

ちなみに、切っ掛けであったFirefoxのデフォルト化については以下の設定で実現できました。

```console
$ cat ~/.local/share/applications/firefox.desktop
[Desktop Entry]
Version=1.0
Name=Firefox Web Browser
GenericName=Web Browser
Comment=Access the Internet
Exec=firefox %U
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=firefox
Categories=Network;WebBrowser;
StartupWMClass=Firefox
StartupNotify=true
MimeType=x-scheme-handler/unknown;x-scheme-handler/about;text/html;text/xml;application/xhtml_xml;application/x-mimearchive;x-scheme-handler/http;x-scheme-handler/https;
$ xdg-settings set default-web-browser firefox.desktop
```

## 参考

libotfがEmacsのクラッシュにつながるケースは以前からあったようです。

- [Fun With Fonts in Emacs](https://www.shimmy1996.com/en/posts/2018-06-24-fun-with-fonts-in-emacs/)
- [emacs/etc/PROBLEMS (GitHub)](https://github.com/emacs-mirror/emacs/blob/master/etc/PROBLEMS)
- [Bug #1735167 “emacs (emacs24-x) crashes reliably on certain utf-...” : Bugs : emacs24 package : Ubuntu](https://bugs.launchpad.net/ubuntu/+source/emacs24/+bug/1735167)

[Fun With Fonts in Emacs](https://www.shimmy1996.com/en/posts/2018-06-24-fun-with-fonts-in-emacs/)には非常に助けられています。
