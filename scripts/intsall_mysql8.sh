#!/bin/bash

# 文件名称
file_name=mysql84-community-release-el7-1.noarch.rpm

# 主要下载链接
main_url="https://repo.mysql.com//$file_name"
# 备用下载链接
backup_url="http://8.141.4.67/base/mysql/$file_name"
# 下载超时时间（秒）
timeout=10

echo "Attempting to download from main URL..."
if curl --output /dev/null --silent --head --fail --max-time $timeout "$main_url"; then
    echo "Downloading from main URL..."
    curl -O --max-time $timeout "$main_url"
else
    echo "Main URL timed out, switching to backup URL..."
fi

# 尝试下载备用链接
if [ ! -f "$file_name" ]; then
    echo "Attempting to download from backup URL..."
    if curl --output /dev/null --silent --head --fail --max-time $timeout "$backup_url"; then
        echo "Downloading from backup URL..."
        curl -O --max-time $timeout "$backup_url"
    else
        echo "Backup URL timed out as well. Unable to download the file."
        exit 1
    fi
fi

# 添加 MySQL Yum 存储库
yum localinstall $file_name

yum-config-manager --disable mysql-8.4-lts-community
yum-config-manager --disable mysql-tools-8.4-lts-community

yum-config-manager --enable mysql80-community
yum-config-manager --enable mysql-tools-community

yum install mysql-community-server

systemctl start mysqld

grep 'temporary password' /var/log/mysqld.log
