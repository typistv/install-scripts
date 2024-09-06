#!/bin/bash
INSTALLACTION_PATH=/root/tools/fisco
TOOLS_PATH=/root/tools

yum install -y openssl openssl-devel
mkdir -p "$INSTALLACTION_PATH"
tar -zxvf "${TOOLS_PATH}/fisco-bcos2.9.1.tar.gz" -C "$INSTALLACTION_PATH"
cp "${TOOLS_PATH}/build_chain2.9.1.sh" "$INSTALLACTION_PATH/"
chmod +x "${INSTALLACTION_PATH}/build_chain2.9.1.sh"
cd "$INSTALLACTION_PATH"
bash "build_chain2.9.1.sh" -e "${INSTALLACTION_PATH}/fisco-bcos" -l 127.0.0.1:4 -p 30300,20200,8545
# bash "${INSTALLACTION_PATH}/nodes/127.0.0.1/start_all.sh"