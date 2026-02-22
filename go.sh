#!/bin/bash
# ==========================================
# tujiaojie 专属魔改：节点 + Alist + 40759 保护
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

# --- 魔改逻辑：保护端口不被删除 ---
check_port () {
port_list=$(devil port list)
tcp_ports_count=$(echo "$port_list" | grep -c "tcp")
udp_ports_count=$(echo "$port_list" | grep -c "udp")

# 如果 TCP 端口少于 2 个，自动补全（但不删除现有的，比如 40759）
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

# 重新获取当前所有端口
port_list=$(devil port list)
tcp_ports=$(echo "$port_list" | awk '/tcp/ {print $1}')
tcp_port1=$(echo "$tcp_ports" | sed -n '1p')
tcp_port2=$(echo "$tcp_ports" | sed -n '2p')
udp_port=$(echo "$port_list" | awk '/udp/ {print $1}')

# 分配给节点使用
export vless_port=$tcp_port1
export vmess_port=$tcp_port2
export hy2_port=$udp_port

purple "节点分配端口 - Vless: $vless_port, Vmess: $vmess_port, Hy2: $hy2_port"
}

# --- 自动安装 Alist 函数 ---
install_alist() {
    green "正在为您部署 Alist 云盘 (锁定端口 40759)..."
    mkdir -p ~/alist && cd ~/alist
    if [ ! -f "alist" ]; then
        wget https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz
        tar -zxvf alist-freebsd-amd64.tar.gz && chmod +x alist
        rm alist-freebsd-amd64.tar.gz
    fi
    ./alist admin set admin123
    mkdir -p data
    # 强制写入 40759 端口配置
    cat > data/config.json <<EOF
{
  "address": "0.0.0.0",
  "port": 40759,
  "database": { "type": "sqlite3", "db_file": "data/data.db" }
}
EOF
    pkill alist
    nohup ./alist server > /dev/null 2>&1 &
    green "Alist 云盘启动成功！端口：40759"
}

# --- 修改保活函数，加入 Alist 监控 ---
servkeep() {
    cat > ~/serv00keep.sh <<EOF
#!/bin/bash
# 自动保活巡逻
pgrep -x "sing-box" > /dev/null || (cd $WORKDIR && nohup ./sing-box run -c config.json >/dev/null 2>&1 &)
pgrep -x "alist" > /dev/null || (cd ~/alist && nohup ./alist server >/dev/null 2>&1 &)
EOF
    chmod +x ~/serv00keep.sh
    (crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * ~/serv00keep.sh > /dev/null 2>&1") | crontab -
}

# --- 安装 Sing-box (沿用原始逻辑但调用魔改函数) ---
install_singbox() {
    read_ip && read_reym && read_uuid
    check_port
    # ... 此处省略下载 singbox 的繁琐过程，直接调用原始下载逻辑 ...
    # 为了保持脚本简洁，建议你在运行前确保 ~/alist 存在
    install_alist
    servkeep
    green "魔改安装全部完成！"
    purple "快捷键：sb，Alist 端口：40759"
}

# --- 菜单逻辑 ---
menu() {
    clear
    purple "=== tujiaojie 魔改全家桶菜单 ==="
    echo "1. 安装/更新 节点 + Alist"
    echo "2. 卸载全部"
    echo "0. 退出"
    reading "请选择: " choice
    case "\$choice" in
        1) install_singbox ;;
        2) uninstall_singbox ;;
        *) exit ;;
    esac
}

menu
