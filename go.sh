#!/bin/bash
# =========================================================
# tujiaojie 专属魔改版 (完全体：节点+Alist+40759保护+5分保活)
# =========================================================

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

# --- [函数 1: 基础交互] ---
read_ip() {
    # 自动获取当前服务器可用IP
    local_ip=$(dig @8.8.8.8 +short "$HOSTNAME" | head -n 1)
    reading "请输入节点IP (默认使用当前服务器IP: $local_ip): " IP
    [[ -z "$IP" ]] && IP=$local_ip
    echo "$IP" > $WORKDIR/ipone.txt
    green "已选择IP: $IP"
}

read_uuid() {
    reading "请输入UUID密码 (回车随机): " UUID
    [[ -z "$UUID" ]] && UUID=$(uuidgen -r)
    echo "$UUID" > $WORKDIR/UUID.txt
    green "UUID: $UUID"
}

read_reym() {
    reading "请输入Reality域名 (回车默认 $USERNAME.${address}): " reym
    [[ -z "$reym" ]] && reym=$USERNAME.${address}
    echo "$reym" > $WORKDIR/reym.txt
    green "Reality域名: $reym"
}

# --- [函数 2: 端口保护 (锁定40759)] ---
check_port () {
    port_list=$(devil port list)
    tcp_ports_count=$(echo "$port_list" | grep -c "tcp")
    udp_ports_count=$(echo "$port_list" | grep -c "udp")

    if [[ $tcp_ports_count -lt 2 ]]; then
        yellow "TCP端口不足，正在自动申请..."
        added=0
        while [[ $added -lt $((2 - tcp_ports_count)) ]]; do
            p=$(shuf -i 10000-65535 -n 1)
            [[ "$p" == "40759" ]] && continue
            if devil port add tcp $p > /dev/null 2>&1; then
                added=$((added + 1))
            fi
        done
    fi

    if [[ $udp_ports_count -lt 1 ]]; then
        while true; do
            up=$(shuf -i 10000-65535 -n 1)
            [[ "$up" == "40759" ]] && continue
            if devil port add udp $up > /dev/null 2>&1; then break; fi
        done
    fi

    port_list=$(devil port list)
    tcp_ports_final=$(echo "$port_list" | grep "tcp" | awk '{print $1}' | grep -v "40759")
    export vless_port=$(echo "$tcp_ports_final" | sed -n '1p')
    export vmess_port=$(echo "$tcp_ports_final" | sed -n '2p')
    export hy2_port=$(echo "$port_list" | awk '/udp/ {print $1}')
    green "端口就绪：Vless:$vless_port | Vmess:$vmess_port | Hy2:$hy2_port"
}

# --- [函数 3: Argo隧道配置] ---
argo_configure() {
    yellow "正在配置 Argo 隧道 (默认使用临时隧道)..."
    # 默认静默选择临时隧道以提高自动化
    echo "临时隧道" > $WORKDIR/argo_type.log
    rm -rf $WORKDIR/boot.log
}

# --- [函数 4: 下载并运行节点核心] ---
download_and_run_singbox() {
    cd $WORKDIR
    green "正在下载 Sing-box 核心..."
    # 下载勇哥发布的 FreeBSD 预编译版
    curl -L -sS -o web https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/sb
    curl -L -sS -o bot https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/server
    chmod +x web bot
    echo "web" > sb.txt
    echo "bot" > ag.txt

    # 生成 Reality 密钥对
    output=$(./web generate reality-keypair)
    private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
    public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')
    
    # 简化版 config.json 生成逻辑
    cat > config.json <<EOF
{
  "log": {"level": "info"},
  "inbounds": [
    {"tag": "vless-in", "type": "vless", "listen": "::", "listen_port": $vless_port, "users": [{"uuid": "$UUID", "flow": "xtls-rprx-vision"}], "tls": {"enabled": true, "server_name": "$reym", "reality": {"enabled": true, "handshake": {"server": "$reym", "server_port": 443}, "private_key": "$private_key", "short_id": [""]}}},
    {"tag": "vmess-in", "type": "vmess", "listen": "::", "listen_port": $vmess_port, "users": [{"uuid": "$UUID"}], "transport": {"type": "ws", "path": "/$UUID-vm"}},
    {"tag": "hy2-in", "type": "hysteria2", "listen": "::", "listen_port": $hy2_port, "users": [{"password": "$UUID"}], "tls": {"enabled": true, "certificate_path": "cert.pem", "key_path": "private.key"}}
  ],
  "outbounds": [{"type": "direct"}]
}
EOF
    # 生成自签名证书供 Hy2 使用
    openssl ecparam -genkey -name prime256v1 -out "private.key"
    openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=$USERNAME" > /dev/null 2>&1

    # 启动
    nohup ./web run -c config.json >/dev/null 2>&1 &
    nohup ./bot tunnel --url http://localhost:$vmess_port --no-autoupdate --logfile boot.log --loglevel info >/dev/null 2>&1 &
    green "节点核心进程已启动"
}

# --- [函数 5: Alist 部署] ---
install_alist() {
    green "正在同步部署 Alist 云盘 (40759)..."
    mkdir -p ~/alist && cd ~/alist
    wget -q https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz
    tar -zxvf alist-freebsd-amd64.tar.gz >/dev/null && chmod +x alist
    ./alist admin set admin123 >/dev/null
    cat > data/config.json <<EOF
{"address": "0.0.0.0", "port": 40759}
EOF
    nohup ./alist server > /dev/null 2>&1 &
}

# --- [函数 6: 5分钟巡逻保活] ---
servkeep() {
    cat > ~/serv00keep.sh <<EOF
#!/bin/bash
pgrep -x "web" > /dev/null || (cd $WORKDIR && nohup ./web run -c config.json >/dev/null 2>&1 &)
pgrep -x "alist" > /dev/null || (cd ~/alist && nohup ./alist server >/dev/null 2>&1 &)
EOF
    chmod +x ~/serv00keep.sh
    (crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * ~/serv00keep.sh > /dev/null 2>&1") | crontab -
}

# --- [主入口] ---
install_main() {
    read_ip && read_reym && read_uuid && check_port
    argo_configure
    download_and_run_singbox
    install_alist
    servkeep
    echo -e "${green}======================================${re}"
    echo -e "${purple}   安装完成！节点已启动，Alist已在40759运行   ${re}"
    echo -e "${green}======================================${re}"
}

# --- [菜单] ---
clear
echo -e "${purple}=== tujiaojie 魔改全家桶 ===${re}"
echo "1. 完整安装 (节点+Alist+保活)"
echo "2. 一键卸载"
echo "0. 退出"
reading "选择: " choice
case "$choice" in
    1) install_main ;;
    2) pkill -u $(whoami); rm -rf ~/alist ~/domains/* ~/serv00keep.sh; green "已卸载" ;;
    *) exit ;;
esac
