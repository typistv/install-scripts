#!/bin/bash

# 检查是否已经安装了NVM，如果已经安装则退出脚本
if command -v nvm &>/dev/null; then
    echo "NVM is already installed. Exiting."
    exit 0
fi

# 检查是否已经安装了wget，如果未安装则安装wget
if ! command -v wget &>/dev/null; then
    echo "wget is not installed. Installing wget..."
    # 安装wget
    if command -v apt-get &>/dev/null; then
        apt-get update
        apt-get install -y wget
    elif command -v yum &>/dev/null; then
        yum install -y wget
    else
        echo "Unsupported package manager. Please install wget manually."
        exit 1
    fi
fi

# 下载NVM
wget https://github.com/nvm-sh/nvm/archive/refs/tags/v0.39.7.tar.gz

# 解压缩NVM
tar -zxvf v0.39.7.tar.gz

# 移动解压后的文件夹到/root/.nvm
mv nvm-0.39.7 /root/.nvm

# 删除下载的压缩包
rm -rf v0.39.7.tar.gz

# 设置NVM的环境变量
nvm_variable="\nexport NVM_DIR="/root/.nvm"\n[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm\n[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion"
echo -e $nvm_variable >> /etc/profile

# 重新加载/etc/profile以使配置生效
source /etc/profile

echo "NVM installation completed."

