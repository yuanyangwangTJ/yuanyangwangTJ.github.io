---
title: ssh反向代理实现内网穿透
date: 2024-08-03 10:18:07
tags:
- ssh
categories:
- SSH
- Misc
---

# ssh反向代理

> [ssh反向代理实现内网穿透；ssh+nginx实现公网云服务器代理访问内网服务器](https://blog.csdn.net/winter2121/article/details/116048685)
>
> [ssh反向代理实现内网穿透【亲测可用】](https://blog.csdn.net/liuxingyuzaixian/article/details/128705262)

<!-- more -->

为实现在公网环境访问内网服务器，现通过**ssh反向代理**的方式，并配置开机自启动服务，步骤如下：

# 内网服务器配置

## 创建启动脚本

```bash
sudo vim /usr/local/bin/reverse-ssh-tunnel.sh
```

内容如下，其中`public_user`表示公网服务器用户，`public_ip`表示公网服务器IP：

```bash
#!/bin/bash
ssh -CNR 7777:localhost:22 -o ServerAliveInterval=60 public_user@public_ip
```

如果手动启动，可以使用`ps aux | grep ssh`查看是否启动。

设置为可运行：

```bash
sudo chmod +x /usr/local/bin/reverse-ssh-tunnel.sh
```

## 创建`systemd`服务

```bash
sudo vim /etc/systemd/system/reverse-ssh-tunnel.service
```

内容如下，注意**用户名**等信息替换：

```
[Unit]
Description=Reverse SSH Tunnel
After=network.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/reverse-ssh-tunnel.sh
Restart=always
RestartSec=10
User=你的用户名
RemainAfterExit=yes
StartLimitIntervalSec=500
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
```

配置启动服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable reverse-ssh-tunnel.service
sudo systemctl start reverse-ssh-tunnel.service

sudo systemctl status reverse-ssh-tunnel.service
```

# 公网服务配置

对于公网服务器本身，可以不添加任何配置，登录公网服务器后，可以通过如下方式访问：

```bash
ssh secret_user@localhost -p 7777
```

当然也可以通过**跳板机**的方式登录访问，如果想要一次性直接访问，提供以下两种方式;

## 公网服务器正向代理

添加公网服务器正向代理，

```bash
ssh -fCNL *:7778:localhost:7777 -o ServerAliveInterval=60 public_user@localhost -p 22
```

上面配置的意思是让本机`7778`端口指向一个远端机器的`7777`端口，而这里的远端机器恰好就是公网服务器本身。当然，可以添加开机自启动服务，与上面类似。

访问如下：

```bash
ssh secret_user@public-ip -p 7778
```

## ssh配置修改

> https://www.ssh.com/academy/ssh/tunneling-example#remote-forwarding
>
> By default, OpenSSH only allows connecting to remote forwarded ports from the server host. 

上面是无法直接跨公网连接内网服务器的原因，可以修改ssh配置文件`/etc/ssh/sshd_config`中选项：

```
GatewayPorts yes
```

重启服务：

```bash
service sshd restart
```

不仅如此，**内网服务器脚本的内容需要允许任何IP地址机器访问**：

```bash
#!/bin/bash
ssh -CNR *:7777:localhost:22 -o ServerAliveInterval=60 public_user@public_ip
```

按照之前方式重启服务，这样就可以直接ssh登录访问了！

# 网络与服务重启

> [Systemd unit auto restart when network changes](https://unix.stackexchange.com/questions/725834/systemd-unit-auto-restart-when-network-changes)

在网络不稳定的情况下，需要重启服务，下面考虑使用`NetworkManager-dispatcher`服务来自动在网络波动情况下重启反向代理服务：

1. 开启`NetworkManager-dispatcher.service`

```bash
sudo systemctl enable --now NetworkManager-dispatcher.service
```

2. 查看网卡信息
3. 在`/etc/NetworkManager/dispatcher.d/`目录创建脚本，推荐以**数字开头**命名，表示级别，比如`10-reverse-ssh-tunnel-dispatcher.sh`，编辑内容如下：

```bash
#/bin/sh

# Scripts under '/etc/NetworkManager/dispatcher.d/' will have 
# two arguments ($1 and $2) which belong to the device or network interface
# and its status.

DEVICE=${1}
STATE=${2}

if [ "$DEVICE" = "wlo1" ]; then
   if [ "$STATE" = "up" ]; then
      systemctl restart reverse-ssh-tunnel.service
   fi
fi
```

这将会在网卡状态为`up`的情况下重启服务。当然，配置完成后重启`dispatcher`服务：

```bash
sudo systemctl daemon-reload
sudo systemctl restart NetworkManager-dispatcher.service
```
