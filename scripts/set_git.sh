#!/bin/bash

# 检查是否已经安装了git，如果已经安装则退出脚本
# if command -v git &>/dev/null; then
#     echo "Git is already installed. Exiting."
#     exit 0
# fi

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

# 安装git
echo "Installing Git..."
if command -v apt-get &>/dev/null; then
    apt-get update
    apt-get install -y git
elif command -v yum &>/dev/null; then
    yum install -y git
else
    echo "Unsupported package manager. Please install git manually."
    exit 1
fi

# 配置git的用户信息
echo "Configuring Git..."
git_name="typistv"
git_email="typistchain@gmail.com"

git config --global user.name "$git_name"
git config --global user.email "$git_email"

echo "Git installation and configuration completed."
