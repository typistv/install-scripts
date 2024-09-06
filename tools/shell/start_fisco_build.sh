#! /bin/bash
source /etc/profile && bash ~/tools/fisco/nodes/127.0.0.1/start_all.sh && cd ~/tools/webase/webase-deploy/ && python3 deploy.py startAll
