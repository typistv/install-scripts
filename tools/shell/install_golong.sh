#!/bin/bash
set -e  # 任何命令执行失败立即退出脚本

# 定义Go版本号和架构，方便修改
GO_VERSION="1.22.2"
GO_ARCH="linux-amd64"
GO_PACKAGE="go${GO_VERSION}.${GO_ARCH}.tar.gz"
GO_URL="https://mirrors.aliyun.com/golang/${GO_PACKAGE}"

# 检查是否已安装 wget
if ! command -v wget &> /dev/null; then
    echo "Error: wget is not installed. Installing wget..."
    yum install -y wget || { echo "Failed to install wget"; exit 1; }
fi

# 下载 Go 安装包
echo "Downloading Go ${GO_VERSION}..."
wget ${GO_URL} || { echo "Failed to download Go package"; exit 1; }

# 解压并安装 Go
echo "Installing Go ${GO_VERSION}..."
rm -rf /usr/local/go 
tar -C /usr/local -xzf ${GO_PACKAGE} || { echo "Failed to extract Go package"; exit 1; }
rm -rf ${GO_PACKAGE}

# 检查 /etc/profile 中是否已添加了 Go 的路径
if ! grep -q "/usr/local/go/bin" /etc/profile; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo "Go PATH added to /etc/profile"
fi

# 重新加载 /etc/profile
source /etc/profile

# 验证安装
if ! command -v go &> /dev/null; then
    echo "Error: Go installation verification failed"
    exit 1
fi

echo "Go ${GO_VERSION} installation completed successfully."
go version  # 显示安装的Go版本
