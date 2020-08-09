---
title: GitHub Pagesのビルド元となるブランチは選べる
author: nobiruwa
tags: GitHub
---

久々にこの[GitHub Pages](https://nobiruwa.github.io/)を閲覧しようとしたところ、404エラーで見られなくなっていました。

「1. masterブランチに静的HTMLサイトをPUSHする」「2. index.htmlを設ける」「3. コミットしてみる」「4. リポジトリを削除して、再度作成してみる」などで解決した、というWebの情報があり1から3までは実行してみたものの解決しませんでした。

「何か設定を間違ったか？」と思い、私のアカウントで[リポジトリ自体](https://github.com/nobiruwa/nobiruwa.github.io)の設定を確認することにしました。まずSettingsタブに遷移します。

![Settingsタブ](/images/2020-08-09-github-pages-settings-icon.png)

Optionsに並ぶ設定項目を見ていると、見慣れない項目がありました。

![GitHub Pages の設定項目(デフォルトのブランチdevelopがビルドのソース)](/images/2020-08-09-github-pages-settings.png)

Beta版で追加されていた「Source」項目で、ビルドされるブランチが指定できるようになっていて、デフォルトのブランチとして指定してあったdevelopとなっていました。Beta版とはいえ、見落としていました。

これをmasterブランチに変えます。

![GitHub Pages の設定項目(masterブランチをビルドのソースにする)](/images/2020-08-09-github-pages-settings-after-save.png)

masterブランチにPUSHしてあったHakyll製のページが表示されるようになりました。

![GitHub Page](/images/2020-08-09-github-pages-site-index-page.png)

## ついでに覚えたこと

### マークダウン記法

`![キャプション](URL)`で画像を貼り付けることができます。

### Linux(X環境)でのスクリーンショットの取り方 - ImageMagick

ImageMagickの`import <ファイルパス>`コマンドを実行すると、マウスポインタのカーソルが`+`記号に似た形状に変化し、画面内をドラッグで矩形選択することで、`<ファイルパス>`にスクリーンショットを保存できます。

`import -window <画面ID> <ファイルパス>`とオプションを追加すると、矩形選択ではなく、オプションで指定した領域を自動的に撮影します。例えば、`-window root`とすると、複数画面がシームレスに撮影されました。
