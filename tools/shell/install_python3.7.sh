#! /bin/bash
yum install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make libffi-devel make gcc gcc-c++ wget -y
wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz
tar -zxvf Python-3.7.2.tgz -C /usr/local/
cd /usr/local/
mv Python-3.7.2 ./python3.7
cd python3.7/
./configure
make&&make install

mv /usr/bin/python /usr/bin/python.bak
ln -s /usr/local/bin/python3 /usr/bin/python
mv /usr/bin/pip /usr/bin/pip.bak
ln -s /usr/local/bin/pip3 /usr/bin/pip

sed -i "s|"/usr/bin/python"|"/usr/bin/python2.7"|g" /usr/bin/yum
sed -i "s|"/usr/bin/python"|"/usr/bin/python2.7"|g" /usr/libexec/urlgrabber-ext-down
