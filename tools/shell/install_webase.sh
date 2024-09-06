#! /bin/bash
# yum install expect -y
# pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
pip3 install PyMySQL
mkdir ~/tools/webase
cp ~/tools/webase-tools/webase-deploy.zip ~/tools/webase/
cd ~/tools/webase/
unzip webase-deploy.zip
cp ~/tools/webase-tools/*.zip ~/tools/webase/webase-deploy/
cd ~/tools/webase/webase-deploy/

mysql_ps="123456"
mysql_name="root"
file_path="common.properties"
old_fisco="fisco.dir=/data/app/nodes/127.0.0.1"
new_fisco="fisco.dir=/root/tools/fisco/nodes/127.0.0.1"

sed -i "s/"docker.mysql=1"/"docker.mysql=0"/g" $file_path
sed -i "s/"23306"/"3306"/g" $file_path
sed -i "s/"dbUsername"/$mysql_name/g" $file_path
sed -i "s/"dbPassword"/$mysql_ps/g" $file_path
sed -i "s/"if.exist.fisco=no"/"if.exist.fisco=yes"/g" $file_path
sed -i "s|$old_fisco|$new_fisco|g" $file_path