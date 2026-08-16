---
title: ssh密钥连接问题
date: 2024-01-11 11:37:49
categories:
    - Misc
tags: 
    - ssh
    - misc
---

# 密钥连接问题
在使用ssh连接时，注意到可以使用密码连接，但是密钥连接失效，如果下面命令连接：

<!-- more -->

```bash
ssh -o PasswordAuthentication=no user@hostname
```

出现`Permission denied (publickey,password)`错误，这个错误表明某处权限出现问题，但可惜我并未及时注意到。

# ssh调试
苦经尝试，终于发现一种[ssh调试](https://blog.csdn.net/wcjlyj/article/details/124148603)的方法，记录如下：

- 服务器端输入：
    ```bash
    sudo /usr/sbin/sshd -p 10022 -d
    ```

    `-d`表示开启调试模式。

- 客户端输入：
    ```bash
    ssh -v usename@ip -p 10022
    ```

这样，便可以详细输出连接细节，包括了详细的错误信息。

# 问题解决
经过调试发现，问题出现在`authorized_keys`文件的权限，虽然在此之前已经有博客说明这个问题，但并未重视，为此，需学习一下**Linux文件权限**的知识。当然，了解这种调试的思想更为宝贵，出现问题之后应该考虑**日志以及调试方法**。

最后，还有一个问题：**谁动了文件权限？！！**
