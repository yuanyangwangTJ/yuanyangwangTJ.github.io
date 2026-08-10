---
title: conda和pip换源
date: 2024-03-04 10:55:57
tags: python
---

# Linux环境
## conda
配置文件`~/.condarc`:

```bash
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/pro
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud

```

查看已安装源：
```bash
conda config --show-sources
```

清除索引缓存：
```bash
conda clean -i
```

## pip
### 配置文件方式

修改配置文件`~/.pip/pip.conf`:
```bash
[global]
index-url = https://mirrors.bfsu.edu.cn/pypi/web/simple
format = columns
trusted-host = mirrors.bfsu.edu.cn
```

### 命令方式

临时使用：
```bash
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple some-package
```

永久更新（需pip>=10.0.0）：
```bash
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

这个方式会将配置写入文件`~/.config/pip/pip.conf`，尚未测试两种配置同时使用的效果。
