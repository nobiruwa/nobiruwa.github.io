---
title: Raspberry PiにDockerをインストールする
author: nobiruwa
tags: Docker, Raspberry Pi
---

## 切っ掛け

[mozilla/TTS](https://github.com/mozilla/TTS)が`pip install tts`だけではインストールできなかったため、有志が公開しているdockerイメージを使ってみたいと思いました。

手順は[How to Install Docker on Raspberry Pi](https://phoenixnap.com/kb/docker-on-raspberry-pi)を参考にしました。

## 手順

`get-docker.sh`をダウンロードします。

```console
$ curl -fsSL https://get.docker.com -o get-docker.sh
```

root権限で`get-docker.sh`を実行します。リポジトリの登録と、パッケージ(`docker-ce`, `docker-ce-cli`, `docker-ce-rootless-extras`)のインストールが行われます。

```console
$ sudo sh get-docker.sh
# Executing docker install script, commit: 93d2499759296ac1f9c510605fef85052a2c32be
Client: Docker Engine - Community
 Version:           20.10.8
 API version:       1.41
 Go version:        go1.16.6
 Git commit:        3967b7d
 Built:             Fri Jul 30 19:55:04 2021
 OS/Arch:           linux/arm
 Context:           default
 Experimental:      true

Server: Docker Engine - Community
 Engine:
  Version:          20.10.8
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.16.6
  Git commit:       75249d8
  Built:            Fri Jul 30 19:52:56 2021
  OS/Arch:          linux/arm
  Experimental:     false
 containerd:
  Version:          1.4.9
  GitCommit:        e25210fe30a0a703442421b0f60afac609f950a3
 runc:
  Version:          1.0.1
  GitCommit:        v1.0.1-0-g4144b63
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0

================================================================================

To run Docker as a non-privileged user, consider setting up the
Docker daemon in rootless mode for your user:

    dockerd-rootless-setuptool.sh install

Visit https://docs.docker.com/go/rootless/ to learn about rootless mode.


To run the Docker daemon as a fully privileged service, but granting non-root
users access, refer to https://docs.docker.com/go/daemon-access/

WARNING: Access to the remote API on a privileged Docker daemon is equivalent
         to root access on the host. Refer to the 'Docker daemon attack surface'
         documentation for details: https://docs.docker.com/go/attack-surface/

================================================================================
```

一般ユーザー権限で`dockerd-rootless.sh`を実行します。

```console
$ sudo apt install uidmap
$ dockerd-rootless.sh install
[INFO] Creating /home/pi/.config/systemd/user/docker.service
[INFO] starting systemd service docker.service
Created symlink /home/pi/.config/systemd/user/default.target.wants/docker.service → /home/pi/.config/systemd/user/docker.service.
[INFO] Installed docker.service successfully.
[INFO] To control docker.service, run: `systemctl --user (start|stop|restart) docker.service`
[INFO] To run docker.service on system startup, run: `sudo loginctl enable-linger pi`

[INFO] Creating CLI context "rootless"
Successfully created context "rootless"

[INFO] Make sure the following environment variables are set (or add them to ~/.bashrc):

export PATH=/usr/bin:$PATH
export DOCKER_HOST=unix:///run/user/1000/docker.sock
```

## インストール後

試しに[synesthesiam/docker-mozillatts](https://hub.docker.com/r/synesthesiam/mozillatts)を動作させます。

```console
$ docker run -it -p 5002:5002 synesthesiam/mozillatts:en
...
[INFO]  * Running on http://0.0.0.0:5002/ (Press CTRL+C to quit)
```
