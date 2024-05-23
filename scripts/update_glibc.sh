#!/bin/bash

# 升级 GCC (默认为4 升级为8)
echo "升级 GCC 到版本 8"
yum install -y centos-release-scl bison
yum install -y devtoolset-8-gcc* devtoolset-8-gcc-c++
ln -sf /opt/rh/devtoolset-8/root/bin/gcc /usr/bin/gcc
ln -sf /opt/rh/devtoolset-8/root/bin/g++ /usr/bin/g++

# 升级 make (默认为3 升级为4)
yum install -y make
echo "升级 make 到版本 4.3"
wget http://ftp.gnu.org/gnu/make/make-4.3.tar.gz
tar -xzvf make-4.3.tar.gz && cd make-4.3/
./configure --prefix=/usr/local/make
make && make install
cd /usr/bin/ && mv make make.bak
ln -sv /usr/local/make/bin/make /usr/bin/make

# 返回初始目录
cd -

# 更新 libstdc++.so.6.0.26
echo "更新 libstdc++.so.6 到版本 6.0.26"
wget https://cdn.frostbelt.cn/software/libstdc%2B%2B.so.6.0.26 -O libstdc++.so.6.0.26
cp libstdc++.so.6.0.26 /usr/lib64/
cd /usr/lib64/
ln -snf ./libstdc++.so.6.0.26 libstdc++.so.6

# 返回初始目录
cd -

# 更新 glibc 到版本 2.28
echo "更新 glibc 到版本 2.28"
wget http://ftp.gnu.org/gnu/glibc/glibc-2.28.tar.gz
tar xf glibc-2.28.tar.gz
cd glibc-2.28/ && mkdir build && cd build
../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin
make -j$(nproc)
make install

echo "所有操作完成"

# 返回初始目录
cd -