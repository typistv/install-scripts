#!/bin/bash

yum install libaio* numactl-libs -y


# 检查是否有MySQL相关软件包
mysql_packages=$(rpm -qa | grep -i mysql)

if [ -n "$mysql_packages" ]; then
  echo "发现MySQL相关软件包，将被移除："
  echo "$mysql_packages"
  yum -y remove $mysql_packages
  echo "MySQL相关软件包已成功移除"
else
  echo "未发现MySQL相关软件包"
fi

# 检查是否有MariaDB相关软件包
mariadb_packages=$(rpm -qa | grep -i mariadb)

if [ -n "$mariadb_packages" ]; then
  echo "发现MariaDB相关软件包，将被移除："
  echo "$mariadb_packages"
  yum -y remove $mariadb_packages
  echo "MariaDB相关软件包已成功移除"
else
  echo "未发现MariaDB相关软件包"
fi

# 解压 MySQL 安装包
echo "开始解压 MySQL 安装包。"
tar -xvf ~/tools/mysql-5.7.44-el7-x86_64.tar
tar -xvf mysql-5.7.44-el7-x86_64.tar.gz -C /usr/local/ --transform 's/mysql-5.7.44-el7-x86_64/mysql/'
rm ~/tools/mysql-5.7.44-el7-x86_64.tar mysql-5.7.44-el7-x86_64.tar.gz mysql-test-5.7.44-el7-x86_64.tar.gz -rf

# 创建 MySQL 用户组和用户
echo "创建 MySQL 用户组和用户。"
groupadd mysql
useradd -r -g mysql mysql

cd /usr/local/
#更改文件的用户组和用户
chown -R mysql:mysql mysql
#给mysql目录下的所有文件加执行权限
chmod -R 775 mysql

#把这个写到配置文件里，路径不同，记得要修改路径
echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile
source /etc/profile

#切换到mysql目录下
cd /usr/local/mysql/


# 初始化 MySQL 并捕捉输出
OUTPUT=$(mysqld --user=mysql --initialize --datadir=/usr/local/mysql/data 2>&1)

# 提取临时密码
TEMP_PASSWORD=$(echo "$OUTPUT" | grep 'temporary password' | awk '{print $NF}')

# 检查是否成功获取密码
if [ -z "$TEMP_PASSWORD" ]; then
    echo "未能提取临时密码。"
    exit 1
fi

#复制启动文件到/etc/init.d/目录
cp -ar /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
mv ~/tools/my.cnf /etc/
chmod -R 775 /etc/my.cnf

#启动 mysql 服务
/etc/init.d/mysqld start
#添加服务
chkconfig --add mysqld
#显示服务列表
chkconfig --list

echo "提取到的临时密码为: $TEMP_PASSWORD"

# 新密码
NEW_PASSWORD=123456
MYSQL_USER=root

# 使用临时密码登录 MySQL 并更新密码
mysql -u root -p"$TEMP_PASSWORD" --connect-expired-password -e "set password for root@localhost = password('$NEW_PASSWORD');"

if [ $? -eq 0 ]; then
    echo "MySQL密码已更新为新密码。"
else
    echo "更新MySQL密码失败。"
fi
# 关闭防护墙
systemctl stop firewalld
systemctl disable firewalld

mysql -u $MYSQL_USER -p$NEW_PASSWORD -e "use mysql;update user set user.Host='%' where user.User='root';flush privileges;"
