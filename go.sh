#!/bin/bash

# ==========================================
# 你的专属一键全家桶：节点 + Alist云盘 + 自动保活
# ==========================================

# --- 1. 安装节点 (Serv00 专用版) ---
echo "第一步：正在安装 Sing-box 节点..."
bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh)

# --- 2. 安装 Alist 云盘 ---
echo "第二步：正在安装 Alist 私人云盘..."
mkdir -p ~/alist
cd ~/alist
# 下载 Serv00(FreeBSD) 对应的 Alist 版本
wget https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz
tar -zxvf alist-freebsd-amd64.tar.gz
chmod +x alist
rm alist-freebsd-amd64.tar.gz

# 初始化 Alist 密码并启动 (默认端口5244，稍后你在后台改)
./alist admin set admin123
nohup ./alist server > /dev/null 2>&1 &

# --- 3. 配置自动保活 (节点 + Alist) ---
echo "第三步：正在配置全自动双重保活系统..."
# 下载保活脚本
curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00keep.sh -o ~/serv00keep.sh
chmod +x ~/serv00keep.sh

# 关键：修改保活脚本，让它同时巡逻 Alist
# 如果发现 alist 没运行，就启动它
if ! grep -q "alist" ~/serv00keep.sh; then
    echo 'if ! pgrep -x "alist" > /dev/null; then cd ~/alist && nohup ./alist server > /dev/null 2>&1 & fi' >> ~/serv00keep.sh
fi

# 设置定时任务 (5分钟一次)
(crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * /home/$(whoami)/serv00keep.sh > /dev/null 2>&1") | crontab -

echo "------------------------------------------------"
echo "恭喜！超级全家桶配置已全部完成。"
echo "1. 节点安装流程已结束。"
echo "2. Alist 已安装，管理账号: admin 密码: admin123"
echo "3. 双重保活已设为每 5 分钟巡逻一次。"
echo "------------------------------------------------"
