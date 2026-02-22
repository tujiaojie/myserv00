#!/bin/bash
# ==========================================
# tujiaojie 专属魔改：完整节点 + Alist 40759 保护
# ==========================================
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }
USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
snb=$(hostname | cut -d. -f1)
nb=$(hostname | cut -d '.' -f 1 | tr -d 's')
HOSTNAME=$(hostname)
hona=$(hostname | cut -d. -f2)

if [ "$hona" = "serv00" ]; then
address="serv00.net"
keep_path="${HOME}/domains/${snb}.${USERNAME}.serv00.net/public_nodejs"
[ -d "$keep_path" ] || mkdir -p "$keep_path"
else
address="useruno.com"
fi
WORKDIR="${HOME}/domains/${USERNAME}.${address}/logs"
devil www add ${USERNAME}.${address} php > /dev/null 2>&1
FILE_PATH="${HOME}/domains/${USERNAME}.${address}/public_html"
[ -d "$FILE_PATH" ] || mkdir -p "$FILE_PATH"
[ -d "$WORKDIR" ] || (mkdir -p "$WORKDIR" && chmod 777 "$WORKDIR")
devil binexec on >/dev/null 2>&1

# --- 1. 核心魔改：保护 40759 不被删除 ---
check_port () {
port_list=$(devil port list)
tcp_ports_count=$(echo "$port_list" | grep -c "tcp")
if [[ $tcp_ports_count -lt 2 ]]; then
    yellow "检测到可用端口不足，正在为您申请新端口..."
    added=0
    target=$((2 - tcp_ports_count))
    while [[ $added -lt $target ]]; do
        new_p=$(shuf -i 10000-65535 -n 1)
        if devil port add tcp $new_p > /dev/null 2>&1; then
            green "成功添加端口: $new_p"
            added=$((added + 1))
        fi
    done
fi
port_list=$(devil port list)
tcp_ports=$(echo "$port_list" | awk '/tcp/ {print $1}')
export vless_port=$(echo "$tcp_ports" | sed -n '1p')
export vmess_port=$(echo "$tcp_ports" | sed -n '2p')
export hy2_port=$(echo "$port_list" | awk '/udp/ {print $1}')
purple "端口已就绪 - Vless: $vless_port, Vmess: $vmess_port, Hy2: $hy2_port"
}

# --- 2. 自动安装 Alist (锁定 40759) ---
install_alist() {
    green "正在部署 Alist 云盘..."
    mkdir -p ~/alist && cd ~/alist
    if [ ! -f "alist" ]; then
        wget https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz
        tar -zxvf alist-freebsd-amd64.tar.gz && chmod +x alist
    fi
    ./alist admin set admin123
    mkdir -p data
    echo '{"address": "0.0.0.0", "port": 40759}' > data/config.json
    pkill alist
    nohup ./alist server > /dev/null 2>&1 &
    green "Alist 启动成功，地址: http://你的IP:40759"
}

# --- 3. 这里的 install_singbox 是从你给的勇哥代码缝合过来的 ---
install_singbox() {
    # 这一行下载勇哥原始的安装脚本并执行，但通过 sed 屏蔽它的删除动作
    curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh -o serv_temp.sh
    sed -i 's/devil port del/echo "skip"/g' serv_temp.sh
    # 直接运行勇哥的安装流程
    bash serv_temp.sh
    # 节点装完后，立刻补上我们的 Alist
    install_alist
    # 强化保活
    (crontab -l 2>/dev/null | grep -v "alist"; echo "*/5 * * * * pgrep -x alist > /dev/null || (cd ~/alist && nohup ./alist server >/dev/null 2>&1 &)") | crontab -
}

# --- 4. 菜单逻辑 ---
clear
purple "=== tujiaojie 魔改全家桶菜单 ==="
echo "1. 安装/更新 节点 + Alist"
echo "2. 卸载全部"
echo "0. 退出"
reading "请选择: " choice
case "$choice" in
    1) install_singbox ;;
    2) pkill -u $(whoami); rm -rf ~/alist ~/domains/* ;;
    *) exit ;;
esac
