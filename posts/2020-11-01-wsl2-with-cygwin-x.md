---
author: nobiruwa
title: Cygwin/XでWSL2のXアプリケーションを表示する
tags: wsl2, cygwin, cygwin-x, x11
---

## tl;dr

WSL2の起動スクリプト(manではinitialization file)に以下の設定を追加します。

```bash
# X configuration
export DISPLAY=`grep -oP "(?<=nameserver ).+" /etc/resolv.conf`:0.0

# Cygwin X Server authentication (requires cygwin's "xhost" package)
CYGWIN_ROOT="/mnt/c/cygwin64"
CYGWIN_XHOST="$CYGWIN_ROOT/bin/xhost.exe"
IP_ADDR=`ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1`
if [ -f "$CYGWIN_XHOST" ] ; then
    ${CYGWIN_XHOST} +${IP_ADDR}
fi
```

## 背景

LinuxマシンでのEmacsは長らくurxvt + emacs-noxという構成で使っていましたが、[emacs-lsp](https://github.com/emacs-lsp)をGUIで使いたいと思い、GTK版のEmacsに移行しました。これに合わせるために、X接続を[Cygwin/X](https://x.cygwin.com/)で実現することにしました。

インターネット上には[VcXsrv](https://sourceforge.net/projects/vcxsrv/)で表示する方法については色々と情報があるのですが、ウィンドウサイズが10行分しかない状態で起動するのと突然ウィンドウが落ちるので使用を断念しました。ただVcXsrvに関する情報には、アクセスコントロールを無効にする直接のX描画(つまりSSHのX11 port forwardingを使わない)であれば表示できるとあり、Cygwin/Xの設定の参考にします。

## 前提条件

- Windows
  - WSL2を起動するとネットワークアダプタ`vEthernet (WSL)`が生成される。
  - `XWin.exe`のTCP受信がファイアウォールで許可されている。または`6000/TCP`の受信が許可されている。
- Cygwin
  - Cygwinは`C:\cygwin64`にインストールしてある。
  - Cygwin/Xを[Cygwin/X User's Guide Chapter 2. Setting Up Cygwin/X](https://x.cygwin.com/docs/ug/setup.html)に従ってインストールしてある。
  - Cygwinに`xhost`パッケージをインストールしてある。
  - Cygwin/Xを起動するときの画面番号は`0`とする。
  - Cygwinの`DISPLAY`環境変数は`:0`とする。
- WSL2
  - `bash`がログインシェルとして使われている。
  - `eth0`がホスト側のネットワークアダプタ`vEthernet (WSL)`に対応している(おそらくデフォルト)。

上記前提条件のうち、技術的要件は以下の2つです。

- `XWin.exe`のTCP受信がファイアウォールで許可されている。または`6000/TCP`の受信が許可されている。
- Cygwinに`xhost`パッケージをインストールしてある。

ほかの2つは既定の設定であるか、環境に関する決めの問題です。

## アイディア

Cygwin側で`xhost +`とすればアクセスコントロールを無効にできますが、もう少しセキュアな設定にしたいです。`xhost +<WSL2のIPアドレス>`によってWSL2にのみ許可を与えることにします。

1. Cygwin側は`xhost`に与える`<WSL2のIPアドレス>`を知る必要がある。
2. WSL2側は`DISPLAY`環境変数にセットするホスト側のIPアドレスを知る必要がある(ディスプレイ番号は`0`決め打ちとした)。

WindowsとWSL2との間の仮想ネットワーク`vEthernet (WSL)`はWSL2の起動時になって生成され、それまではWSL2のIPアドレスもホスト側のIPアドレスも決定されません。よって、WSL2の起動後に上記2点の設定ができるようになります。

1についてはWSL2側の`ip addr`の出力の加工で取得できますし、2についても[Can't use X-Server in WSL 2 #4106](https://github.com/microsoft/WSL/issues/4106)で議論されている通り、`/etc/resolv.conf`から取得することができます。または[WSL2の中のX clientから VcXsrv に xauth で接続したい](https://ja.stackoverflow.com/questions/66736/wsl2%E3%81%AE%E4%B8%AD%E3%81%AEx-client%E3%81%8B%E3%82%89-vcxsrv-%E3%81%AB-xauth-%E3%81%A7%E6%8E%A5%E7%B6%9A%E3%81%97%E3%81%9F%E3%81%84)にあるように、`<マシン名>.mshome.net`をホスト名とすることができます。CygwinのコマンドはWSL2からも実行することができるので、1と2の両方の設定もWSL2の起動スクリプトから行えます。

ここまでを踏まえ、以下の設定(再掲)としました。

```bash
# X configuration
export DISPLAY=`grep -oP "(?<=nameserver ).+" /etc/resolv.conf`:0.0

# Cygwin X Server authentication (requires cygwin's "xhost" package)
CYGWIN_ROOT="/mnt/c/cygwin64"
CYGWIN_XHOST="$CYGWIN_ROOT/bin/xhost.exe"
IP_ADDR=`ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1`
if [ -f "$CYGWIN_XHOST" ] ; then
    ${CYGWIN_XHOST} +${IP_ADDR}
fi
```
