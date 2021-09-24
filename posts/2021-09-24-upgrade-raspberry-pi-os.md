---
title: Raspberry Pi OSをBullseyeにアップグレードする
author: nobiruwa
tags: Rasberry Pi, Debian, Linux
---

## BusterからBullseyeへアップグレード

2021年8月に[Debian GNU Linux bullseye](https://www.debian.org/releases/stable/)がリリースされました。Raspberry Pi OSの公式リリースに先駆けてBullseyeをインストールすることにしました。

## `/etc/apt/sources.list`の更新

使用するリポジトリを`buster`から`bullseye`に変更する必要があります。32bit版を使っているので以下の通りに変更しました。

### `/etc/apt/sources.list.d/docker.list`の更新

```
deb [arch=armhf signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/raspbian bullseye stable
```

### `/etc/apt/sources.list.d/raspi.list`の更新

```
deb http://archive.raspberrypi.org/debian/ bullseye main
# Uncomment line below then 'apt-get update' to enable 'apt-get source'
#deb-src http://archive.raspberrypi.org/debian/ buster main
```

## `apt`の実行

手順は[Chapter 4. Upgrades from Debian 10 (buster)](https://www.debian.org/releases/stable/amd64/release-notes/ch-upgrading.en.html#backup)を参考にしました。

```console
# apt clean # 古いパッケージのキャッシュを削除
# apt update
# apt upgrade --without-new-pkgs
# apt --purge remove libgcc-8-dev gcc-8-base # 競合の削除
# apt full-upgrade
# apt --purge autoremove
# reboot
```

途中`apt full-upgrade`でパッケージを展開できなくなっていたため、SDカードをPCに挿して`fsck -y <SDカードのパーティションに対応したブロックデバイス>`によりファイルシステムを修復する必要がありました。

## アップグレード後

### I2Cを有効にする

アップグレード後、I2Cが無効になっていたため、有効にしました。

```console
# raspi-config
=> 3 Interface Options
=> P5 I2C
=> `Would you like the ARM I2C interface to be enabled?`という質問に`<Yes>`と回答することで有効になる
```

### Python環境の最新化

pythonのバージョンが3.9になったため、`pip`コマンドの再インストールや`virtualenv`環境の再構築を行いました。

```console
$ python3 get-pip.py --user
```

```console
$ rm ~/.local/bin/easy_install-<古いバージョン>
$ rm ~/.local/bin/pip<古いバージョン>
$ rm -rf ~/.local/lib/python<古いバージョン>
```

```console
$ . <virtualenvディレクトリ>/bin/activate
$ pip install --upgrade <パッケージ>...
$ deactivate
```
