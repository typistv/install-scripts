#!/bin/bash
path="/etc/yum.repos.d/mariadb.repo"
touch $path
ustc_mirror="# MariaDB 10.2 CentOS repository list - created 2021-07-12 07:37 UTC\n# http://downloads.mariadb.org/mariadb/repositories/\n[mariadb]\nname = MariaDB\nbaseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.2/centos7-amd64\ngpgkey=https://mirrors.ustc.edu.cn/mariadb/yum/RPM-GPG-KEY-MariaDB\ngpgcheck=1"
echo -e $ustc_mirror >> $path
yum clean all -y
yum makecache all -y
yum install MariaDB-server MariaDB-client -y
systemctl start mariadb.service
systemctl enable mariadb.service


# 执行mysql_secure_installation
mysql_secure_installation <<EOF

# 初次运行直接回车
Y

# 设置root用户密码
123456
123456

# 是否删除匿名用户
Y

# 是否禁止root远程登录
Y

# 是否删除test数据库
Y

# 是否重新加载权限表
Y

EOF

#!/bin/bash

# MySQL远程访问授权脚本

# MySQL登录信息
MYSQL_USER="root"
MYSQL_PASSWORD="123456"
MYSQL_HOST="localhost"
MYSQL_PORT="3306"

# 远程访问授权信息
REMOTE_USER="root"
REMOTE_HOST="%"
REMOTE_PASSWORD="123456"

# 登录MySQL并授权
mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" <<EOF
GRANT ALL PRIVILEGES ON *.* TO '${REMOTE_USER}'@'${REMOTE_HOST}' IDENTIFIED BY '${REMOTE_PASSWORD}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
