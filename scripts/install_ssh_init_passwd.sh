#!/bin/bash

# 安装 OpenSSH 服务器
yum install -y openssh-server

# 启动 OpenSSH 服务
systemctl start sshd

# 设置 OpenSSH 开机自启动
systemctl enable sshd

# 修改 root 用户密码为 123456
echo "root:123456" | chpasswd

# 显示修改后的密码
echo "Root password changed to 123456"