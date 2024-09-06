#!/bin/bash
source /etc/profile
startPath=/home/startFisocBcosAndWebase-front.sh
startCode="#!/bin/bash\nsource /etc/profile\nbash ~/tools/fisco/nodes/127.0.0.1/start_all.sh\ncd ~/tools/webase-front/ && bash start.sh"
touch $startPath
echo -e $startCode >> $startPath
chmod +x $startPath

servicePath=/etc/systemd/system/startFisco.service
serviceCode="[Unit]\nDescription=Start Fisoc and Webase-front\nAfter=network.target\n\n[Service]\nExecStart=$startPath\nRestart=no\nUser=root\nType=simple\nRemainAfterExit=true\n\n[Install]\nWantedBy=multi-user.target"

touch $servicePath
echo -e $serviceCode >> $servicePath
chmod +x $servicePath
systemctl daemon-reload
systemctl restart startFisco.service
systemctl status startFisco.service
systemctl enable startFisco.service
