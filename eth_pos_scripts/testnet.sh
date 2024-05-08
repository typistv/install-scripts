#!/bin/bash

# 设置脚本在执行过程中出现错误时立即退出，并打印每一行命令
set -exu
set -o pipefail

# 检查是否安装了 jq 和 curl 工具，如果没有则输出错误信息并退出脚本
if ! command -v jq &> /dev/null; then
    echo "错误：未安装 jq，请先安装 jq。"
    exit 1
fi
if ! command -v curl &> /dev/null; then
    echo "错误：未安装 curl，请先安装 curl。"
    exit 1
fi

# 网络文件存储目录，包括日志和数据等
NETWORK_DIR=/root/ethereum/network

# 设置节点数量
NUM_NODES=2

# 端口信息，确保不会发生端口冲突
GETH_BOOTNODE_PORT=30301

GETH_HTTP_PORT=8000
GETH_WS_PORT=8100
GETH_AUTH_RPC_PORT=8200
GETH_METRICS_PORT=8300
GETH_NETWORK_PORT=8400

PRYSM_BEACON_RPC_PORT=4000
PRYSM_BEACON_GRPC_GATEWAY_PORT=4100
PRYSM_BEACON_P2P_TCP_PORT=4200
PRYSM_BEACON_P2P_UDP_PORT=4300
PRYSM_BEACON_MONITORING_PORT=4400

PRYSM_VALIDATOR_RPC_PORT=7000
PRYSM_VALIDATOR_GRPC_GATEWAY_PORT=7100
PRYSM_VALIDATOR_MONITORING_PORT=7200

# 当按下 Ctrl+C 终止脚本时执行的清理操作
trap 'echo "捕获到 Ctrl+C。正在终止所有进程并退出。"; kill $(jobs -p); exit' ERR SIGINT

# 删除之前运行留下的数据和进程
rm -rf "$NETWORK_DIR" || echo "网络目录不存在"
mkdir -p $NETWORK_DIR
pkill geth || echo "没有运行中的 geth 进程"
pkill beacon-chain || echo "没有运行中的 beacon-chain 进程"
pkill validator || echo "没有运行中的 validator 进程"
pkill bootnode || echo "没有运行中的 bootnode 进程"

# 设置依赖的二进制文件路径，可根据需要修改
GETH_BINARY=./ethereum/geth-tools/geth
GETH_BOOTNODE_BINARY=./ethereum/geth-tools/bootnode

PRYSM_CTL_BINARY=./ethereum/prysm/prysmctl
PRYSM_BEACON_BINARY=./ethereum/prysm/beacon-chain
PRYSM_VALIDATOR_BINARY=./ethereum/prysm/validator

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

# 生成测试网络的创世块
$PRYSM_CTL_BINARY testnet generate-genesis \
--fork=deneb \
--num-validators=$NUM_NODES \
--chain-config-file=tools/config.yml \
--geth-genesis-json-in=tools/genesis.json \
--output-ssz=$NETWORK_DIR/genesis.ssz \
--geth-genesis-json-out=$NETWORK_DIR/genesis.json

# 设置 prysm 启动节点
PRYSM_BOOTSTRAP_NODE=

# 计算需要等待同步的最小节点数
MIN_SYNC_PEERS=$((NUM_NODES/2))
echo $MIN_SYNC_PEERS 是最小的同步节点数量

# 循环创建节点
for (( i=0; i<$NUM_NODES; i++ )); do
    NODE_DIR=$NETWORK_DIR/node-$i
    mkdir -p $NODE_DIR/execution
    mkdir -p $NODE_DIR/consensus
    mkdir -p $NODE_DIR/logs

    # 创建 geth 密码文件
    geth_pw_file="$NODE_DIR/geth_password.txt"
    echo "" > "$geth_pw_file"

    # 将创世块和配置文件复制到节点目录
    cp tools/config.yml $NODE_DIR/consensus/config.yml
    cp $NETWORK_DIR/genesis.ssz $NODE_DIR/consensus/genesis.ssz
    cp $NETWORK_DIR/genesis.json $NODE_DIR/execution/genesis.json

    # 为节点创建密钥和其他账户信息
    $GETH_BINARY account new --datadir "$NODE_DIR/execution" --password "$geth_pw_file"

    # 初始化节点的执行客户端
    $GETH_BINARY init \
      --datadir=$NODE_DIR/execution \
      $NODE_DIR/execution/genesis.json

    # 启动 geth 执行客户端
    $GETH_BINARY \
      --networkid=${CHAIN_ID:-32382} \
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
      --identity=node-$i \
      --maxpendpeers=$NUM_NODES \
      --verbosity=3 \
      --vmdebug \
      --syncmode=full > "$NODE_DIR/logs/geth.log" 2>&1 &

    sleep 5

    # Start prysm consensus client for this node
    $PRYSM_BEACON_BINARY \
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

    # Start prysm validator for this node. Each validator node will
    # manage 1 validator
    $PRYSM_VALIDATOR_BINARY \
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
tail -f "$NETWORK_DIR/node-0/logs/geth.log"