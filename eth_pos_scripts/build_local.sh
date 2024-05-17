#!/bin/bash

set -exu
set -o pipefail

ETHEREUM_DIR="/root/ethereum"
GETH_FILE="geth-alltools-linux-amd64-1.14.0-87246f3c"

mkdir -p $ETHEREUM_DIR/prysm

wget -P $ETHEREUM_DIR http://192.168.9.140/blockchain/ethereum/go-ethereum/$GETH_FILE.tar.gz
cd $ETHEREUM_DIR
tar -zxvf $GETH_FILE.tar.gz
rm -rf $GETH_FILE.tar.gz
mv $GETH_FILE geth-tools

cd $ETHEREUM_DIR/prysm
wget http://192.168.9.140/blockchain/ethereum/prysm/beacon-chain-v5.0.3-linux-amd64
mv beacon-chain-v5.0.3-linux-amd64 beacon-chain
chmod 777 beacon-chain

wget http://192.168.9.140/blockchain/ethereum/prysm/prysmctl-v5.0.3-linux-amd64
mv prysmctl-v5.0.3-linux-amd64 prysmctl
chmod 777 prysmctl

wget http://192.168.9.140/blockchain/ethereum/prysm/validator-v5.0.3-linux-amd64
mv validator-v5.0.3-linux-amd64 validator
chmod 777 validator