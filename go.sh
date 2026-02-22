#!/bin/bash

# ==========================================
# tujiaojie 专属魔改版 (基于勇哥原版)
# 功能：Sing-box全协议 + Alist + 40759端口保护
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

# --- 魔改函数 1：保护端口 (禁止删除任何已有端口，包括 40759) ---
check_port () {
    port_list=$(devil port list)
    tcp_ports_count=$(echo "$port_list" | grep -c "tcp")
    udp_ports_count=$(echo "$port_list" | grep -c "udp")

    # 只有在端口不足时才添加，绝不删除
    if [[ $tcp_ports_count -lt 2 ]]; then
        yellow "检测到TCP端口不足，正在自动申请..."
        added=0
        while [[ $added -lt $((2 - tcp_ports_count)) ]]; do
            p=$(shuf -i 10000-65535 -n 1)
            if devil port add tcp $p > /dev/null 2>&1; then
                green "已添加TCP端口: $p"
                added=$((added + 1))
            fi
        done
    fi

    if [[ $udp_ports_count -lt 1 ]]; then
        while true; do
            up=$(shuf -i 10000-65535 -n 1)
            if devil port add udp $up > /dev/null 2>&1; then
                green "已添加UDP端口: $up"
                break
            fi
        done
    fi

    # 抓取端口供节点使用
    port_list=$(devil port list)
    tcp_ports=$(echo "$port_list" | awk '/tcp/ {print $1}')
    export vless_port=$(echo "$tcp_ports" | sed -n '1p')
    export vmess_port=$(echo "$tcp_ports" | sed -n '2p')
    export hy2_port=$(echo "$port_list" | awk '/udp/ {print $1}')
    
    purple "当前分配：Vless:$vless_port | Vmess:$vmess_port | Hy2:$hy2_port"
}

# --- 魔改函数 2：安装 Alist 并锁定 40759 ---
install_alist() {
    green "正在同步部署 Alist 云盘 (40759 端口)..."
    mkdir -p ~/alist && cd ~/alist
    if [ ! -f "alist" ]; then
        wget https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz
        tar -zxvf alist-freebsd-amd64.tar.gz && chmod +x alist
        rm alist-freebsd-amd64.tar.gz
    fi
    ./alist admin set admin123
    mkdir -p data
    cat > data/config.json <<EOF
{
  "address": "0.0.0.0",
  "port": 40759,
  "database": { "type": "sqlite3", "db_file": "data/data.db" }
}
EOF
    pkill alist
    nohup ./alist server > /dev/null 2>&1 &
    green "Alist 云盘启动成功！端口: 40759"
}

# --- 注入保活巡逻 ---
servkeep() {
    cat > ~/serv00keep.sh <<EOF
#!/bin/bash
# 自动巡逻脚本
pgrep -x "sing-box" > /dev/null || (cd $WORKDIR && nohup ./sing-box run -c config.json >/dev/null 2>&1 &)
pgrep -x "alist" > /dev/null || (cd ~/alist && nohup ./alist server >/dev/null 2>&1 &)
EOF
    chmod +x ~/serv00keep.sh
    (crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * ~/serv00keep.sh > /dev/null 2>&1") | crontab -
}

# --- 节点下载与运行 (缝合原版代码) ---
download_and_run_singbox() {
    # 此处省略原版中超长的文件下载/配置生成部分，为了演示直接引导流程
    # 实际运行时请确保你的代码包含原版的 config.json 生成逻辑
    green "正在配置 Sing-box 核心组件..."
    # ... 原版核心逻辑 ...
}

# --- 菜单界面 ---
menu() {
    clear
    purple "=========================================="
    purple "   tujiaojie 魔改全家桶 (节点+Alist)      "
    purple "=========================================="
    echo -e "1. ${green}完整安装 (节点 + Alist)${re}"
    echo -e "2. ${red}一键卸载${re}"
    echo -e "
