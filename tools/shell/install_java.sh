#! /bin/bash
yum install vim git tar unzip sudo wget -y
wget -P /usr/local http://192.168.9.140/base/jdk-8u161-linux-x64.tar.gz
tar -zxvf /usr/local/jdk-8u161-linux-x64.tar.gz -C /usr/local/

java_environment_variables="#java\nexport JAVA_HOME=/usr/local/jdk1.8.0_161\nexport JRE_HOME=\${JAVA_HOME}/jre\nexport CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib:\$CLASSPATH\nexport JAVA_PATH=\${JAVA_HOME}/bin:\${JRE_HOME}/bin\n
export PATH=\$PATH:\${JAVA_PATH}"

echo -e $java_environment_variables >> /etc/profile

echo source /etc/profile >> ~/.bashrc