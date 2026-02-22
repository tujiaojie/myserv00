#!/bin/bash

# ==========================================
# 你的专属一键全家桶：节点 + Alist(40759端口) + 自动保活
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

# --- 2.5 核心步骤：预设端口并启动 ---
echo "正在配置专属端口 40759..."
./alist admin set admin123
# 先生成配置文件
nohup ./alist server > /dev/null 2>&1 &
sleep 2
pkill alist
# 强制将默认的 5244 替换为 40759
if [ -f "~/alist/data/config.json" ]; then
    sed -i 's/5244/40759/g' ~/alist/data/config.json
fi
# 重新启动
nohup ./alist server > /dev/null 2>&1 &

# --- 3. 配置自动保活 (节点 + Alist) ---
echo "第三步：正在配置全自动双重保活系统..."
curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00keep.sh -o ~/serv00keep.sh
chmod +x ~/serv00keep.sh

# 关键：修改保活脚本，让它以后也用 40759 端口检查启动
if ! grep -q "alist" ~/serv00keep.sh; then
    echo 'if ! pgrep -x "alist" > /dev/null; then cd ~/alist && nohup ./alist server > /dev/null 2>&1 & fi' >> ~/serv00keep.sh
fi

# 设置定时任务 (5分钟一次)
(crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * /home/$(whoami)/serv00keep.sh > /dev/null 2>&1") | crontab -

echo "------------------------------------------------"
echo "恭喜！超级全家桶配置已全部完成。"
echo "1. 节点安装流程已结束。"
echo "2. Alist 已安装并运行在端口: 40759"
echo "3. 管理账号: admin 密码: admin123"
echo "4. 双重保活已设为每 5 分钟巡逻一次。"
echo "------------------------------------------------"
