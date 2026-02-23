#!/bin/bash
USER=$(whoami)
ALIST_PORT=40759
mkdir -p ~/alist
cd ~/alist
wget 
tar -zxvf alist-freebsd-amd64.tar.gz
rm alist-freebsd-amd64.tar.gz
chmod +x alist
./alist server > alist_init.log 2>&1 &
sleep 5
pkill -9 alist
sed -i '' "s/5244/$ALIST_PORT/g" data/config.json
./alist admin
nohup ./alist server > /dev/null 2>&1 &
