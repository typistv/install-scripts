#! /bin/bash
source /etc/profile
yum install unzip -y
unzip ~/tools/webase-tools/webase-front.zip -d ~/tools/
cp -r ~/tools/fisco/nodes/127.0.0.1/sdk/* ~/tools/webase-front/conf/
cd ~/tools/webase-front/
bash start.sh