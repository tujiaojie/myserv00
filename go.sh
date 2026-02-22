#!/bin/bash
# ==========================================
# 你的专属魔改版：节点 + Alist(40759) + 永久保活
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

# --- 端口保护逻辑 (已修改) ---
check_port () {
port_list=$(devil port list)
tcp_ports=$(echo "$port_list" | grep -c "tcp")
udp_ports=$(echo "$port_list" | grep -c "udp")

# 【魔改点 1】: 禁止脚本自动删除 TCP 端口，保护你的 40759
if [[ $tcp_ports -lt 2 ]]; then
    green "检测到端口不足，正在尝试为您补全..."
    tcp_ports_to_add=$((2 - tcp_ports))
    tcp_ports_added=0
    while [[ $tcp_ports_added -lt $tcp_ports_to_add ]]; do
        tcp_port=$(shuf -i 10000-65535 -n 1) 
        result=$(devil port add tcp $tcp_port 2>&1)
        if [[ $result == *"succesfully"* ]]; then
            green "已添加TCP端口: $tcp_port"
            tcp_ports_added=$((tcp_ports_added + 1))
        fi
    done
fi

# 获取当前实际端口供节点使用
port_list=$(devil port list)
tcp_ports_list=$(echo "$port_list" | awk '/tcp/ {print $1}')
export vless_port=$(echo "$tcp_ports_list" | sed -n '1p')
export vmess_port=$(echo "$tcp_ports_list" | sed -n '2p')
# 如果你的 40759 刚好是前两个，节点会借用；如果是第三个，则不受干扰
export hy2_port=$(echo "$port_list" | awk '/udp/ {print $1}')
}

# --- Alist 自动安装逻辑 (新增) ---
install_alist() {
    green "正在同步安装 Alist 云盘..."
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
    green "Alist 已启动，端口: 40759"
}

# --- 注入保活巡逻 ---
servkeep() {
    # 此处省略原有的保活路径定义，直接追加 Alist 检查
    K_FILE="${HOME}/serv00keep.sh"
    # 如果原脚本生成了保活文件，我们强行插入 Alist 监控
    if [ -f "$K_FILE" ]; then
        if ! grep -q "alist" "$K_FILE"; then
            echo 'if ! pgrep -x "alist" > /dev/null; then cd ~/alist && nohup ./alist server > /dev/null 2>&1 & fi' >> "$K_FILE"
        fi
    fi
}

# --- 之后衔接原有的 install_singbox 等函数 ---
# (此处为你刚才粘贴的后续安装逻辑...)
