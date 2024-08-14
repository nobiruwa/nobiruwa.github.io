---
title: SoftEtherによるVPNの導入
author: nobiruwa
tags: VPN, Linux, Raspberry Pi
---

## VPNサーバー (Raspberry Pi 4) のセットアップ

「SoftEther VPN」の`SecureNAT`が気になり、自宅で常に稼動しているRaspberry Pi 4をVPNサーバー化するセットアップを行いました。

### SecureNAT機能について

SecureNAT機能について理解するために、公式サイトの[3.7 仮想 NAT および仮想 DHCP サーバー](https://ja.softether.org/4-docs/1-manual/3/3.7)と、[VPNFAQ036. SecureNAT の動作モードにはどのような違いがありますか。](https://ja.softether.org/4-docs/3-kb/VPNFAQ036)を見る必要がありました。

FAQにあるように、SecureNAT起動時にDHCPサーバーへACK要求を行います。

> ## 利用モードの選択
> SecureNAT は仮想 NAT 機能の利用時に、ホスト OS に接続されたイーサネットインターフェイスと Raw IP ソケットで、 DHCP 要求を送信してみます。この DHCP 要求で IP アドレスを取得できたら、インターネット上の Web サーバーの名前解決が DNS で行えることと、解決された IP アドレスへの HTTP での接続が可能であることを確認します。全てに成功した場合のみ、そのインターフェイスが仮想 NAT の WAN 側として使用されます。イーサネットインターフェイスでの通信に成功した場合はカーネルモード SecureNAT が使用され、Raw IP ソケットでの通信に成功した場合は Raw IP モード SecureNAT が使用されます。いずれも成功しなかった場合はユーザモード SecureNAT が使用されます。

VPNサーバーのログ `/var/log/softether/server_log/vpn_yyyymmdd.log` に結果が記録されます。

```
yyyy-MM-dd HH:mm:ss.fff [HUB "vpn"] SecureNAT: It has been detected that the Kernel-mode NAT for SecureNAT can be run on the interface "eth0". The Kernel-mode NAT is starting. The TCP, UDP and ICMP NAT processings will be performed with high-performance via Kernel-Mode hereafter. The parameters of Kernel-mode NAT: IP Address = "<払い出されたIPアドレス>", Subnet Mask = "255.255.255.0", Default Gateway = "<デフォルトゲートウェイのIPアドレス>", Broadcast Address = "<ブロードキャストのIPアドレス>", Virtual MAC Address: "<仮想MACアドレス>", DHCP Server Address: "<DHCPサーバーのIPアドレス>", DNS Server Address: "<DNSサーバーのIPアドレス>"
```

DHCPサーバーのログを見ると、`Virtual MAC Address`の仮想MACアドレスにIPアドレスがリースされていました。

### 必要なパッケージのインストール

```console
# apt install softether-common softether-vpnserver softether-vpncmd
```

`softether-vpnserver.service`が自動起動されました。

なお、VPN Bridge接続をする場合は`softether-vpnbridge`も合わせてインストールする必要があります。

### ファイアウォールでのポート開放

VPN接続をするために、VPNサーバーの443/TCPポートへの接続を許可します。

[Allow web traffic in iptables software firewall - rackspace](https://docs.rackspace.com/support/how-to/allow-web-traffic-in-iptables/)を参考にしました。

```console
# iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
# iptables-save
```

### ルータの静的NAPT設定 (PR-500KI)

続いて、WAN側からVPNサーバーの443/TCPポートへ接続できるよう、ルータに静的NAPTによるルーティングを設定します。

自宅ではPR-500KIを使っており、この機器では、機器ごとに利用可能なWAN側ポートが制限されております。設定にあたっては[v6プラスでポートを開放する方法](v6プラスでポートを開放する方法)を参考にしました。

Raspberry PiにSSH接続し、ルータ設定用にインストールしておいたWebブラウザ(`midori`)を使って[配信済事業者ソフトウェア一覧](http://ntt.setup:8888/t)を開き、`IPv4設定`をクリックします。

[IPv4設定](http://ntt.setup:8888/enabler.ipv4/main)には`利用可能ポート`が列挙されており、静的NAPT設定に利用可能なポート番号を2つ選びます。

1つはSSL通信のためのポートです。

- 対象プロトコル
  - `TCP`を選択
- 公開対象ポート
  - `利用可能ポート`から選んだポート番号を入力(例: `12345`)
- 宛先アドレス
  - ルーターから払いだされたVPNサーバーのIPアドレス(例: `192.168.1.2`)
- 宛先ポート
  - VPNサーバーが使用するSSL通信ポートを入力(`443`)

もう1つはOpenVPN接続のポートです。

- 対象プロトコル
  - `TCP`を選択
- 公開対象ポート
  - `利用可能ポート`から選んだポート番号を入力(例: `23456`)
- 宛先アドレス
  - ルーターから払いだされたVPNサーバーのIPアドレスを入力(例: `192.168.1.2`)
- 宛先ポート
  - VPNサーバーが使用するOpenVPN通信ポート番号を入力(`1194`)

### 仮想HUBの作成

VPNサーバーの操作を`vpncmd`から行ってみました。

まずはVPNサーバーの管理パスワードの設定と仮想HUBの作成です。
仮想HUBの名前だけでなく仮想HUBのパスワードもここで決定します。

```console
# vpncmd
vpncmd command - SoftEther VPN Command Line Management Utility Developer Edition
SoftEther VPN Command Line Management Utility (vpncmd command)
Developer Edition
Version 5.01 Build 9674   (English)
Compiled 2020/12/03 09:35:09 by Unknown at Unknown
Copyright (c) all contributors on SoftEther VPN project in GitHub.
Copyright (c) Daiyuu Nobori, SoftEther Project at University of Tsukuba, and SoftEther Corporation.
All rights reserved.
5
By using vpncmd program, the following can be achieved.

1. Management of VPN Server or VPN Bridge
2. Management of VPN Client
3. Use of VPN Tools (certificate creation and Network Traffic Speed Test Tool)

Select 1, 2 or 3: 1 # 1を入力してEnter

Specify the host name or IP address of the computer that the destination VPN Server or VPN Bridge is operating on.
By specifying according to the format 'host name:port number', you can also specify the port number.
(When the port number is unspecified, 443 is used.)
If nothing is input and the Enter key is pressed, the connection will be made to the port number 443 of localhost (this computer).
Hostname of IP Address of Destination: # Enter

If connecting to the server by Virtual Hub Admin Mode, please input the Virtual Hub name.
If connecting by server admin mode, please press Enter without inputting anything.
Specify Virtual Hub Name: # Enter
Connection has been established with VPN Server "localhost" (port 443).

You have administrator privileges for the entire VPN Server.
VPN Server>ServerPasswordSet
ServerPasswordSet command - Set VPN Server Administrator Password
Please enter the password. To cancel press the Ctrl+D key.

Password: ****** # VPNサーバーの管理パスワードを入力してEnter
Confirm input: ****** # VPNサーバーの管理パスワードを再度入力してEnter

The command completed successfully.
VPN Server>HubCreate # 仮想HUBを作成するためにHubCreateコマンドを実行
HubCreate command - Create New Virtual Hub
Name of Virtual Hub to be created: vpn # 仮想HUB名に与える名前を入力してEnter

Please enter the password. To cancel press the Ctrl+D key.

Password: ****** # 仮想HUBのパスワードを入力してEnter
Confirm input: ****** # 仮想HUBのパスワードを再度入力してEnter

The command completed successfully.
VPN Server>exit
```

次に仮想HUBのSecureNATを有効にします。

```console
# vpncmd
vpncmd command - SoftEther VPN Command Line Management Utility Developer Edition
SoftEther VPN Command Line Management Utility (vpncmd command)
Developer Edition
Version 5.01 Build 9674   (English)
Compiled 2020/12/03 09:35:09 by Unknown at Unknown
Copyright (c) all contributors on SoftEther VPN project in GitHub.
Copyright (c) Daiyuu Nobori, SoftEther Project at University of Tsukuba, and SoftEther Corporation.
All rights reserved.

By using vpncmd program, the following can be achieved.

1. Management of VPN Server or VPN Bridge
2. Management of VPN Client
3. Use of VPN Tools (certificate creation and Network Traffic Speed Test Tool)

Select 1, 2 or 3: 1 # 1を選択してEnter

Specify the host name or IP address of the computer that the destination VPN Server or VPN Bridge is operating on.
By specifying according to the format 'host name:port number', you can also specify the port number.
(When the port number is unspecified, 443 is used.)
If nothing is input and the Enter key is pressed, the connection will be made to the port number 443 of localhost (this computer).
Hostname of IP Address of Destination: # Enter

If connecting to the server by Virtual Hub Admin Mode, please input the Virtual Hub name.
If connecting by server admin mode, please press Enter without inputting anything.
Specify Virtual Hub Name: vpn # 仮想HUBの名前を入力してEnter
Password: ********* # 仮想HUBのパスワードを入力してEnter

Connection has been established with VPN Server "localhost" (port 443).

You have administrator privileges for Virtual Hub 'vpn' on the VPN Server.

VPN Server/vpn>SecureNATEnable
SecureNatEnable command - Enable the Virtual NAT and DHCP Server Function (SecureNat Function)
The command completed successfully.

VPN Server/vpn>exit
```

### 外部からSoftEther VPN サーバー管理マネージャで設定を行う

次はインターネットからVPNサーバーに接続して残りの設定を行ってみます。

#### 接続の作成

`SoftEther VPN サーバー管理マネージャ`ウィンドウから`[新しい接続設定]`ボタンを選択します。

`新しい接続の作成`ダイアログでは以下のように設定しました。

- 設定名
  - `自宅`と入力
- VPN Server の指定
  - ホスト名
    - PR-500KIのWAN側のIPアドレスを入力
  - ポート番号
    - PR-500KIの静的NAPT設定で選んだポート番号を入力
- 経由するプロキシサーバーの設定
  - プロキシの種類
    - プロキシを必要としなかったため`直接 TCP/IP 接続 (プロキシを使わない)`を選択
- 管理モードの選択とパスワードの入力
  - `サーバー管理モード`を選択
- 管理パスワード
  - `ServerPasswordSet`で設定した管理パスワードを入力

`[OK]`ボタンを押すと`SoftEther VPN Server への接続設定`ダイアログに接続設定が追加されました。

#### VPN接続ユーザーの作成

仮想HUBのVPN接続ユーザーを作成します。

`SoftEther VPN サーバー管理マネージャ`ウィンドウで接続設定`自宅`を選択した状態で`[接続]`ボタンを押して接続に成功すると、`自宅 - SoftEther VPN サーバー管理マネージャ`ダイアログが開きます。

仮想HUB`vpn`を選択した状態で`[仮想 HUB の管理]`ボタンを押して、`仮想 HUB の管理 - vpn`ダイアログを開きます。

`[ユーザーの管理]`ボタンを押して、`ユーザーの管理`ダイアログを開きます。

`[新規作成]`ボタンを押して、`ユーザーの新規作成`ダイアログを開きます。グループ参加なし、パスワード認証を行うユーザーを作成します。

- ユーザー名
  - アルファベットで任意の名称を入力
- 本名
  - 任意の名前を入力
- 説明
  - 任意の説明を入力
- グループ名
  - 空文字列のまま入力を省略
- 認証方法
  - パスワード認証
- パスワード認証
  - パスワード
    - パスワードを入力
  - パスワードの確認入力
    - パスワードを入力

`[OK]`ボタンを押すと、`ユーザーの管理`ダイアログにユーザーが追加されます。

#### IPsec/L2TPの設定

IPsec/L2TP自体は使用しませんが、後述するOpenVPNのための設定を行います。

`自宅 - SoftEther VPN サーバー管理マネージャ`ダイアログで`[IPsec / L2TP 設定]`ボタンを押して、`IPsec / L2TP / L2TPv3 設定`ダイアログを開きます。

`接続時のユーザー名で仮想 HUB 名が省略された場合に接続する仮想 HUB の選択`で`vpn`を選択します。

`[OK]`ボタンを押して`IPsec / L2TP / L2TPv3 設定`ダイアログを閉じます。

#### OpenVPNの設定

AndroidではIPsec/L2TPは使えずOpenVPNを使用します。そのための設定を行います。

`自宅 - SoftEther VPN サーバー管理マネージャ`ダイアログで`[OpenVPN / MS-SSTP 設定]`ボタンを押して、`OpenVPN / MS-SSTP 設定`ダイアログを開きます。

- `OpenVPN サーバー機能を有効にする`
  - チェックボックスを有効にします。
- `[OpenVPN クライアント用のサンプル設定ファイルを生成]`ボタンを押して、zipファイルをダウンロードします。

`[OK]`ボタンを押して`OpenVPN / MS-SSTP 設定`ダイアログを閉じます。

## VPNクライアントのセットアップ (Windows)

`SoftEther VPN クライアント接続マネージャ`を使って、VPNサーバーに接続します。

### 仮想VLANカードの作成

`[新しい接続設定の作成]`を選択すると、初めに`新しい仮想 LAN カードの作成`ダイアログが表示されます。`仮想 LAN カードの名前`に適当な名称(例: `VPN`)を入力し`[OK]`ボタンを押します。

### 新しい接続設定の作成

`[新しい接続設定の作成]`を選択して`新しい接続設定のプロパティ`ダイアログを開きます。

VPNサーバーの設定に合わせて以下の通り入力します。

- 接続設定名
  - 任意の名称を入力 (例: `VPN Client`)
- 接続先 VPN Server の指定
  - ホスト名
    - PR-500KIのWAN側のIPアドレスを入力
  - ポート番号
    - PR-500KIの静的NAPT設定で選んだポート番号を入力(`443`)
  - 仮想 HUB 名
    - 作成した仮想HUBの名前を選択 (`vpn`)
- 経由するプロキシサーバーの設定
  - プロキシを必要としなかったため`直接 TCP/IP 接続 (プロキシを使わない)`を選択
- サーバー証明書の検証のオプション
  - 設定を省略
- 使用する仮想 LAN カード
  - 作成した仮想LANカードを選択
- ユーザー認証
  - 認証の種類
    - 標準パスワード認証
  - ユーザー名
    - `ユーザーの管理`で作成したユーザーのユーザー名を入力
  - パスワード
    - `ユーザーの管理`で作成したユーザーのパスワードを入力

`[OK]`ボタンを押すと、`SoftEther VPN クライアント接続マネージャ`ウィンドウに接続設定が追加されました。

## 接続 (Windows)

`SoftEther VPN クライアント接続マネージャ`ウィンドウで接続設定をダブルクリックすると接続が試行されます。接続に成功すると`状態`が`接続完了`と表示されます。

## 接続 (Android)

### OpenVPN設定ファイルの作成

`SoftEther VPN サーバー管理マネージャ`の`OpenVPN / MS-SSTP 設定`ダイアログからダウンロードしたzipファイルから`<VPNサーバーホスト名>_openvpn_remote_access_l3.ovpn`を取り出し、以下のように変更します。

```diff
@@ -60,7 +60,7 @@
 #
 # Specify either 'proto tcp' or 'proto udp'.
 
-proto udp
+proto tcp
 
 
 ###############################################################################
@@ -86,7 +86,7 @@
 #       the Dynamic DNS hostname, replace it to either IP address or
 #       other domain's hostname.
 
-remote <VPNサーバーの管理番号>.v4.softether.net 1194
+remote <VPNサーバーの管理番号>.v4.softether.net <静的NAPT設定でOpenVPN通信用に割り当てたWAN側ポート番号>
 
 
 ###############################################################################
```

### Android端末のOpenVPNセットアップ

`<VPNサーバーホスト名>_openvpn_remote_access_l3.ovpn`をAndroid端末のストレージにコピーしておきます。

AndroidOpenVPNクライアントをインストールします。

`Import Profile`で`<VPNサーバーホスト名>_openvpn_remote_access_l3.ovpn`を選択して`[IMPORT]`ボタンを押します。

`Username`には仮想HUBのユーザー名称を入力します。`Save password`チェックボックスを有効にして、`Password`にパスワードを入力して、`[ADD]`ボタンを押します。

インポートしたプロファイルをタップすると接続が試行され、成功すればVPN接続が開始されます。

## Linux端末

VPNサーバーを動かしているRaspberry Pi 4もVPNクライアントとしてVPN接続することで、Raspberry Pi 4のWebサーバーにも接続できるようにします。

試行錯誤を繰り返したので順序は正しくない可能性があります。

まずは必要なパッケージをインストールします。

```console
# apt install softether-vpnclient
```

`vpncmd`を使って(localhostの)VPNクライアントをセットアップします。

仮想NIC`vpn0`と仮想HUB`vpn`を接続するアカウント`vpnconn`を作成します。


```console
$ vpncmd /client
Hostname of IP Address of Destination: # Enter

Connected to VPN Client "localhost".

VPN Client>NicCreate vpn0
NicCreate command - Create New Virtual Network Adapter
The command completed successfully.

VPN Client>AccountCreate vpnconn /SERVER:<VPNサーバーのIPアドレス>:443 /HUB:vpn /USERNAME:<仮想HUBのユーザー名称> /NICNAME:vpn0
AccountCreate command - Create New VPN Connection Setting
The command completed successfully.

VPN Client>NicList
NicList command - Get List of Virtual Network Adapters
Item                        |Value
----------------------------+-----------------------------------
Virtual Network Adapter Name|vpn0
Status                      |Enabled
MAC Address                 |5EE40FF922AC
Version                     |Version 5.01 Build 9674   (English)
The command completed successfully.
```

作成したアカウントが仮想HUB`vpn`に作成したユーザーを用いて接続すよう、ユーザー名とパスワードを設定します。

```console
VPN Client>AccountUsernameSet vpnconn
AccountUsernameSet command - Set User Name of User to Use Connection of VPN Connection Setting
Connecting User Name: <ユーザー名> # `ユーザーの管理`で作成したユーザーのユーザー名を入力

The command completed successfully.

VPN Client>AccountPasswordSet vpnconn
AccountPasswordSet command - Set User Authentication Type of VPN Connection Setting to Password Authentication
Please enter the password. To cancel press the Ctrl+D key.

Password: ****** # `ユーザーの管理`で作成したユーザーのパスワードを入力
Confirm input: ****** # `ユーザーの管理`で作成したユーザーのパスワードを入力


Specify standard or radius: standard

The command completed successfully.
VPN Client>exit
```

`vpncmd`で接続します。

```console
VPN Client>AccountConnect vpnconn
AccountConnect command - Start Connection to VPN Server using VPN Connection Setting
The command completed successfully.
```

`AccountStatusGet`コマンドでアカウントの状態を確認してください。

```console
VPN Client>AccountStatusGet vpnconn
AccountStatusGet command - Get Current VPN Connection Setting Status
Item                                      |Value
------------------------------------------+-------------------------------------------------------------
VPN Connection Setting Name               |vpnconn
Session Status                            |Connection Completed (Session Established)
VLAN ID                                   |-
Server Name                               |<IPアドレス>
Port Number                               |TCP Port 443
Server Product Name                       |SoftEther VPN Server Developer Edition (32 bit) (Open Source)
...[snip]...
The command completed successfully.
```

セッションが確立していない場合は、`AccountCreate`、`AccountUsernameSet`、`AccountPasswordSet`の設定を再度実行してください。

また、クライアント側のログ`/var/log/softether/client_log/client_YYYYmmdd.log`と、サーバー側のログ`/var/log/softether/server_log/vpn_YYYYmmdd.log`に接続失敗の理由が記載されているかを確認してください。

`AccountStatusGet`コマンドでセッションが確立されていることを確認したら、最後に仮想DHCPサーバーからIPアドレスを取得するために`dhcpcd`コマンドを実行してください。

```console
# dhcpcd vpn_vpn0 # サーバー用途の場合は静的割り当てのほうがよい
```

ただし、Raspberry Pi 4はサーバー用途であるため、`dhcpcd`コマンド(`dhcpcd-base`パッケージが必要です)を実行するかわりにIPアドレスの静的割り当てとルーティング設定を行います。

仮想DHCPサーバーの管理外のIPアドレスを割り当てます。

```console
# ip addr add 192.168.30.2/24 dev vpn_vpn0
# ip route add 192.168.30.0/24 via 192.168.30.2 dev vpn_vpn0
```

## Raspberry Pi 4でのVPN接続自動化

Raspbery Pi 4の起動時、前節のVPN接続が自動で行われるようにします。

`/home/pi/bin/vpn0-start.sh`、`/home/pi/bin/vpn0-stop.sh`、`/home/pi/.config/systemd/system/user/vpn0.service`を作成します。内容はそれぞれ以下の通りです。

### `/home/pi/bin/vpn0-start.sh`

```bash
#!/usr/bin/env bash

# SoftEther
vpncmd /client localhost /cmd AccountConnect vpnconn

# Network
DEVICE_NAME=vpn_vpn0
ADDRESS=192.168.30.2
MASK=24 
NETWORK_ADDRESS=192.168.30.0/24

sudo ip addr add ${ADDRESS}/${MASK} dev ${DEVICE_NAME}

sudo ip route add ${NETWORK_ADDRESS} via ${ADDRESS} dev ${DEVICE_NAME}

exit 0
```

### `/home/pi/bin/vpn0-stop.sh`

```bash
#!/usr/bin/env bash

# Network
DEVICE_NAME=vpn_vpn0
ADDRESS=192.168.30.2
MASK=24
NETWORK_ADDRESS=192.168.30.0/24

routes=`ip route | egrep ${DEVICE_NAME}`

while IFS= read -r line
do
  if [[ $line =~ ([0-9\.\/]+) ]]; then
    network_address=${BASH_REMATCH[1]}
    echo delete route ${network_address}
    sudo ip route delete ${network_address}
  fi
done <<< "$routes"

sudo ip addr del ${ADDRESS}/${MASK} dev ${DEVICE_NAME}

# SoftEther
vpncmd /client localhost /cmd AccountDisconnect vpnconn

exit 0
```

### `/home/pi/.config/systemd/system/user/vpn0.service`

```systemd-unit
[Unit]
Description=assign a static ip address to the softether client.
After=softether-vpnserver.service softether-vpnclient.service

[Service]
Type=oneshot
ExecStart=/home/pi/bin/vpn0-start.sh
ExecStop=/home/pi/bin/vpn0-stop.sh
TimeoutStopSec=5
RemainAfterExit=yes

[Install]
WantedBy=default.target
```

### サービスの有効化

```bash
systemctl --user daemon-reload
systemctl --user enable vpn0.service
```

## 参考文献

- [v6プラスでポートを開放する方法](v6プラスでポートを開放する方法)
  - PR-500KIでの静的NAPT設定の手順を説明してくれています。
- [Allow web traffic in iptables software firewall - rackspace](https://docs.rackspace.com/support/how-to/allow-web-traffic-in-iptables/)
  - `iptables`コマンドの使い方の説明があります。
- [SoftEther_VPN の vpncmd の使い方](https://qiita.com/ekzemplaro/items/47f2d1b88f80e01b403d)
  - `vpncmd`を使ったVPNクライアント接続の手順です。
- [Linuxmania:SoftEtherでVPN環境を作ろう](https://www.linuxmania.jp/softether-vpn.html)
  - `vpncmd`を使ったVPNクライアント接続の手順です。
- [Raspberry Pi に SoftEther_VPN Client をインストール](https://qiita.com/ekzemplaro/items/57b13994fbd1b5e3c286)
  - `vpncmd`を使ったVPNクライアント接続の手順です。
- [SoftEther で L2TP/IPsec から OpenVPN に切り替えてみた](https://blog.oyasu.info/2021/08/17/8244/)
  - Android端末ではOpenVPNサーバー機能を使えばよいことと、その設定方法が詳しくかかれていました。
- [AndroidのOpenVPN接続設定（v3.0.0以降）　■セカイVPN■ ](https://faq.interlink.or.jp/faq2/View/wcDisplayContent.aspx?id=701)
  - Android端末でのOpenVPN接続設定の手順が分かりやすく説明されていました。
- [3.7 仮想 NAT および仮想 DHCP サーバー](https://ja.softether.org/4-docs/1-manual/3/3.7)
  - SecureNAT機能の説明があります。
- [VPNFAQ036. SecureNAT の動作モードにはどのような違いがありますか。](https://ja.softether.org/4-docs/3-kb/VPNFAQ036)
  - SecureNATが動作モードを決定するためにDHCPサーバー、DNSサーバー、HTTPサーバーと通信を行うとの説明があります。
- [SoftEther VPN connects every minute to Yahoo.com](https://www.vpnusers.com/viewtopic.php?t=7716)
  - SecureNAT動作モードを決定する際のDNS名前解決とHTTP通信にyahoo.comが用いられているという回答があります。
- [DHCP_Client - Debian Wiki](https://wiki.debian.org/DHCP_Client)
  - `dhclient`コマンドの代替コマンドとして`dhcpcd`が挙げられています。
