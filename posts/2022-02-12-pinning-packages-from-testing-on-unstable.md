---
title: Debianのunstable版でtesting版のパッケージを使用する(Pinning)
author: nobiruwa
tags: Debian, Pinning, AptPreferences, NVIDIA Driver
---

## 切っ掛け

Debianのunstable版を使っていると、`apt upgrade`を行ったタイミングでXが使えなくなることがあります。

少なくとも私のPCでは、[NvidiaGraphicsDrivers#Build\_failures - Debian Wiki](https://wiki.debian.org/NvidiaGraphicsDrivers#Build_failures)にあるようにNVIDIAのドライバが新しいカーネルに対応していない場合に起こっています。

この記事では回避方法として以下の3つが上げられています。

> Solutions for this, from most to least recommended, are temporarily
> using an older kernel until the driver is updated, installing a
> newer version of the driver from Debian Experimental if one is
> available that supports your kernel version, or finding a patch for
> the build failure online that can be added to DKMS.

1. ドライバーが更新されるまでより古いカーネルを使う
2. experimental版のより新しいドライバーをインストールする
3. オンラインでDKMSに追加できるパッチを探す

今回は、ドライバーが更新されるまでの暫定的な対応として、testing版から古いカーネルとドライバなど他のパッケージをpinning(ピン留め)を使ってインストールすることにしました。

## 症状

以下のように`xserver-xorg-video-nvidia`の依存パッケージである`xorg-video-abi-NN`(`NN`はバージョン番号)を解決できずに失敗します。
`xorg-video-abi-NN`はvirtual packageであり、実際には適切なバージョンの`xserver-xorg-core`がないということを示しています。

```console
The following packages have unmet dependencies:
 xserver-xorg-video-nvidia : Depends: xorg-video-abi-24 or
                                      xorg-video-abi-23 but it is not installable or
                                      xorg-video-abi-20 but it is not installable or
                                      xorg-video-abi-19 but it is not installable or
                                      xorg-video-abi-18 but it is not installable or
                                      xorg-video-abi-15 but it is not installable or
                                      xorg-video-abi-14 but it is not installable or
                                      xorg-video-abi-13 but it is not installable or
                                      xorg-video-abi-12 but it is not installable or
                                      xorg-video-abi-11 but it is not installable or
                                      xorg-video-abi-10 but it is not installable or
                                      xorg-video-abi-8 but it is not installable or
                                      xorg-video-abi-6.0 but it is not installable
                             Depends: xserver-xorg-core (< 2:1.20.99) but 2:21.1.3-2 is to be installed
E: Unable to correct problems, you have held broken packages.
```

## `sources.list`の設定

まずは`/etc/apt/sources.list`testing版のリポジトリを追加します。

```
[...snip...]
deb http://ftp.jp.debian.org/debian/ testing main contrib non-free
[...snip...]
```

パッケージを更新します。

```console
$ sudo apt update
```

## `apt_preferences`の設定

次に、[3.10 How to keep specific versions of packages installed (complex) - APT HOWTO (Obsolete Documentation)](https://www.debian.org/doc/manuals/apt-howto/ch-apt-get.en.html#s-pin)の説明を参考にしつつ、`/etc/apt/preferences.d/testing.pref`を作り以下の内容を記述しました。

```
# downgrade dependencies
Package: *
Pin: release a=testing
Pin-Priority: 50

# downgrade packages (Pin-Priority must be more than 1000.)
Package: linux-image-* linux-headers-* nvidia-driver nvidia-driver-bin xserver-xorg-video-nvidia nvidia-vdpau-driver nvidia-alternative nvidia-kernel-dkms nvidia-legacy-check nvidia-driver-libs nvidia-driver-libs-nonglvnd xserver-xorg-core xserver-xorg-input-*
Pin: release a=testing
Pin-Priority: 1001
```

### 1個目のPinningの内容

testingアーカイブのパッケージをまず`Pin-Priotrity: 50`、つまり明示しない限りインストールの対象とならないようにします。

他のパッケージの依存関係として必要な場合もインストールされます。

### 2個目のPinningの内容

ダウングレードを可能とするために、`Pin-Priority`を`1001`にしています。

testingアーカイブからpinningするパッケージを`Packages`セクションに列挙します。

以下の設定が必要でした。

1. カーネルのダウングレードに必要だった設定
   - `linux-image-* linux-headers-*`
2. ドライバのダウングレードに必要だった設定
   - `nvidia-driver nvidia-driver-bin xserver-xorg-video-nvidia nvidia-vdpau-driver nvidia-alternative nvidia-kernel-dkms nvidia-legacy-check nvidia-driver-libs nvidia-driver-libs-nonglvnd xserver-xorg-core`
     - `nvidia-driver`から`nvidia-driver-libs-nonglvnd`までは[How to properly setup and install nvidia on Debian/Devuan - \@Kreyren's GitHub Gist](https://gist.github.com/Kreyren/cccf642ce672fd8f127ed128cf27749b#file-gistfile1-md)からそのまま拝借しました。
     - testing版とunstble版の`nvidia-driver`などNVIDIAのドライバに関係するパッケージのバージョンは同一だったので、pinningが真に必要なパッケージは`xserver-xorg-core`だけなのかもしれませんが、一応すべてpinningすることにしました。
3. マウスとキーボードを使用可能にするために必要だった設定
   - `xserver-xorg-input-*`
     - `startx`後にマウスがキーボードを使えなくなったため、[user interface - Mouse and Keyboard not working after reinstalling ubuntu-desktop - Stack Overflow](https://stackoverflow.com/a/59127797/10974912)を参考に追加しました。

### Pinningの確認

`/etc/apt/preferences.d/testing.pref`の設定が`apt-cache policy`に反映されているかを確認します。

```console
$ sudo apt-cache policy
Package files:
[...snip...]
  50 http://ftp.jp.debian.org/debian testing/non-free i386 Packages
     release o=Debian,a=testing,n=bookworm,l=Debian,c=non-free,b=i386
     origin ftp.jp.debian.org
  50 http://ftp.jp.debian.org/debian testing/non-free amd64 Packages
     release o=Debian,a=testing,n=bookworm,l=Debian,c=non-free,b=amd64
     origin ftp.jp.debian.org
  50 http://ftp.jp.debian.org/debian testing/contrib i386 Packages
     release o=Debian,a=testing,n=bookworm,l=Debian,c=contrib,b=i386
     origin ftp.jp.debian.org
  50 http://ftp.jp.debian.org/debian testing/contrib amd64 Packages
     release o=Debian,a=testing,n=bookworm,l=Debian,c=contrib,b=amd64
     origin ftp.jp.debian.org
  50 http://ftp.jp.debian.org/debian testing/main i386 Packages
     release o=Debian,a=testing,n=bookworm,l=Debian,c=main,b=i386
     origin ftp.jp.debian.org
  50 http://ftp.jp.debian.org/debian testing/main amd64 Packages
     release o=Debian,a=testing,n=bookworm,l=Debian,c=main,b=amd64
     origin ftp.jp.debian.org
[...snip...]
Pinned packages:
     xserver-xorg-input-evdev -> 1:2.10.6-2 with priority 1001
     xserver-xorg-input-mouse -> 1:1.9.3-1 with priority 1001
     nvidia-alternative -> 470.103.01-1 with priority 1001
     xserver-xorg-core -> 2:1.20.14-1 with priority 1001
     xserver-xorg-input-all -> 1:7.7+23 with priority 1001
     xserver-xorg-input-kbd -> 1:1.9.0-1+b2 with priority 1001
     xserver-xorg-input-mutouch -> 1:1.3.0-2+b1 with priority 1001
     xserver-xorg-input-joystick -> 1:1.6.3-1+b1 with priority 1001
     xserver-xorg-input-xwiimote -> 0.5-1+b3 with priority 1001
     xserver-xorg-input-elographics -> 1:1.4.2-1 with priority 1001
     nvidia-driver-bin -> 470.103.01-1 with priority 1001
     xserver-xorg-input-aiptek -> 1:1.4.1-3+b1 with priority 1001
     nvidia-driver-libs -> 470.103.01-1 with priority 1001
     nvidia-driver -> 470.103.01-1 with priority 1001
     xserver-xorg-input-synaptics -> 1.9.1-2 with priority 1001
     nvidia-kernel-dkms -> 470.103.01-1 with priority 1001
     xserver-xorg-input-mtrack -> 0.3.1-1+b3 with priority 1001
     xserver-xorg-input-libinput -> 1.2.0-1 with priority 1001
     xserver-xorg-input-evdev-dev -> 1:2.10.6-2 with priority 1001
     nvidia-legacy-check -> 470.103.01-1 with priority 1001
     xserver-xorg-input-wacom -> 0.34.99.1-1+b1 with priority 1001
     xserver-xorg-input-joystick-dev -> 1:1.6.3-1 with priority 1001
     nvidia-vdpau-driver -> 470.103.01-1 with priority 1001
     xserver-xorg-input-libinput-dev -> 1.2.0-1 with priority 1001
     xserver-xorg-input-synaptics-dev -> 1.9.1-2 with priority 1001
     xserver-xorg-video-nvidia -> 470.103.01-1 with priority 1001
     xserver-xorg-input-multitouch -> 1.0~rc3-2+b1 with priority 1001
```

期待通りに反映されていることが確認できました。

## パッケージのダウングレードインストール

最後にダウングレードインストールを行って完了です。

以下のステップによりXが再び使えるようになりました。

1. testing版のカーネルとヘッダーをインストール
2. testing版のドライバーをインストール
3. マウスとキーボードが使えなくなるので再インストール
4. `/etc/X11/xorg.conf`を念の為更新

実際のコマンドは以下の通りです。

```console
$ sudo apt install linux-{image,headers}-5.15.0-3-amd64 linux-kbuild-5.15
$ sudo apt install nvidia-driver/testing xserver-xorg-core/testing
$ sudo apt install xserver-xorg-input-all
$ sudo nvidia-xconfig
```

他にもステップの途中で`autoremove`を求められるパッケージで削除されては困るものをインストールしました。

```console
$ sudo apt install xdg-dbus-proxy libwayland-client0
```

`startx`で動作テストに成功した後、Xが使えないカーネルは削除しました。

## unstable版のパッケージに戻してよいかのチェック

unstable版のパッケージに戻してよいかは、以下の`apt -s install`コマンドで確認できます。

```console
$ sudo apt update
$ sudo apt -s install xserver-xorg-core/unstable nvidia-driver/unstable xserver-xorg-video-nvidia/unstable
```

新しいカーネルに戻す場合は、`linux-image-<version>-<ARCH>`と`linux-headers-<version>-<ARCH>`だけでなく`linux-kbuild-<version>`パッケージもインストールするようにしてください。

## 参考

- [NvidiaGraphicsDrivers#Build\_failures - Debian Wiki](https://wiki.debian.org/NvidiaGraphicsDrivers#Build_failures)
  - 原因と回避方法が端的に記載されています。
- [3.10 How to keep specific versions of packages installed (complex) - APT HOWTO (Obsolete Documentation)](https://www.debian.org/doc/manuals/apt-howto/ch-apt-get.en.html#s-pin)
  - pinningの書式が分かりやすく書かれています。
- [How to properly setup and install nvidia on Debian/Devuan - \@Kreyren's GitHub Gist](https://gist.github.com/Kreyren/cccf642ce672fd8f127ed128cf27749b#file-gistfile1-md)
  - pinningの対象とすべきパッケージが記載されており参考にしました。
- [user interface - Mouse and Keyboard not working after reinstalling ubuntu-desktop - Stack Overflow](https://stackoverflow.com/a/59127797/10974912)
  - NVIDIAのドライバを再インストールをする時にキーボードとマウスが動かなくなる事象にいつもハマっています。
    この質問と回答のおかげで`xserver-xorg-input-all`も再インストールが必要であることに気付かされました。
