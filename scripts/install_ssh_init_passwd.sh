#!/bin/bash

yum install -y openssh-server && systemctl start sshd && systemctl enable sshd && echo "root:123456" | chpasswd
