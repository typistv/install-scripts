#!/bin/bash

# 文件名称
file_name=go1.16.15.linux-amd64.tar.gz

# 主要下载链接
main_url="http://192.168.9.140/golang/$file_name"
# 备用下载链接
backup_url="https://studygolang.com/dl/golang/$file_name"
# 下载超时时间（秒）
timeout=10

# 函数：从主要或备用链接下载文件
download_file() {
    local url="$1"
    echo "Attempting to download from $url..."
    if curl --output /dev/null --silent --head --fail --max-time $timeout "$url"; then
        echo "Downloading from $url..."
        curl -O --max-time $timeout "$url"
    else
        echo "$url timed out. Unable to download the file."
        return 1
    fi
}

# 下载文件
download_file "$main_url" || download_file "$backup_url"

# 解压并安装 Go
rm -rf /usr/local/go && tar -C /usr/local -xzf $file_name
rm -rf $file_name

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