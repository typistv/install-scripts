#! /bin/bash
networkPath=~/tools/caliper/caliper-benchmarks/networks/fisco-bcos/
fiscoPath=~/tools/fisco/nodes/127.0.0.1/
helloworldPath=~/tools/caliper/caliper-benchmarks/benchmarks/samples/fisco-bcos/helloworld/config.yaml
rm -rf ~/tools/caliper
tar -xvf ~/tools/caliper.tar -C ~/tools/

cp -r "${networkPath}"4nodes1group/fisco-bcos.json $networkPath

sed -i 's|"end": "docker-compose -f networks/fisco-bcos/4nodes1group/docker-compose.yaml down"||' "${networkPath}fisco-bcos.json"
sed -i 's|"docker-compose -f networks/fisco-bcos/4nodes1group/docker-compose.yaml up -d; sleep 3s",|"bash ~/tools/fisco/nodes/127.0.0.1/start_all.sh"|' "${networkPath}fisco-bcos.json"
sed -i "s|\./networks/fisco-bcos/4nodes1group/|$fiscoPath|" "${networkPath}fisco-bcos.json"
sed -i "s|8914|8545|" "${networkPath}fisco-bcos.json"
sed -i "s|8915|8546|" "${networkPath}fisco-bcos.json"
sed -i "s|8916|8547|" "${networkPath}fisco-bcos.json"
sed -i "s|8917|8548|" "${networkPath}fisco-bcos.json"
sed -i "s|20914|20200|" "${networkPath}fisco-bcos.json"
sed -i "s|20915|20201|" "${networkPath}fisco-bcos.json"
sed -i "s|20916|20202|" "${networkPath}fisco-bcos.json"
sed -i "s|20917|20203|" "${networkPath}fisco-bcos.json"
sed -i "s|node.key|sdk.key|" "${networkPath}fisco-bcos.json"
sed -i "s|node.crt|sdk.crt|" "${networkPath}fisco-bcos.json"

sed -i "s|10000|10|" $helloworldPath
sed -i "s|1000|1|" $helloworldPath

cd ~/tools/caliper/
npx caliper benchmark run --caliper-workspace caliper-benchmarks --caliper-benchconfig benchmarks/samples/fisco-bcos/helloworld/config.yaml  --caliper-networkconfig networks/fisco-bcos/fisco-bcos.json