#!/bin/bash

# 文件名称
file_name=mysql84-community-release-el7-1.noarch.rpm

# 主要下载链接
main_url="https://repo.mysql.com//$file_name"
# 备用下载链接
backup_url="http://8.141.4.67/base/mysql/$file_name"
# 下载超时时间（秒）
timeout=10

# 过渡密码
interim_password="Aew&de!23"

# 新密码
new_password="123456"

# 外部访问允许的 IP 地址，如果允许所有 IP 访问，可设置为 '0.0.0.0'
bind_address="0.0.0.0"

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

# 检查文件是否存在，如果不存在则退出
if [ ! -f "$file_name" ]; then
    echo "File not found. Exiting..."
    exit 1
fi

# 安装 MySQL Yum 存储库
yum localinstall -y $file_name

# 启用 mysql80-community 和 mysql-tools-community 存储库
yum-config-manager --enable mysql80-community mysql-tools-community

# 安装 MySQL 服务器
yum install -y mysql-community-server

# 启动 MySQL 服务
systemctl start mysqld

# 等待 MySQL 服务启动
sleep 10

# 输出临时密码
temp_password=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

# 修改密码为过渡密码
mysql -u root -p"$temp_password" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$interim_password';"

# 修改 MySQL 密码验证等级为 LOW
mysql -u root -p"$interim_password" --connect-expired-password -e "SET GLOBAL validate_password.policy=LOW;"

# 修改 MySQL 密码验证长度为6
mysql -u root -p"$interim_password" --connect-expired-password -e "SET GLOBAL validate_password.length=6;"

# 修改 MySQL 密码为新密码
mysql -u root -p"$interim_password" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$new_password';"

# 修改 MySQL 配置文件，允许外部访问
sed -i "s/^bind-address\s*=.*$/bind-address = ${bind_address}/" /etc/my.cnf

# 重启 MySQL 服务器使配置生效
systemctl restart mysql

# 连接 MySQL 并执行 SQL 命令
mysql -u root -p"$new_password" <<EOF
USE mysql;
UPDATE user SET host='%' WHERE user='root';
FLUSH PRIVILEGES;
EOF

# 授予root用户访问所有数据库的权限
mysql -u root -p"$new_password" -e "GRANT ALL ON *.* TO 'root'@'%';"

# 刷新权限
mysql -u root -p"$new_password" -e "FLUSH PRIVILEGES;"

echo "MySQL 已配置允许外部访问，并授予 root 用户访问所有数据库的权限。"

# 退出脚本
exit 0
