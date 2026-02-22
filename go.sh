#!/bin/bash

# ==========================================
# 终极全家桶：利用现有端口，不触发系统删除
# ==========================================

# --- 1. 先跑节点安装 ---
# 注意：安装完后，记下那个 Hysteria2 的端口（假设是 47415）
echo "第一步：正在确保节点环境就位..."
bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh)

# --- 2. 安装 Alist 并“借用”端口 ---
echo "第二步：安装 Alist 并借用节点端口..."
mkdir -p ~/alist && cd ~/alist
wget https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz
tar -zxvf alist-freebsd-amd64.tar.gz
chmod +x alist
rm alist-freebsd-amd64.tar.gz

# --- 3. 自动匹配端口 (核心逻辑) ---
# 自动寻找你名下的 TCP 端口，并把 Alist 绑定在最后一个端口上
# 这样无论勇哥脚本怎么变端口，Alist 都能跟过去
MY_PORT=$(devil port list | grep tcp | awk '{print $1}' | tail -n 1)
echo "检测到可用端口: $MY_PORT，正在绑定 Alist..."

./alist admin set admin123
mkdir -p data
echo "{\"address\": \"0.0.0.0\", \"port\": $MY_PORT}" > data/config.json

pkill alist
nohup ./alist server > /dev/null 2>&1 &

# --- 4. 配置保活 ---
curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00keep.sh -o ~/serv00keep.sh
chmod +x ~/serv00keep.sh
if ! grep -q "alist" ~/serv00keep.sh; then
    echo "if ! pgrep -x \"alist\" > /dev/null; then cd ~/alist && nohup ./alist server --port $MY_PORT > /dev/null 2>&1 & fi" >> ~/serv00keep.sh
fi
(crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * /home/$(whoami)/serv00keep.sh > /dev/null 2>&1") | crontab -

echo "------------------------------------------------"
echo "全家桶配置完成！"
echo "Alist 已经借用了端口: $MY_PORT"
echo "你可以通过 http://你的IP:$MY_PORT 访问云盘"
echo "------------------------------------------------"
