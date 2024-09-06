#!/bin/bash
tar -zxvf ~/tools/nvm-0.39.5.tar.gz -C /root/
cd /root/
mv nvm-0.39.5 .nvm
nvm_variable="\nexport NVM_DIR="/root/.nvm"\n[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm\n[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion"
echo -e $nvm_variable >> /etc/profile
source /etc/profile
# nvm install v16.20.2 ~/tools/node-v16.20.2-linux-x64.tar.gz
# 修改为淘宝镜像
# npm config set registry https://registry.npmmirror.com
# nvm install v8.17.0 ~/tools/node-v8.17.0-linux-x64.tar.gz
# nvm use 16