---
title: Docker与深度学习环境
date: 2024-07-23 22:32:13
categories:
  - Docker
tags:
  - docker
  - deep learning
---

# Docker

## 简介

<!-- more -->

Docker 镜像是一个描述容器如何运行的的文件，Docker 容器是 Docker 镜像在运行或被终止时的一个阶段。容器和主机上的其他文件是隔离的。当我们运行一个 Docker 容器的时候，它会使用一个被隔离出来的文件系统，这个文件系统是由一个 Docker 镜像提供的。Docker 镜像包含了运行应用程序所需要的一切东西——所有的依赖、配置、脚本、二进制文件等等。

## 安装

在ubuntu上安装docker，[官方安装教程](https://docs.docker.com/engine/install/ubuntu/)。

考虑国内网络问题，设置`apt`的时候可以使用其他源：

```bash
# 添加软件源GPG密钥
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 
```

```bash
# 向sources.list添加Docker软件源
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```bash
sudo apt update
```

## Docker Group

Docker Group是Linux系统中的一个用户组，其主要目的是为了方便管理员将普通用户加入到这个组中，从而赋予这些用户执行Docker命令的权限。当用户被添加到Docker Group后，他们就可以无需使用`sudo`命令来执行Docker命令，从而提高了操作效率。

默认情况下，Docker 在安装过程中会创建一个名为 docker 的用户组，用于管理 Docker 容器。

查看如下：

```bash
getent group docker
```

不存在可以创建：

```bash
sudo groupadd docker
```

将当前用户添加至用户组并更新：

```bash
sudo usermod -aG docker $USER
newgrp docker
```

如果未生效，可以退出当前终端并重新登录。

## Docker镜像加速

> [快速设置 Docker 的三种网络代理配置](https://blog.csdn.net/peng2hui1314/article/details/124267333)
>
> [官方代理配置文档](https://docs.docker.com/config/daemon/proxy/#httphttps-proxy)

### Docker Client

关于docker的镜像加速问题，**推荐使用代理方式，使用官方镜像**。以下为个人使用：

```bash
export https_proxy=http://127.0.0.1:7891 http_proxy=http://127.0.0.1:7891 all_proxy=socks5://127.0.0.1:7891
```

### Docker Daemon

但是这样做依旧不够，docker这个程序只是一个控制台程序，用于attach，真正操作docker的是运行在后台的docker daemon，也就是我们需要通过`systemctl start docker`来启动docker daemon。所以说即使我们设置了环境变量http_proxy，那么也只是针对前台docker console使用，而真正访问pull镜像的确是后台的daemon，因此，需要设置daemon访问proxy：

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo vim /etc/systemd/system/docker.service.d/http-proxy.conf
```

添加内容如下：

> HTTP_PROXY 用于代理访问 http 请求，HTTPS_PROXY 用于代理访问 https 请求，如果想某个 IP或域名不走代理则配置到 NO_PROXY中

```
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080/"
Environment="HTTPS_PROXY=http://proxy.example.com:8080/"
Environment="NO_PROXY=localhost,127.0.0.1,.example.com"
```

最后刷新重启：

```
sudo systemctl daemon-reload
sudo systemctl restart docker
```

命令可以简化为：

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/proxy.conf <<-'EOF'
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:7891"
Environment="HTTPS_PROXY=http://127.0.0.1:7891"
Environment="NO_PROXY=localhost,127.0.0.1,.example.com,10.0.0.0/8"
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

可以使用如下命令检测Docker有没有使用代理：

```bash
systemctl show --property=Environment docker
```

这里存在一个问题，考虑到Linux多用户情况，如果不同用户需要配置不同代理，目前并无法实现，目前发现的可能解决方案为使用`rootless docker`，但是安装配置比较繁琐，后续再探索。

### Docker Container

对于容器内部代理访问，因为本身容器就可以当作简化版系统，可以通过在容器内设置环境变量的方式，**但是并不推荐**，这里使用`Docker 17.07`以及更高版本的全局配置方式：

```bash
# 创建目录
mkdir ~/.docker
# 创建编辑配置文件
vim ~/.docker/config.json
```

添加内容：

```
{
 "proxies":
 {
   "default":
   {
     "httpProxy": "http://127.0.0.1:7891",
     "httpsProxy": "http://127.0.0.1:7891",
     "noProxy": "*.test.example.com,.example2.com,127.0.0.0/8"
   }
 }
}
```

重新启动docker：

```bash
sudo systemctl restart docker
```

# Docker深度学习项目环境

因为在多台机器上频繁部署深度学习环境，所以考虑使用Docker化深度学习环境和项目，目标是环境打包分享之后，只需要安装好显卡驱动就行。将其过程记录如下。

## 基础镜像

项目的基础镜像可以选择从nvidia/cuda进行构建，在此之上安装torch等，或者直接使用pytorch官方所提供的镜像，下面使用这种方式。

### 拉取镜像

```bash
docker pull pytorch/pytorch:2.3.1-cuda12.1-cudnn8-runtime
```

### 创建容器

```bash
docker run -it --gpus all --name dp-env --hostname docker-pc pytorch/pytorch:2.3.1-cuda12.1-cudnn8-runtime /bin/bash
```

可能出现的问题：

```
docker: Error response from daemon: could not select device driver "" with capabilities: [[gpu]]
```

这是因为没有安装`nvidia-docker`，安装按照[nvidia官方文档](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-apt)即可，完成之后重启docker服务。

## 使用容器

容器创建完成，后续便可以正常使用了，通过下面的命令直接进入交互模式：

```bash
docker start -i dp-env
```

经过测试发现，torch官方提供的基础环境中，系统为`ubuntu 22.04`，当然极其精简，可以安装将自己的环境个性化配置，保存为镜像，方便后续使用。

# Docker私有仓库

> [docker配置私有仓库](https://yeasy.gitbook.io/docker_practice/repository/registry)

考虑到Docker hub公有仓库部分不便性，我们现在使用`docker-registry`来构建私有的镜像仓库。具体参考[链接](https://yeasy.gitbook.io/docker_practice/repository/registry)即可。下面将配置命令记录：

```bash
docker run -d \
    -p 5000:5000 \
    -v /srv/docker-data/registry:/var/lib/registry \
    --restart=always --name registry registry
```

## Docker容器打包

现在将上面创建的深度学习项目容器打包并上传。

命令：`docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]`

options选项：

```
-a :提交的镜像作者；
-c :使用Dockerfile指令来创建镜像；
-m :提交时的说明文字；
-p :在commit时，将容器暂停。
```

```bash
docker commit -m "fisrt commit" dp-env torch-pc:0.1
```

## 私有仓库上传、搜索、下载

使用`docker tag`标记一个镜像，然后推送到它的仓库，格式为：

`docker tag IMAGE[:TAG] [REGISTRY_HOST[:REGISTRY_PORT]/]REPOSITORY[:TAG]`

```bash
docker tag torch-pc:0.1 registry.example.internal:5000/torch-pc:latest
```

使用 `docker push` 上传标记的镜像：

```bash
docker push registry.example.internal:5000/torch-pc:latest
```

这里因为是内网地址作为私有仓库地址，Docker 默认不允许非 `HTTPS` 方式推送镜像。我们可以通过 Docker 的配置选项来取消这个限制，在`/etc/docker/daemon.json`中配置如下：

```
{
  "insecure-registries": [
    "registry.example.internal:5000"
  ]
}
```

用`curl` 查看仓库中的镜像:

```bash
curl registry.example.internal:5000/v2/_catalog
```

```
{"repositories":["torch-pc"]}
```

先删除已有镜像，再尝试从私有仓库中下载这个镜像：

```bash
$ docker image rm registry.example.internal:5000/torch-pc:latest
$ docker pull registry.example.internal:5000/torch-pc:latest
$ docker image ls
```

# 其他

## 默认存储位置修改

> [修改docker的默认存储位置及镜像存储位置](https://www.cnblogs.com/JasonCeng/p/15728592.html)

Docker的默认存储位置为：`/var/lib/docker`，可以通过下面命令查看具体位置：

```shell
sudo docker info | grep "Docker Root Dir"
```

如果空间受限，最直接的方法是挂载分区到这个目录，考虑到管理需求，可以采用修改路径或者软连接的方式来实现。

首先停止Docker服务：

```bash
docker stop $(docker ps -aq)
sudo systemctl stop docker
```

移动目录并连接：

```bash
sudo mv /var/lib/docker /srv/docker-data/docker
sudo ln -s /srv/docker-data/docker /var/lib/docker
```

## 关于Docker用处

探索Docker的初衷是为了简化不同服务器之间环境的配置，但是发现即使使用Docker，**如果环境经常发生变动**，也很难拥有良好的体验。Docker也不推荐过度配置，使用ssh连接Docker虽然可行，但是又破环了Docker的设计理念，单纯使用Docker作为环境，对于开发时的自动补全等，体验有限，目前发现**Pycharm**可以加载镜像，或许结合`Dockerfile`可以获得不错的体验，当然需要将环境安装步骤写在`Dockerfile`中；而**vscode**提供了对于创建容器的连接方式，类似于远程开发。两种方式，孰优孰劣，很难论断。但无论如何，想要在一台空服务器上运行项目，Docker提供环境的方案还是值得一试。
