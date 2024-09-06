#!/bin/bash
    INSTALLACTION_PATH=/root/tools/fisco
    TOOLS_PATH=/root/tools
    FISCO_NAME=fisco-bcos.tar.gz
    BUILD_CHAIN_NAME=build_chain.sh
    JAVA_VERSION="1.8.0_161"

install_fisco(){
    check_openssl
    mkdir -p "$INSTALLACTION_PATH"
    tar -zxvf "${TOOLS_PATH}/$FISCO_NAME" -C "$INSTALLACTION_PATH"
    cp "${TOOLS_PATH}/$BUILD_CHAIN_NAME" "$INSTALLACTION_PATH/"
    chmod +x "${INSTALLACTION_PATH}/$BUILD_CHAIN_NAME"
    cd "$INSTALLACTION_PATH"
    bash "$BUILD_CHAIN_NAME" -e "${INSTALLACTION_PATH}/fisco-bcos" -l 127.0.0.1:4 -p 30300,20200,8545
}

check_openssl(){
    # 检查 OpenSSL 是否已安装
    openssl_installed=$(rpm -qa | grep -q openssl && echo "Yes" || echo "No")
    echo "OpenSSL installed: $openssl_installed"

    # 检查 OpenSSL-devel 是否已安装
    openssl_devel_installed=$(rpm -qa | grep -q openssl-devel && echo "Yes" || echo "No")
    echo "OpenSSL-devel installed: $openssl_devel_installed"
    
    # 如果 OpenSSL 未安装，则自动安装
    if [ "$openssl_installed" == "No" ]; then
        echo "Installing OpenSSL..."
        yum install -y openssl
    fi

    # 如果 OpenSSL-devel 未安装，则自动安装
    if [ "$openssl_devel_installed" == "No" ]; then
        echo "Installing OpenSSL-devel..."
        yum install -y openssl-devel
    fi
}

# check_console(){
#     bash $INSTALLACTION_PATH/nodes/127.0.0.1/start_all.sh
#     cd $TOOLS_PATH
#     if [ -d "console" ]; then
#         echo "Folder console exists."
#     else
#         tar -zxvf console.tar.gz
#         # 最新版本控制台使用如下命令拷贝配置文件
#         cp -n console/conf/config-example.toml console/conf/config.toml
#         cp -r $INSTALLACTION_PATH/nodes/127.0.0.1/sdk/* console/conf/
#     fi
#     output=$(bash console/start.sh &)
#     pid=$!
#     echo "$pid"
#     echo "$output"
#     # 检查输出中是否包含指定的字符串
    if echo "$output" | grep -q "create BcosSDK failed, error info: init channel network error!"; then
        echo "Error: create BcosSDK failed. Stopping script."
        exit 1
    fi

#     # 等待控制台程序启动
#     sleep 10

#     # 检查控制台程序是否正在运行
#     if ps -p $pid > /dev/null; then
#         echo "控制台程序已经成功启动，进程ID为: $pid"
#         # 在此处添加您的其他操作，如果需要的话

#         # 终止脚本
#         trap "kill $pid" EXIT
#     else
#         echo "控制台程序启动失败，请检查日志或其他错误信息"
#         # 终止脚本
#         exit 1
#     fi
#     # 如果没有包含指定字符串，则继续执行脚本的其余部分
#     echo "Continue with script..."
# }


# 检查脚本文件
check_console(){
    bash $INSTALLACTION_PATH/nodes/127.0.0.1/start_all.sh
    cd $TOOLS_PATH
    if [ -d "console" ]; then
        echo "Folder console exists."
    else
        tar -zxvf console.tar.gz
        # 最新版本控制台使用如下命令拷贝配置文件
        cp -n console/conf/config-example.toml console/conf/config.toml
        cp -r $INSTALLACTION_PATH/nodes/127.0.0.1/sdk/* console/conf/
    fi
    nohup bash console/start.sh > console_output.log 2>&1 &
    pid=$!
    echo "$pid"
    # 等待控制台程序启动
    sleep 10
    # 检查控制台程序是否正在运行
    if ps -p $pid > /dev/null; then
        echo "控制台程序已经成功启动，进程ID为: $pid"
        # 在此处添加您的其他操作，如果需要的话
        # 终止脚本
        kill $pid
    else
        echo "控制台程序启动失败，请检查日志或其他错误信息"
        # 终止脚本
        exit 1
    fi
    rm -rf $TOOLS_PATH/console
}

check_java(){
    java_version=$(java -version 2>&1)
    # 检查java命令是否存在
    if command -v java >/dev/null 2>&1; then
        echo "Java 已安装。"
    else
        exit 1
    fi
}

check_add_new_node(){
    CONFIG_PATH=/root/tools/fisco/nodes/127.0.0.1/node4/config.ini
    cd $TOOLS_PATH
    cp gen_node_cert.sh $INSTALLACTION_PATH/nodes/127.0.0.1/
    cd $INSTALLACTION_PATH/nodes/127.0.0.1/
    bash gen_node_cert.sh -c ../cert/agency -o node4
    cp node0/config.ini node0/start.sh node0/stop.sh node4/
    
    sed -i "s|channel_listen_port=20200|channel_listen_port=20204|" "$CONFIG_PATH"
    sed -i "s|jsonrpc_listen_port=8545|jsonrpc_listen_port=8549|" "$CONFIG_PATH"
    sed -i "s|listen_port=30300|listen_port=30304|" "$CONFIG_PATH"
    # 在 p2p 部分找到最后一个节点并添加一个新节点在其后
    last_node=$(grep -oP 'node\.\d+=' "$config_file" | awk -F'.' '{print $2}' | sort -n | tail -n 1)
    new_node_index=$((last_node + 1))

    output=$(bash $INSTALLACTION_PATH/nodes/127.0.0.1/start_all.sh)
    if echo "$output" | grep -q "node4 start successfully"; then
        echo "已添加新的节点node4"
    else
        echo "Error:无法新的节点node4"
        exit 1
    fi
    bash $INSTALLACTION_PATH/nodes/127.0.0.1/stop_all.sh
    rm -rf  $INSTALLACTION_PATH/nodes/127.0.0.1/node4
}

check_webase(){
    bash $INSTALLACTION_PATH/nodes/127.0.0.1/start_all.sh
    if [ -d "$TOOLS_PATH/webase" ]; then
        rm -rf $TOOLS_PATH/webase
        kill_port
    fi
    mkdir $TOOLS_PATH/webase
    cp $TOOLS_PATH/webase-tools/webase-deploy.zip $TOOLS_PATH/webase/
    cd $TOOLS_PATH/webase/
    unzip webase-deploy.zip
    cp $TOOLS_PATH/webase-tools/*.zip $TOOLS_PATH/webase/webase-deploy/
    cd $TOOLS_PATH/webase/webase-deploy/
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
    run_webase_install
    
    python3 deploy.py stopAll
    rm -rf $TOOLS_PATH/webase
}


run_webase_install() {
kill_port
delete_tables
cd $TOOLS_PATH/webase/webase-deploy/
#检查是否安装expect
if ! command -v expect &> /dev/null; then
    echo "Expect is not installed. Installing..."
    # 使用包管理器安装 expect
    if command -v apt-get &> /dev/null; then
        sudo apt-get install expect -y
    elif command -v yum &> /dev/null; then
        sudo yum install expect -y
    else
        echo "Could not determine package manager. Please install expect manually."
        exit 1
    fi
fi
    # 切换到工作目录
    cd ~/tools/webase/webase-deploy/

    # 创建 Expect 脚本
    expect_script=$(mktemp)
    cat <<'EOF' > "$expect_script"
#!/usr/bin/expect

# 执行命令前的提示信息
set prompt "deploy  has completed"

# 执行命令
spawn python3 deploy.py installAll

while {1} {
    expect {
        "*Do you want to re-download and overwrite it*" {
            send "n\r"
            exp_continue
        }
        "Do you want drop and recreate it?" {
            send "y\r"
            exp_continue
        }
        "Do you want drop and re-initialize it?" {
            send "y\r"
            exp_continue
        }
        "$prompt" {
            puts "$expect_out(buffer)"
            break
        }
        eof {
            break
        }
    }
}

EOF

    # 赋予执行权限
    chmod +x "$expect_script"

    # 执行 Expect 脚本
    "$expect_script"

    # 删除临时文件
    rm -f "$expect_script"
}

kill_port(){

# 检查 lsof 是否已安装
if ! command -v lsof &> /dev/null; then
    echo "lsof is not installed. Installing..."
    # 使用 yum 包管理器安装 lsof
    sudo yum install lsof -y
    # 检查安装是否成功
    if ! command -v lsof &> /dev/null; then
        echo "Failed to install lsof. Please install it manually."
        exit 1
    fi
fi

echo "lsof is installed."


# 定义要检查的端口范围
ports=(5000 5001 5002 5003 5004)

# 检查每个端口是否被占用，并终止相关进程
for port in "${ports[@]}"; do
    echo "Checking port $port..."
    pid=$(lsof -t -i:$port)
    if [ -n "$pid" ]; then
        echo "Error! Port $port has been used. Please check."
        echo "Process found with PID $pid on port $port."
        # 输出占用该端口的进程信息
        echo "Process details:"
        ps -p $pid -o pid,ppid,cmd
        kill $pid
    else
        echo "No process found on port $port."
    fi
done
}

delete_tables(){
    # 设置 MySQL 用户名和密码
mysql_user="root"
mysql_password="123456"

# 检查 MySQL 用户名和密码是否为空
if [ -z "$mysql_user" ] || [ -z "$mysql_password" ]; then
    echo "MySQL username or password is not provided. Please provide them."
    exit 1
fi

# 执行 MySQL 查询语句删除 webasenodemanager 和 webasesign 数据库
mysql -u"$mysql_user" -p"$mysql_password" -e "DROP DATABASE IF EXISTS webasenodemanager"
mysql -u"$mysql_user" -p"$mysql_password" -e "DROP DATABASE IF EXISTS webasesign"
# 检查执行结果
if [ $? -eq 0 ]; then
    echo "webasenodemanager and webasesign databases have been deleted successfully."
else
    echo "Failed to delete webasenodemanager and webasesign databases."
fi
}