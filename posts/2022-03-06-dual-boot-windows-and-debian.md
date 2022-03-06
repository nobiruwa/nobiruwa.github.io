---
title: WindowsとDebianのデュアルブートを構成する
author: nobiruwa
tags: Haskell, Emacs, LSP
---

## 切っ掛け

HP PavillionシリーズのデスクトップPCを10年以上使い続けて特に異常もないのですがスペックを刷新しようと思いマウスコンピューター製のデスクトップPCを購入しました。

これまではUEFIではなくBIOSを使ったり、UEFIは使うもののSecure Bootを無効にし使ったりと、Secure Bootを避けていました。

今回はUEFIでSecure Bootを有効にしたうえで、デュアルブート構成でのDebianのインストールに挑戦しました。

## tl;dr

WindowsのシステムドライブのUEFIパーティションを汚さないよう(LinuxがUEFIから起動されるために必要な`shim`というローダーは入れられる)、Linuxのインストールドライブを分けると無用なトラブルを避けられるようです。

新しいデスクトップPCでは購入オプションとして1TBのHDDを追加し、これにDebian GNU/Linux(以下Debian)をインストールすることにしました。

このとき、GRUBもLinuxのインストールドライブにインストールするようにします。

UEFIでは`shim`を起動順序の先頭にすることでGRUBからDebianとWindowsを自由に切り替えられるようになります。

上記の点に気を付ければDebianのインストール自体は`Expert Install`で慣れている(`Graphical Install`はステップのどこかで終了しないことがあるので避けています)ので割愛します。

以下では、UEFIのブート構成に関して学習したことと、今回新たにハマった点を備忘のために記録します。

## ブート構成の確認

Debianをインストールしたら、Debianから`blkid`を実行してパーティション情報を確認します。

```console
$ sudo blkid | sort
/dev/sda1: PARTUUID="3d5baade-95fb-45b4-8128-5951466ceef1"
/dev/sda2: UUID="9225299d-ac2d-4b74-9257-31e7fbeb9c21" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="a1d12f99-db89-4314-9bc1-7538a2668897"
/dev/sda3: UUID="3ea32de2-2799-417e-8467-9cfbbebf3e77" TYPE="swap" PARTUUID="4779845e-1534-4213-9a72-9c36bfb685b3"
/dev/sdb1: LABEL="SYSTEM" UUID="E28E-5404" BLOCK_SIZE="512" TYPE="vfat" PARTLABEL="EFI system partition" PARTUUID="feb4246b-0490-4823-8219-a4198ebab99e"
/dev/sdb2: PARTLABEL="Microsoft reserved partition" PARTUUID="62cecad1-1ecf-467f-beb1-e7c5a51a0bd5"
/dev/sdb3: LABEL="Windows" BLOCK_SIZE="512" UUID="A4768EE4768EB718" TYPE="ntfs" PARTLABEL="Basic data partition" PARTUUID="0be2818d-aa2c-4da8-ab26-bbfe79e9c81f"
/dev/sdb4: LABEL="Windows RE tools" BLOCK_SIZE="512" UUID="24B48F21B48EF518" TYPE="ntfs" PARTLABEL="Basic data partition" PARTUUID="f66dc73e-7639-46f3-a226-dfe9b03b8923"
```

デバイスブロックの割当は、Debianが`/dev/sda`、Windowsが`/dev/sdb`となっているようです。

`efibootmgr`コマンドを実行して、UEFIのブートエントリを確認します。

```
$ efibootmgr -v
BootCurrent: 0002
Timeout: 1 seconds
BootOrder: 0002,0000
Boot0000* Windows Boot Manager	HD(1,GPT,feb4246b-0490-4823-8219-a4198ebab99e,0x800,0x82000)/File(\EFI\MICROSOFT\BOOT\BOOTMGFW.EFI)WINDOWS.........x...B.C.D.O.B.J.E.C.T.=.{.9.d.e.a.8.6.2.c.-.5.c.d.d.-.4.e.7.0.-.a.c.c.1.-.f.3.2.b.3.4.4.d.4.7.9.5.}.../P...............
Boot0002* debian	HD(1,GPT,feb4246b-0490-4823-8219-a4198ebab99e,0x800,0x82000)/File(\EFI\DEBIAN\SHIMX64.EFI)
```

`shim`が追加されていることが確認できました。

次にDebianの`/etc/fstab`の内容を確認します。

```console
$ cat /etc/fstab
[...snip...]
# / was on /dev/sdb2 during installation
UUID=9225299d-ac2d-4b74-9257-31e7fbeb9c21 /               ext4    errors=remount-ro 0       1
# /boot/efi was on /dev/sda1 during installation
UUID=E28E-5404  /boot/efi       vfat    umask=0077      0       1
# swap was on /dev/sdb3 during installation
UUID=3ea32de2-2799-417e-8467-9cfbbebf3e77 none            swap    sw              0       0
```

`/boot/efi`にUEFIパーティションがマウントされるようです。

UEFIパーティションに追加されたDebian用のファイル構成を確認します。

```console
$ sudo find /boot/efi/EFI/debian 
/boot/efi/EFI/debian
/boot/efi/EFI/debian/shimx64.efi
/boot/efi/EFI/debian/grubx64.efi
/boot/efi/EFI/debian/mmx64.efi
/boot/efi/EFI/debian/fbx64.efi
/boot/efi/EFI/debian/BOOTX64.CSV
/boot/efi/EFI/debian/grub.cfg
```

`/boot/efi/EFI/debian/grub.cfg`があることから`shim`はGRUBを実行するのだと分かります。

`/boot/efi/EFI/debian/grub.cfg`の内容を確認します。

```console
$ sudo cat /boot/efi/EFI/debian/grub.cfg
search.fs_uuid 9225299d-ac2d-4b74-9257-31e7fbeb9c21 root hd0,gpt2 
set prefix=($root)'/boot/grub'
configfile $prefix/grub.cfg
```

GRUBは`/`(=`PARTUUID=9225299d-ac2d-4b74-9257-31e7fbeb9c21` = `/dev/sda2`)にあるGRUBの設定(`/boot/grub/grub.cfg`)をロードして、メニューを表示するということが分かります。

## GRUBのメニューにWindowsを表示させる

`os-prober`がWindowsの存在するパーティションを探索してGRUBのメニューに追加するのですが、[セキュリティを理由に](https://forum.manjaro.org/t/grub2-why-is-os-prober-now-disabled-by-default/57599)デフォルトでは無効となっています。

`/etc/grub.d`ディレクトリ配下にカスタムのスクリプトを置くことでもメニューエントリを追加できますが、今回は自己責任で`os-prober`を有効にしてWindowsを表示させることにしました。

手順は以下の3ステップです。

1. `ntfs-3g`をインストールする
2. `/etc/default/grub`に`GRUB_DISABLE_OS_PROBER=false`を追加する
3. `update-grub`を実行する

コマンドは以下の通り実行しました。

```console
$ sudo apt install ntfs-3g
$ echo '' >> /etc/default/grub
$ echo '# Enable os-prober' >> /etc/default/grub
$ echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
$ sudo update-grub
```

## NVIDIAグラフィックスドライバーをインストールする

NVIDIAグラフィックスドライバーは`nvidia-driver`パッケージを入れるだけで使えるようになると考えていましたが、
[Debian Bug report logs - #953366](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=953366)と同じ状態になり
GUIを起動することができませんでした 。

Secure Bootの導入によって、カーネルドライバーに署名が必須となります。


Debianが公式に署名していないドライバーにはMachine Owner Key (以下MOK)、つまりマシン所有者自身の署名が必要です。

[Debian Wiki](https://wiki.debian.org/SecureBoot)で具体的な手順が説明されています。
[Ubuntuのブログ](https://ubuntu.com/blog/how-to-sign-things-for-secure-boot)が元となっているようですが使用するコマンド名に違いがあるようです。

1. MOKを作成する。
   - 適当な内容でX.509エンコーディングの証明書と鍵を作ればよく、`openssl`コマンドを使って作成できます。
   - 証明書はUbuntuを真似て`/var/lib/shim-signed/mok`ディレクトリに置くとよいです。
2. MOKをエンロールする。
   - エンロールとはドライバーの署名が信頼できるものであるとみなされるよう、EFIに証明書を登録する作業です。
   - `mokutil`パッケージの`mokutil`コマンドを使用します。`mokutil`コマンドは実行時にパスワードを求めます。
     Debian Wikiでは`# prompts for one-time password`とあるので1回限りのパスワードと考えてよさそうです。
     OSの終了からマシンの電源が切られるまでの間に証明書の登録を行うようで、
     OSのシャットダウンを行うと途中ターミナルのダイアログで`mokutil`コマンドで入力したパスワードの再入力を
     求められます。これで、OSの起動時に毎回証明書がロードされるようになります。
3. ドライバーに署名する。
   - `sbsigntool`パッケージの`sbsign`コマンドを使ってカーネルそのもの(`/boot/vmlinuz-$VERSION`)やカーネルモジュール(`*.ko`)に署名することができます。

以上がSecure BootのためのMOKを使った署名の方法ですが、NVIDIAのプロプライエタリなドライバーインストーラを使うと、
ドライバーのコンパイル、署名鍵の作成、署名を一度に行ってくれます。あとはMOKをエンロールするだけです。

インストーラは`lynx`などテキストベースのWebブラウザを使えばコンソールからもダウンロードできます。

インストーラのウィザードの内容は[UEFI のセキュアブート機にNVIDIAのドライバを入れる話](https://qiita.com/arc279/items/99f08b549c95881007b9)で確認できます。

MOKは`/usr/share/nvidia`ディレクトリ配下に保存されます。

```console
$ ls /usr/share/nvidia/nvidia-modsign*
nvidia-modsign-crt-<hexstring>.der
nvidia-modsign-key-<hexstring>.key
```

`<hexstring>`は鍵を表す8桁16進数の数値です。

インストーラ実行後、`mokutil`で`nvidia-modsign-crt-<hexstring>.der`を登録します。

```console
$ sudo mokutil -import nvidia-modsign-crt-<hexstring>.der
```

生成された鍵は次回以降のコンパイルで再利用できます。

鍵の入れ換えを行った場合は[mokutil --export と mokutil --delete](https://askubuntu.com/questions/805152/is-it-possible-to-delete-an-enrolled-key-using-mokutil-without-the-original-der)
を組み合わせて不要になった証明書を削除できます。
