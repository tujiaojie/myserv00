#!/bin/bash

# ==========================================
# 你的专属一键全家桶：魔改避坑版
# ==========================================

# --- 1. 下载并魔改勇哥脚本 (防止它删你的 40759) ---
echo "正在下载并魔改安装脚本，锁定端口保护..."
curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh -o serv00_mod.sh

# 【关键魔改】: 把脚本里“删除端口”的指令直接注释掉，让它没权力删你的端口
sed -i 's/devil port list/echo "skip delete"/g' serv00_mod.sh
sed -i 's/devil port del/echo "skip delete"/g' serv00_mod.sh

# 运行魔改后的脚本
bash serv00_mod.sh

# --- 2. 安装 Alist 云盘 ---
echo "第二步：正在安装 Alist 私人云盘..."
mkdir -p ~/alist
cd ~/alist
wget https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz
tar -zxvf alist-freebsd-amd64.tar.gz
chmod +x alist
rm alist-freebsd-amd64.tar.gz

# 初始化密码并强行指定 40759 端口
./alist admin set admin123
# 预先创建配置文件夹，防止第一次启动失败
mkdir -p data
echo '{"address": "0.0.0.0", "port": 40759}' > data/config.json 

nohup ./alist server > /dev/null 2>&1 &

# --- 3. 配置全自动双重保活 ---
echo "第三步：配置保活巡逻..."
curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00keep.sh -o ~/serv00keep.sh
chmod +x ~/serv00keep.sh

# 确保保活脚本里也使用你的 40759
if ! grep -q "alist" ~/serv00keep.sh; then
    echo 'if ! pgrep -x "alist" > /dev/null; then cd ~/alist && nohup ./alist server > /dev/null 2>&1 & fi' >> ~/serv00keep.sh
fi

# 写入定时任务
(crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * /home/$(whoami)/serv00keep.sh > /dev/null 2>&1") | crontab -

echo "------------------------------------------------"
echo "恭喜！魔改全家桶配置完成。"
echo "现在勇哥脚本再也不会删你的 40759 端口了。"
echo "Alist 访问地址: http://你的IP:40759"
echo "------------------------------------------------"
