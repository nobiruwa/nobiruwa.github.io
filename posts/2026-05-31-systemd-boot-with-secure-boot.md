---
title: UEFIセキュアブート環境におけるGRUBからsystemd-bootへの移行
author: nobiruwa
tags: Secure Boot, Dual Boot, GRUB, Systemd, Systemd-Boot
---

## 切っ掛け

2026年5月にセキュアブートの証明書を更新するWindows Updateを行ってから、GRUBからWindows 11を起動することが出来なくなりました。  
この問題を解消しようと調べ物をしていたなかでsystemd-bootの存在を知り、試してみることにしました。

## 最終的な起動時の構成

[Boot Loader Specification](https://www.freedesktop.org/wiki/MatthewGarrett/BootLoaderSpec/) (BLS) のうち、 Type #1 構成を選びました。

チェーンロードの関係は以下のようになります。

```plain
UEFI
  ↓
/boot/efi/EFI/debian/shimx64.efi (Signed by Microsoft UEFI CA 2023)
  ↓
/boot/efi/EFI/systemd-bootx64.efi (Signed by Debian Secure Boot CA)
  ↓
/boot/efi/loader/entries/(マシンID)-(カーネルバージョン)-(アーキテクチャ).conf
  ↓
/boot/efi/(マシンID)/(カーネルバージョン)-(アーキテクチャ)/linux
  +
/boot/efi/(マシンID)/(カーネルバージョン)-(アーキテクチャ)/initrd.img-(カーネルバージョン)-(アーキテクチャ)
```

自前の鍵(KEK/DB, etc.)を用意してshimを使わないようにしたり、Type #2構成でsystemd-bootからUKIを起動するようにしたり、といったいくつかのバリエーションがあるようですが面倒なので採用しませんでした。

上記のブートをデフォルトとし、Windows 11を起動したい場合はUEFIのブートメニューを使うようにしました。

## 構築手順

色々と試したので正確な構築手順を理解できていませんが、おそらく以下のコマンドにより完了してしまうのでは。

```bash
# apt install --allow-remove-essential systemd-boot-efi-amd64-signed systemd-boot grub-efi-amd64-signed-
```

## 注意点

### systemd-bootx64.efiが署名されていること

systemd-boot-efi-amd64パッケージのefiファイルがESPパーティションにコピーされた場合、systemd-bootx64.efiは未署名であるためセキュアブートを有効にしたマシンでは起動に失敗します。

#### systemd-bootx64.efiの確認と修正

正しい状態は以下の通りです。

```bash
# diff /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/efi/EFI/systemd/systemd-bootx64.efi
Binary files /usr/lib/systemd/boot/efi/systemd-bootx64.efi and /boot/efi/EFI/systemd/systemd-bootx64.efi differ
# diff /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed /boot/efi/EFI/systemd/systemd-bootx64.efi
```

もし未署名のsystemd-bootx64.efiがコピーされた場合は、systemd-boot関連のパッケージを再設定します。

```bash
# mv /boot/efi/EFI/systemd/systemd-bootx64.efi /tmp
# dpkg-reconfigure systemd-boot
Created directory "/boot/efi/EFI".
Created directory "/boot/efi/EFI/systemd".
Created directory "/boot/efi/EFI/BOOT".
Created directory "/boot/efi/loader".
Created directory "/boot/efi/loader/keys".
Created directory "/boot/efi/loader".
Created directory "/boot/efi/loader/entries".
Created directory "/boot/efi/EFI".
Created directory "/boot/efi/EFI/Linux".
Copied "/usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed" to "/boot/efi/EFI/systemd/systemd-bootx64.efi".
Copied "/usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed" to "/boot/efi/EFI/BOOT/BOOTX64.EFI".
Created directory "/boot/efi/e714167f6abc424f8496f8921afb8d7f".
Random seed file /boot/efi/loader/random-seed successfully refreshed (32 bytes).
Updated EFI boot entry "Linux Boot Manager".
Updated EFI boot entry "Fallback Linux Boot Manager".
```

### shimx64.efi経由でsystemd-bootx64.efiを起動すること

ブートメニューからLinux Boot Managerを選択しても起動に失敗します。systemd-bootをセットアップするとshim64.efi経由でsystemd-bootx64.efiを起動するDebianというエントリが作られますので、そちらをデフォルトのブートローダーとして設定しておきます。

```bash
# efibootmgr -u
BootCurrent: 000A
Timeout: 1 seconds
BootOrder: 000A,0000,0002,0001,0003,0004
Boot0000* Windows Boot Manager	HD(1,GPT,feb4246b-0490-4823-8219-a4198ebab99e,0x800,0x82000)/\EFI\MICROSOFT\BOOT\BOOTMGFW.EFI䥗䑎坏S
Boot0001* Linux Boot Manager	HD(1,GPT,feb4246b-0490-4823-8219-a4198ebab99e,0x800,0x82000)/\EFI\SYSTEMD\SYSTEMD-BOOTX64.EFI
Boot0002* debian	HD(1,GPT,feb4246b-0490-4823-8219-a4198ebab99e,0x800,0x82000)/\EFI\DEBIAN\SHIMX64.EFI
Boot0003* UEFI: PXE IPv4 Intel(R) Ethernet Connection (14) I219-V	PciRoot(0x0)/Pci(0x1f,0x6)/MAC(a8a1597e4880,0)/IPv4(0.0.0.0,0,DHCP,0.0.0.0,0.0.0.0,0.0.0.0)
Boot0004* UEFI: PXE IPv6 Intel(R) Ethernet Connection (14) I219-V	PciRoot(0x0)/Pci(0x1f,0x6)/MAC(a8a1597e4880,0)/IPv6([::],0,Static,[::],[::],64)
Boot0005* Fallback Linux Boot Manager	HD(1,GPT,feb4246b-0490-4823-8219-a4198ebab99e,0x800,0x82000)/\EFI\systemd\systemd-boot-fallbackx64.efi
Boot0006* Fallback Linux Boot Manager	VenHw(99e275e7-75a0-4b37-a2e6-c5385e6c00cb)
Boot0007* Fallback Linux Boot Manager	VenHw(99e275e7-75a0-4b37-a2e6-c5385e6c00cb)
Boot000A* Debian	HD(1,GPT,feb4246b-0490-4823-8219-a4198ebab99e,0x800,0x82000)/EFI\DEBIAN\SHIMX64.EFI\EFI\systemd\systemd-bootx64.efi \0
```

## 参考

- [Boot Loader Specification](https://www.freedesktop.org/wiki/MatthewGarrett/BootLoaderSpec/)
- [Supported architectures and packages - SecureBoot - Debian Wiki](https://wiki.debian.org/SecureBoot#Supported_architectures_and_packages)
- [Secure Boot setup with systemd-boot - SecureBoot - Debian Wiki](https://wiki.debian.org/SecureBoot#Secure_Boot_setup_with_systemd-boot)

最終的に採用しなかったものの、UKIについても参考にしました。

- [UKI - Debian Wiki](https://wiki.debian.org/UKI)

