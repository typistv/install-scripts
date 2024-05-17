#!/bin/bash

set -exu
set -o pipefail

CHAIN_ID=32382
GETH_HTTP_PORT=8000
GETH_WS_PORT=8100
GETH_METRICS_PORT=8200
GETH_NETWORK_PORT=8300
GETH_AUTH_RPC_PORT=8400
ETHEREUM_DIR=/root/ethereum
NETWORK_DIR=$ETHEREUM_DIR/network
NUM_NODES=4
GETH_BINARY=$ETHEREUM_DIR/geth-tools/geth
GETH_BOOTNODE_BINARY=$ETHEREUM_DIR/geth-tools/bootnode
# 端口信息，确保不会发生端口冲突
GETH_BOOTNODE_PORT=30301


# GETH_PW_FILE=$ETHEREUM_PATH
BOOTNODE_ENODE=

PRYSM_DIR=$ETHEREUM_DIR/prysm




# MIN_SYNC_PEERS=$((NUM_NODES/2))
MIN_SYNC_PEERS=1
echo $MIN_SYNC_PEERS 是最小的同步节点数量



####
PRYSM_BOOTSTRAP_NODE=
PRYSM_BEACON_RPC_PORT=4000
PRYSM_BEACON_GRPC_GATEWAY_PORT=4100
PRYSM_BEACON_P2P_TCP_PORT=4200
PRYSM_BEACON_P2P_UDP_PORT=4300
PRYSM_BEACON_MONITORING_PORT=4400

PRYSM_VALIDATOR_RPC_PORT=7000
PRYSM_VALIDATOR_GRPC_GATEWAY_PORT=7100
PRYSM_VALIDATOR_MONITORING_PORT=7200
#########
accounts="0x0000000000000000000000000000000000000000000000000000000000000000"

trap 'echo "捕获到 Ctrl+C。正在终止所有进程并退出。"; kill $(jobs -p); exit' ERR SIGINT

# pkill geth || echo "没有运行中的 geth 进程"
# pkill beacon-chain || echo "没有运行中的 beacon-chain 进程"
# pkill validator || echo "没有运行中的 validator 进程"
# pkill bootnode || echo "没有运行中的 bootnode 进程"


rm -rf $NETWORK_DIR









# 创建启动节点用于客户端对等发现
mkdir -p $NETWORK_DIR/bootnode
# 生成启动节点的密钥
$GETH_BOOTNODE_BINARY -genkey $NETWORK_DIR/bootnode/nodekey

# 启动启动节点
$GETH_BOOTNODE_BINARY \
    -nodekey $NETWORK_DIR/bootnode/nodekey \
    -addr=:$GETH_BOOTNODE_PORT \
    -verbosity=5 > "$NETWORK_DIR/bootnode/bootnode.log" 2>&1 &

sleep 2
# 从启动节点日志中获取 ENODE
bootnode_enode=$(head -n 1 $NETWORK_DIR/bootnode/bootnode.log)
# 检查是否成功获取 ENODE
if [[ "$bootnode_enode" == enode* ]]; then
    echo "启动节点的 ENODE 是：$bootnode_enode"
else
    echo "未找到启动节点的 ENODE。正在退出。"
    exit 1
fi



cp tools/* $ETHEREUM_DIR/
cp $ETHEREUM_DIR/genesis.json $ETHEREUM_DIR/temporarily.json
# 为节点创建密钥和其他账户信息
for (( i=0; i<$NUM_NODES; i++ )); do
    NODE_DIR=$NETWORK_DIR/node$i
    mkdir -p $NODE_DIR/execution

    geth_pw_file="$NODE_DIR/geth_password.txt"
    echo "" > "$geth_pw_file"

    output=$(echo -e "\n" | $GETH_BINARY account new --datadir "$NODE_DIR/execution" --password "$geth_pw_file")
    public_address=$(echo "$output" | grep -oP 'Public address of the key:\s+\K\S+')
    accounts+=${public_address:2}
    jq --arg addr "${public_address:2}" '.alloc += { ($addr): { "balance": "0x21e19e0c9bab2400000" } }' $ETHEREUM_DIR/temporarily.json > $ETHEREUM_DIR/result.json
    mv $ETHEREUM_DIR/result.json $ETHEREUM_DIR/temporarily.json
done

   extradata=$accounts"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    jq --arg addr "${extradata}" '.extradata = ($addr)' $ETHEREUM_DIR/temporarily.json > $ETHEREUM_DIR/result.json
    mv $ETHEREUM_DIR/result.json $ETHEREUM_DIR/temporarily.json


    # 生成信标链测试网络 POS使用
    $PRYSM_DIR/prysmctl testnet generate-genesis \
    --fork=deneb \
    --num-validators=$NUM_NODES \
    --chain-config-file=$ETHEREUM_DIR/config.yml \
    --geth-genesis-json-in=$ETHEREUM_DIR/temporarily.json \
    --output-ssz=$ETHEREUM_DIR/genesis.ssz \
    --geth-genesis-json-out=$ETHEREUM_DIR/temporarily.json



# 启动 geth 执行客户端
for((i=0; i<$NUM_NODES; i++))
do
    NODE_DIR=$NETWORK_DIR/node$i
    mkdir -p $NODE_DIR/logs

    cp $ETHEREUM_DIR/temporarily.json $NODE_DIR/execution/genesis.json

    $GETH_BINARY init \
      --datadir=$NODE_DIR/execution \
      $NODE_DIR/execution/genesis.json

    # 启动 geth 执行客户端
    $GETH_BINARY \
      --networkid=${CHAIN_ID:-32382} \
      --allow-insecure-unlock \
      --http \
      --http.api=web3,eth,debug,personal,net \
      --http.addr=0.0.0.0 \
      --http.corsdomain="*" \
      --http.port=$((GETH_HTTP_PORT + i)) \
      --port=$((GETH_NETWORK_PORT + i)) \
      --metrics.port=$((GETH_METRICS_PORT + i)) \
      --ws \
      --ws.api=eth,net,web3 \
      --ws.addr=0.0.0.0 \
      --ws.origins="*" \
      --ws.port=$((GETH_WS_PORT + i)) \
      --authrpc.vhosts="*" \
      --authrpc.addr=0.0.0.0 \
      --authrpc.jwtsecret=$NODE_DIR/execution/jwtsecret \
      --authrpc.port=$((GETH_AUTH_RPC_PORT + i)) \
      --datadir=$NODE_DIR/execution \
      --password=$geth_pw_file \
      --bootnodes=$bootnode_enode \
      --identity=node$i \
      --maxpendpeers=$NUM_NODES \
      --verbosity=3 \
      --vmdebug \
      --syncmode=full > "$NODE_DIR/logs/geth.log" 2>&1 &

    sleep 5

    mkdir -p $NODE_DIR/consensus
    cp $ETHEREUM_DIR/genesis.ssz $NODE_DIR/consensus/genesis.ssz
    cp $ETHEREUM_DIR/config.yml $NODE_DIR/consensus/config.yml

    # 启动prysm共识客户端
    $PRYSM_DIR/beacon-chain \
      --datadir=$NODE_DIR/consensus/beacondata \
      --min-sync-peers=$MIN_SYNC_PEERS \
      --genesis-state=$NODE_DIR/consensus/genesis.ssz \
      --bootstrap-node=$PRYSM_BOOTSTRAP_NODE \
      --interop-eth1data-votes \
      --chain-config-file=$NODE_DIR/consensus/config.yml \
      --contract-deployment-block=0 \
      --chain-id=${CHAIN_ID:-32382} \
      --rpc-host=127.0.0.1 \
      --rpc-port=$((PRYSM_BEACON_RPC_PORT + i)) \
      --grpc-gateway-host=127.0.0.1 \
      --grpc-gateway-port=$((PRYSM_BEACON_GRPC_GATEWAY_PORT + i)) \
      --execution-endpoint=http://localhost:$((GETH_AUTH_RPC_PORT + i)) \
      --accept-terms-of-use \
      --jwt-secret=$NODE_DIR/execution/jwtsecret \
      --suggested-fee-recipient=0x123463a4b065722e99115d6c222f267d9cabb524 \
      --minimum-peers-per-subnet=0 \
      --p2p-tcp-port=$((PRYSM_BEACON_P2P_TCP_PORT + i)) \
      --p2p-udp-port=$((PRYSM_BEACON_P2P_UDP_PORT + i)) \
      --monitoring-port=$((PRYSM_BEACON_MONITORING_PORT + i)) \
      --verbosity=info \
      --slasher \
      --enable-debug-rpc-endpoints > "$NODE_DIR/logs/beacon.log" 2>&1 &


    $PRYSM_DIR/validator \
      --beacon-rpc-provider=localhost:$((PRYSM_BEACON_RPC_PORT + i)) \
      --datadir=$NODE_DIR/consensus/validatordata \
      --accept-terms-of-use \
      --interop-num-validators=1 \
      --interop-start-index=$i \
      --rpc-port=$((PRYSM_VALIDATOR_RPC_PORT + i)) \
      --grpc-gateway-port=$((PRYSM_VALIDATOR_GRPC_GATEWAY_PORT + i)) \
      --monitoring-port=$((PRYSM_VALIDATOR_MONITORING_PORT + i)) \
      --graffiti="node-$i" \
      --chain-config-file=$NODE_DIR/consensus/config.yml > "$NODE_DIR/logs/validator.log" 2>&1 &


      # Check if the PRYSM_BOOTSTRAP_NODE variable is already set
    if [[ -z "${PRYSM_BOOTSTRAP_NODE}" ]]; then
        sleep 5 # sleep to let the prysm node set up
        # If PRYSM_BOOTSTRAP_NODE is not set, execute the command and capture the result into the variable
        # This allows subsequent nodes to discover the first node, treating it as the bootnode
        PRYSM_BOOTSTRAP_NODE=$(curl -s localhost:4100/eth/v1/node/identity | jq -r '.data.enr')
            # Check if the result starts with enr
        if [[ $PRYSM_BOOTSTRAP_NODE == enr* ]]; then
            echo "PRYSM_BOOTSTRAP_NODE is valid: $PRYSM_BOOTSTRAP_NODE"
        else
            echo "PRYSM_BOOTSTRAP_NODE does NOT start with enr"
            exit 1
        fi
    fi
done

# You might want to change this if you want to tail logs for other nodes
# Logs for all nodes can be found in `./network/node-*/logs`
tail -f "$NETWORK_DIR/node0/logs/geth.log"