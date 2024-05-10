#!/bin/bash

# 文件名称
file_name=mysql84-community-release-el7-1.noarch.rpm

# 主要下载链接
main_url="https://repo.mysql.com//$file_name"
# 备用下载链接
backup_url="http://8.141.4.67/base/mysql/$file_name"
# 下载超时时间（秒）
timeout=10

#过渡密码
interim_password="Aew&de!23"

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

# 检查文件是否存在，如果不存在则退出
if [ ! -f "$file_name" ]; then
    echo "File not found. Exiting..."
    exit 1
fi

# 安装 MySQL Yum 存储库
yum localinstall -y $file_name

# 安装 yum-utils
yum install -y yum-utils

# 更新存储库缓存
yum makecache

# 禁用 mysql-8.4-lts-community 和 mysql-tools-8.4-lts-community 存储库
yum-config-manager --disable mysql-8.4-lts-community
yum-config-manager --disable mysql-tools-8.4-lts-community

# 启用 mysql80-community 和 mysql-tools-community 存储库
yum-config-manager --enable mysql80-community
yum-config-manager --enable mysql-tools-community

# 安装 MySQL 服务器
yum install -y mysql-community-server

# 启动 MySQL 服务
systemctl start mysqld

# 等待一段时间，确保 MySQL 服务已启动
sleep 10

# 输出临时密码
temp_password=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

# 修改密码为过渡密码
mysql -u root -p"$temp_password" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY $interim_password;"

# 修改 MySQL 密码验证等级为 LOW
mysql -u root -p"$interim_password" -e "SET GLOBAL validate_password.policy=LOW;"

#修改 MySQL 密码验证长度为6
mysql -u root -p"$interim_password" -e "SET GLOBAL validate_password.length=6;"

# 修改 MySQL 密码为 '123456'
mysql -u root -p"$interim_password" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';"

# 输出修改后的密码
echo "MySQL password has been changed to '123456'."

# 退出脚本
exit 0
