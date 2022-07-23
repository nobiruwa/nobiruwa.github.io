---
title: 非公式APTリポジトリの利用 - apt-key addから/etc/apt/trusted.gpg.dとsigned-byオプションへの移行
author: nobiruwa
tags: Debian, APT, apt key
---

`apt key`を実行すると以下のメッセージを見るようになりました。

```console
Warning: apt-key is deprecated. Manage keyring files in trusted.gpg.d instead (see apt-key(8)).
```

`/etc/apt/trusted.gpg.d`ディレクトリを見ると`debian-archive-keyring`パッケージによって展開されたDebian公式リポジトリのOpenPGP公開鍵が存在しています。

非公式なAPTリポジトリについての対処方法は[DebianRepository/UseThirdParty - Debian Wiki](https://wiki.debian.org/DebianRepository/UseThirdParty)に分かりやすく書いてありました。

OpenPGP公開鍵の配布方法は[OpenPGP Key distribution](https://wiki.debian.org/DebianRepository/UseThirdParty#OpenPGP_Key_distribution)にて以下のように定められています。

1. リポジトリはOpenPGP鍵で署名されているべきです。
2. バイナリ形式の公開鍵が`<deriv>-archive-keyring.gpg`という名前でリポジトリのルートから取得可能であるべきです。
   - `<deriv>`はリポジトリを表す短い名前です。
3. ASCII形式の公開鍵は`<deriv>-archive-keyring.asc`という名前で取得可能でもよいです。
4. OpenPGP公開鍵はHTTPSで提供されるべきです。
5. 公開鍵サーバから取得可能にしてもよいです。
   - 適切な公開鍵サーバーを選ぶべきです。
   - OpenPGP公開鍵は他の信頼できる鍵で署名されるべきです。
6. rootのみが書き換え可能な場所でHTTPSのようなセキュアなメカニズムでダウンロードできなければなりません。
   - `/etc/apt/trusted.gpg.d`に置いてはなりません。
   - `apt-key add`で追加してはなりません。
   - `/usr/share/keyrings`に置くべきです。

リポジトリを利用する場合には以下に従う必要があります。

1. ASCII形式の公開鍵を使ってはなりません。
   - `gpg --dearmor`や、`gpt --import`と`gpg --export`の組合せなどでバイナリ形式に変換すべきです。
2. `sources.list`のエントリは`signed-by`オプションを持つべきです。
   - `signed-by`オプションにはフィンガープリントではなくファイルを指定しなければなりません。
   - tipではsecure aptのバージョンが1.4以降であればASCII形式のOpenPGP公開鍵を使用できるとあります。
     `signed-by`オプションでは`gpg`拡張子だとバイナリ形式として読み込み、`asc`拡張子だとASCII形式として読み込むようです。
     私はバイナリ形式とASCII形式の両方を管理するものの、`signed-by`オプションにはバイナリ形式を使うことにします。

## `/etc/apt/trusted.gpg.d`と`signed-by`オプションへの移行

節のタイトルとは矛盾しますが`/etc/apt/trusted.gpg.d`を避けて非公式APTリポジトリの公開鍵を管理しなければなりません。

`/usr/share/keyrings`ディレクトリには`debian-archive-keyring`パッケージに含まれるOpenPGP公開鍵が置かれているため、`/usr/local/share/keyrings`ディレクトリを作り分けて管理することにしました。

以下に利用している非公式APTリポジトリの`sources.list`の内容を掲載します。`#`で始まるコメント行にOpenPGP公開鍵の取得方法を書きました。

プロンプト文字が`$`であれば一般ユーザーで実行するコマンドで、`#`であればrootで実行するコマンドです。

### Docker Engine (`/etc/apt/sources.list.d/docker-engine.list`)

```
# # wget https://download.docker.com/linux/debian/gpg -O /usr/local/share/keyrings/docker-engine.asc
# # wget -qO- https://download.docker.com/linux/debian/gpg | gpg --dearmor | tee /usr/local/share/keyrings/docker-engine.gpg > /dev/null
deb [signed-by=/usr/local/share/keyrings/docker-engine.gpg] https://download.docker.com/linux/debian bullseye stable
```

### Heroku CLI (`/etc/apt/sources.list.d/heroku.list`)

```
# # wget https://cli-assets.heroku.com/apt/release.key -O /usr/local/share/keyrings/heroku-archive-keyring.asc
# # wget -qO- https://cli-assets.heroku.com/apt/release.key | gpg --dearmor | tee /usr/local/share/keyrings/heroku-archive-keyring.gpg > /dev/null
deb [signed-by=/usr/local/share/keyrings/heroku-archive-keyring.gpg] https://cli-assets.heroku.com/apt ./
```

### ローカルAPTリポジトリ (`/etc/apt/sources.list.d/local-debsrc.list`)

```
# $ gpg --list-keys # get a fingerprint
# $ gpg --export <fingerprint> | sudo dd of=/usr/local/share/keyrings/local-debsrc-archive-keyring.gpg
# $ gpg -a --export <fingerprint> | sudo tee /usr/local/share/keyrings/local-debsrc-archive-keyring.asc
deb [signed-by=/usr/local/share/keyrings/local-debsrc-archive-keyring.gpg] file:///home/ein/debsrc/repository/ ./
```

### PowerShell (`/etc/apt/sources.list.d/microsoft.list`)

```
# # wget https://packages.microsoft.com/keys/microsoft.asc -O /usr/local/share/keyrings/microsoft-archive-keyring.asc
# # wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/local/share/keyrings/microsoft-archive-keyring.gpg > /dev/null
deb [arch=amd64 signed-by=/usr/local/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/microsoft-debian-bullseye-prod/ bullseye main
```

[Installing PowerShell on Debian Linux - PowerShell | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/scripting/install/install-debian?view=powershell-7.2)の[Installation on Debian 10 via Package Repository](https://docs.microsoft.com/en-us/powershell/scripting/install/install-debian?view=powershell-7.2#installation-on-debian-10-via-package-repository)を見ると正しいOpenPGP公開鍵の取得からPowerShellのインストールの手順は以下の通りのようです。

```console
# Download the Microsoft repository GPG keys
$ wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb

# Register the Microsoft repository GPG keys
$ sudo dpkg -i packages-microsoft-prod.deb

# Update the list of products
$ sudo apt-get update

# Install PowerShell
$ sudo apt-get install -y powershell

# Start PowerShell
$ pwsh
```

### Skype Stable (`/etc/apt/sources.list.d/skype-stable.list`)

```
# # wget https://repo.skype.com/data/SKYPE-GPG-KEY -O /usr/local/share/keyrings/skype-archive-keyring.gpg
# # rm -f /tmp/skype-archive-keyring.gpg
# # gpg --keyring /tmp/skype-archive-keyring.gpg --no-default-keyring --import /usr/local/share/keyrings/skype-archive-keyring.gpg
# # gpg --keyring /tmp/skype-archive-keyring.gpg --no-default-keyring --export -a > /usr/local/share/keyrings/skype-archive-keyring.asc
deb [arch=amd64 signed-by=/usr/local/share/keyrings/skype-archive-keyring.gpg] https://repo.skype.com/deb stable main
```

### Skype Unstable (`/etc/apt/sources.list.d/skype-unstable.list`)

```
# # wget https://repo.skype.com/data/SKYPE-GPG-KEY -O /usr/local/share/keyrings/skype-archive-keyring.gpg
# # rm -f /tmp/skype-archive-keyring.gpg
# # gpg --keyring /tmp/skype-archive-keyring.gpg --no-default-keyring --import /usr/local/share/keyrings/skype-archive-keyring.gpg
# # gpg --keyring /tmp/skype-archive-keyring.gpg --no-default-keyring --export -a > /usr/local/share/keyrings/skype-archive-keyring.asc
deb [arch=amd64 signed-by=/usr/local/share/keyrings/skype-archive-keyring.gpg] https://repo.skype.com/deb unstable main
```

## `/etc/apt/trusted.gpg`の削除

`apt-key add`で使われていた`/etc/apt/trusted.gpg`を削除します。

```console
# rm /etc/apt/trusted.gpg
```

## `apt update`の実行

最後に`apt update`を実行してエラーが出なければ移行の完了です。

なお、拡張子(`.gpg`か`.asc`)と実際の中身が違っていたり、無関係なOpenPGP公開鍵ファイルを指定していたりすると`NO_PUBKEY`といったGPG errorが表示されます。
