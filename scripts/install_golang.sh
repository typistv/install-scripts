#!/bin/bash

# 检查是否已安装 wget
if ! command -v wget &> /dev/null; then
    echo "Error: wget is not installed. Installing wget..."
    yum install -y wget
fi

# 下载 Go 安装包
wget https://mirrors.aliyun.com/golang/go1.22.2.linux-amd64.tar.gz

# 解压并安装 Go
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
rm -rf go1.22.2.linux-amd64.tar.gz

# 检查 /etc/profile 中是否已添加了 Go 的路径
if ! grep -q "/usr/local/go/bin" /etc/profile; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo "Go PATH added to /etc/profile"
fi

# 重新加载 /etc/profile
source /etc/profile

# 检查是否已安装 Go
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed. Please install Go manually."
    exit 1
fi


echo "Go installation completed successfully."

echo "Go设置国内代理"
go env -w GO111MODULE=on
go env -w  GOPROXY=https://goproxy.cn,direct

go env | grep GOPROXY