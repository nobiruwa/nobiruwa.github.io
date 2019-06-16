---
title: EmacsでのC/C++開発
author: nobiruwa
tags: C, C++, Emacs, LSP
---

## tl;dr

lsp-modeとcclsを用いることで、十分に快適な環境を得ることができました。

## 切っ掛け

[OpenGLのチュートリアル](http://www.opengl-tutorial.org/)を使って学習しているところ、GNU Globalでは一部のAPIの補完がイマイチだったので、環境を模索することにしました。

例えば、以下のAPIはGNU Globalが`/usr/include`配下を入力して作るタグGTAGSには登録されません。

```{#mycode .cpp .numberLines startFrom="100"}
#define glBindVertexArray GLEW_GET_FUN(__glewBindVertexArray)
```

目標はOpenGLの開発をベンチマークとして、以下の事が実現できるようになることです。

1. 関数名の補完ができる
2. 関数の引数の型・戻り値(つまり関数の型)が分かる
3. 貧弱なPCでもストレスなく使用できる

## 変遷

1. [ggtags](https://github.com/leoliu/ggtags) + [GNU Global](https://www.gnu.org/software/global/)
   - glewのAPIが補完できたりできなかったりしました。
   - 関数を参照するヘッダー内行を検索することで関数の型が分かるのですが、カレントバッファーがいちいちヘッダーファイルに変化するのが億劫に感じました。
2. ggtags + [Exuberant Ctags](http://ctags.sourceforge.net/)
   - GNU Globalと大差ありませんでした。
3. [irony-mode](https://github.com/Sarcasm/irony-mode)
   - `glBindVertexArray`を補完できるようになりましたが、関数の型が分からず惜しいです。
4. [lsp-mode](https://github.com/emacs-lsp/lsp-mode) + [clangd](https://clang.llvm.org/extra/clangd/)
   - 補完と関数の型は申し分ありませんでした。
   - ただ、clangdがlsp-modeから送信されるリクエストを処理しきれず、CPU使用率が100%を超えしばしば通信が切断されます。
5. [eglot](https://github.com/joaotavora/eglot) + clangd
   - 補完と関数の型はlsp-modeほどの情報量はありませんでしたが、申し分ありませんでした。
   - eglotはEmacs側でリクエストをdebounceしますが、clangdはそれでも負荷が高いです。
6. [emacs-ycmd](https://github.com/abingham/emacs-ycmd) + [ycmd](https://github.com/Valloric/ycmd)
   - 期待したような情報が表示されず、カスタマイズによる改善を断念しました。
7. ggtags + [universal-ctags](https://github.com/universal-ctags/ctags)
   - universal-ctagsのコマンドを読み解くのが面倒になり使用を断念しました。
8. lsp-mode + [ccls](https://github.com/MaskRay/ccls)
   - 補完と関数の型は申し分ありませんでした。
   - cclsがdeounce(キューに溜まったリクエストを間引く)するようで、CPU使用率は許容範囲でした。

## lsp-mode + ccls の構築手順

開発のモードとしてlsp-modeを用い、バックエンドにはCCLSを用います。

この組み合わせが気に入った理由は以下の通りです。

1. lsp-mode + [company-lsp](https://github.com/tigersoldier/company-lsp) + [lsp-ui](https://github.com/emacs-lsp/lsp-ui) により、様々な情報が出力されます。
2. cclsは他のバックエンド(clangd、[cquery](https://github.com/cquery-project/cquery))に比べて動作が軽量です。
   - [LSP](https://langserver.org/) ([Language Protocol Server](https://microsoft.github.io/language-server-protocol/)) に基づいているため、フロントエンドとバックエンドは乗り換えが比較的容易です。

cclsはクライアントからのリクエストを適度にdebounce(間引く)するため、比較的CPU使用率が跳ね上がることを防いでいるようです。

詳細はさておき、Clang 7 (2019年4月現在、Debian SidのデフォルトのClangがこのバージョンのため)と組み合わせて開発環境を揃えるための手順と設定を記録しておきます。

#### Clangのインストール + cclsのビルド

```bash
$ sudo apt-get install cmake libclang-7-dev clang-format-7 clang-tools-7
$ cd ~/repo
$ git clone --depth=1 --recursive https://github.com/MaskRay/ccls.git ccls.git
$ cd ccls.git
$ sed -i -e 's/find_program(CLANG_EXECUTABLE clang)/find_program(CLANG_EXECUTABLE clang-7)/' CMakeLists.txt
$ cmake -H. -BRelease -DCMAKE_BUILD_TYPE=Release 
$ cmake --build Release
```

#### Emacsパッケージのインストール

```emacs
M-x package-install
ccls
clang-format
lsp-mode
lsp-ui
```

#### Emacsパッケージの設定

```lisp
;;;;;;;;
;; ccls
;;;;;;;;
(require 'ccls)
(setq ccls-executable (expand-file-name "~/repo/ccls.git/Release/ccls"))
```

```lisp
;;;;;;;;
;; clang-format
;;;;;;;;
(require 'clang-format)
(setq clang-format-executable "/usr/bin/clang-format-7")
```

```lisp
;;;
;; company-mode
;; company-*
;;;
(require 'company)

;; company-backends
(require 'company-clang)
(setq company-clang-executable (executable-find "/usr/bin/clang-7"))
(setq company-clang--version '(normal . 7.0))

(require 'company-dict)
(require 'company-lsp)

(setq company-dict-dir "~/repo/nobiruwa.github/dot-emacs.d.git/company-dict")

(with-eval-after-load "company"
  (global-company-mode +1)
  ;; C-[ C-i
  (global-set-key (kbd "C-M-i") 'company-complete)
  (define-key emacs-lisp-mode-map (kbd "C-M-i") 'company-complete)
  (define-key lisp-interaction-mode-map (kbd "C-M-i") 'company-complete)

  (setq company-backends
        '(company-bbdb
          company-nxml
          company-css
          company-eclim
          company-semantic
          company-lsp
          company-clang
          company-xcode
          company-cmake
          company-capf
          company-files
          (company-dabbrev-code company-etags company-keywords company-dict)
          company-oddmuse
          company-dabbrev)))
```

```lisp
;;;;;;;;
;; lsp-mode
;;;;;;;;
(require 'lsp-mode)
(setq lsp-clients-clangd-executable "/usr/bin/clangd-7")
(setq lsp-prefer-flymake nil)
;; # apt-get install clang-tools-7 # libclang-devのメジャーバージョンと合わせる
;; C++ではclang-formatが必要
(add-hook 'c-mode-hook #'lsp)
(add-hook 'c++-mode-hook #'lsp)
```

```lisp
;;;;;;;;
;; lsp-ui
;;;;;;;;
(require 'lsp-ui)
```
