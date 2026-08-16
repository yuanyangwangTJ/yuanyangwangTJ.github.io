---
title: opencv问题记录
date: 2024-06-19 18:14:57
categories:
    - Misc
tags: 
    - opencv
---

opencv在安装使用的过程中，有很多的问题出现，现记录如下：

# Linux python版本

<!-- more -->

下面讨论的安装环境为服务器版的Linux，并不带图形界面，将会尝试安装**python**版本的**opencv**，环境使用**conda**创建.

## 安装

python版opencv的安装有全局和局部的安装，全局使用Linux包管理器，比如`apt`等管理，此方式还未尝试，日后若有使用，再做记录，现讨论局部安装，即在conda环境下安装opencv。

使用`conda install`命令安装的opencv，在索引补全上存在问题（*conda测试安装版本为4.7，其他版本不保证*)，故**推荐使用pip**安装，命令如下：

```bash
$ pip install opencv-python
```

## FAQ

> opencv可不止一个坑！！！

> 这里先说结论：如果只需要使用opencv提供的算法等函数，并不调用显示查看的函数，上面的安装并没有问题，但是如果**在无GUI的Linux服务器**上尝试调用`imshow`等显示函数，会出现这些问题。**推荐的解决方式是放弃这个函数，使用其他方式，比如matplotlib等来查看。**否则，无异于浪费生命！

先使用一个简单的测试程序，验证opencv显示函数是否可以成功运行：

```python
import cv2
img = cv2.imread('./img.xxx', flags=1)
cv2.imshow('demo', img)
cv2.waitKey(0)
```

没有出现正常的图片显示，或者出现图片控制台输出有问题，继续如下：

### opencv-headless与contrib

脚本命令`python file.py`命令运行，出现下面问题：

```
OpenCV(4.9.0) /io/opencv/modules/highgui/src/window.cpp:1272: error: (-2:Unspecified error) The function is not implemented. Rebuild the library with Windows, GTK+ 2.x or Cocoa support. If you are on Ubuntu or Debian, install libgtk2.0-dev and pkg-config, then re-run cmake or configure script in function 'cvShowImage'
```

这是由于安装的opencv并非满血版本导致，可以尝试使用如下命令解决，[来源链接](https://stackoverflow.com/questions/67120450/error-2unspecified-error-the-function-is-not-implemented-rebuild-the-libra)：

```bash
pip uninstall opencv-python-headless -y
pip install opencv-python --upgrade
```

`opencv-python-headless`是**一个不带图形界面的版本的OpenCV**，它可以用来进行图像处理和计算机视觉任务，但是不能用来显示图像或视频，这也解释了为什么上面的代码会出现问题。

另外，结合[stackoverflow的回答](https://stackoverflow.com/questions/50783177/opencv-the-function-is-not-implemented-rebuild-the-library-with-windows/52575640#52575640)，也可以使用如下安装命令解决问题：

> **两个都是stackoverflow的认证回答，两者应该都是补充安装opencv其他部分**

```bash
pip install opencv-python
pip install opencv-contrib-python 
```

其中，`opencv-contrib`是加强版opencv，除了主模块，还包括一些增强模块以及测试的新算法，验证成熟之后，再加入主模块，算是有社区支持。

### QT报错

上面问题解决之后，再次运行程序，在无`X Forward`的终端下，错误信息应该会**再次升级**，出现`core dumped`，在vscode jupyter中，这个问题表现为`kernel dead`，脚本运行可能报错如下：

```
qt.qpa.xcb: could not connect to display 
qt.qpa.plugin: Could not load the Qt platform plugin "xcb" in "/opt/miniconda3/envs/CV/lib/python3.9/site-packages/cv2/qt/plugins" even though it was found.
This application failed to start because no Qt platform plugin could be initialized. Reinstalling the application may fix this problem.

Available platform plugins are: xcb, eglfs, minimal, minimalegl, offscreen, vnc, webgl.

Aborted (core dumped)
```

这个错误出现的原因很简单，无GUI的服务器怎么可能运行图形化的程序，解决方式是**开启X11转发**，可能需要服务器安装Gtk等，**实现转发最容易的方式是使用mobaxterm这种带有X11的软件**。

![image-20240619185113758](https://raw.githubusercontent.com/yuanyangwangTJ/Picture/master/img/202406191854572.png)

### QT版本兼容性

即使走到这一步，也依旧有可能遇到问题，程序可以运行，图像也显示，但是终端打印如下的信息：

```
QObject::moveToThread: Current thread (0x23f5ac0) is not the object's thread (0x24e4ca0).
Cannot move to target thread (0x23f5ac0)
```

搜索发现，这个问题是因为QT和opencv版本之间不兼容导致的，但是很遗憾，还未找到解决方案，网上有建议对opencv进行降级处理，但最终也没有找到合适的对应版本。

## opencv显示图片

既然使用`imshow`显示，是在浪费生命，那么下面给出可用的显示图片方案，[参考链接](https://stackoverflow.com/a/47821222)：

```python
img = cv2.imread('path_to_image')
# plt.imshow(img, cmap = 'gray', interpolation = 'bicubic')
plt.imshow(img)
plt.xticks([]), plt.yticks([])  # to hide tick values on X and Y axis
plt.show()
```

这样，便可以正常查看图片了，**有一种兜兜转转回原地的感觉**？！
