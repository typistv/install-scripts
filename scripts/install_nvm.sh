#!/bin/bash

wget https://github.com/nvm-sh/nvm/archive/refs/tags/v0.39.7.tar.gz
tar -zxvf v0.39.7.tar.gz
mv nvm-0.39.7 /root/.nvm
rm -rf v0.39.7.tar.gz
nvm_variable="\nexport NVM_DIR="/root/.nvm"\n[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm\n[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion"
echo -e $nvm_variable >> /etc/profile
