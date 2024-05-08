#!/bin/bash

set -exu
set -o pipefail

PRYSM_PATH="ethereum/prysm"
GETH_PATH="ethereum/geth-tools"

mkdir -p $PRYSM_PATH

wget -P ethereum http://192.168.9.140/blockchain/ethereum/go-ethereum/geth-alltools-linux-amd64-1.14.0-87246f3c.tar.gz
cd ethereum
tar -zxvf geth-alltools-linux-amd64-1.14.0-87246f3c.tar.gz
mv geth-alltools-linux-amd64-1.14.0-87246f3c geth-tools

cd ..
cd $PRYSM_PATH
wget http://192.168.9.140/blockchain/ethereum/prysm/beacon-chain-v5.0.3-linux-amd64
mv beacon-chain-v5.0.3-linux-amd64 beacon-chain

wget http://192.168.9.140/blockchain/ethereum/prysm/prysmctl-v5.0.3-linux-amd64
mv prysmctl-v5.0.3-linux-amd64 prysmctl

wget http://192.168.9.140/blockchain/ethereum/prysm/validator-v5.0.3-linux-amd64
mv validator-v5.0.3-linux-amd64 validator
