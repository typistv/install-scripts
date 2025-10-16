#!/bin/bash
set -e
# 检查是否已安装 JDK
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "检测到 JDK 已安装，版本信息为：$JAVA_VERSION"
    echo "脚本退出，无需重复安装。"
    exit 0
else
    echo "未检测到 JDK，准备进行安装。"
fi

# 安装必要工具
yum install vim git tar unzip sudo wget -y

# 下载 JDK 安装包
JDK_VERSION="8u451-linux-x64"
JDK_URL="http://192.168.46.1:8080/dufs/tools/jdk-${JDK_VERSION}.tar.gz"
INSTALL_PATH="/root/install-packages/utils"
JDK_FILE="$INSTALL_PATH/jdk-${JDK_VERSION}.tar.gz"
INSTALL_DIR="/usr/local/"

# 确保安装包目录存在
mkdir -p "$INSTALL_PATH"

# 下载 JDK 安装包
if [ ! -f "$JDK_FILE" ]; then
    echo "正在从 $JDK_URL 下载 JDK 安装包..."
    wget -O "$JDK_FILE" "$JDK_URL" || { echo "下载 JDK 安装包失败！请检查网络或 URL。"; exit 1; }
else
    echo "本地已存在 JDK 安装包，跳过下载。"
fi

# 解压 JDK 安装包
tar -zxvf "$JDK_FILE" -C /usr/local/ || { echo "解压 JDK 失败！请检查文件路径和完整性。"; exit 1; }

# 获取解压后的文件夹名称
FOLDER_NAME=$(ls "$INSTALL_DIR" | grep "jdk")
if [ -z "$FOLDER_NAME" ]; then
    echo "未找到解压后的文件夹！"
    exit 1
else
    echo "解压后的文件夹名称为：$FOLDER_NAME"
fi

# 配置环境变量
java_environment_variables=$(cat <<EOF

# JAVA 配置
export JAVA_HOME=/usr/local/${FOLDER_NAME}
export JRE_HOME=\${JAVA_HOME}/jre
export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib:\$CLASSPATH
export JAVA_PATH=\${JAVA_HOME}/bin:\${JRE_HOME}/bin
export PATH=\$PATH:\${JAVA_PATH}
EOF
)

echo -e "$java_environment_variables" >> /etc/profile || { echo "写入 /etc/profile 失败！"; exit 1; }

# 加载新环境变量
source /etc/profile || { echo "加载环境变量失败！请手动检查 /etc/profile。"; exit 1; }

# 将 `source /etc/profile` 写入 ~/.bashrc
echo "source /etc/profile" >> ~/.bashrc || { echo "更新 ~/.bashrc 失败！"; exit 1; }

# 检查安装结果
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "JDK 安装成功，版本信息为：$JAVA_VERSION"
else
    echo "JDK 安装失败！请检查日志。"
    exit 1
fi