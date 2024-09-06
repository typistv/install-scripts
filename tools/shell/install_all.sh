#! /bin/bash
INSTALLACTION_PATH="~/app"
TOOLS_PATH="~/tools"
mkdir -p $INSTALLACTION_PATH/fisco
yum install -y openssl openssl-devel
tar -zxvf $TOOLS_PATH/fisco-bcos.tar.gz -C $INSTALLACTION_PATH/fisco