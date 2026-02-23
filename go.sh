#!/bin/bash
# =========================================================
# tujiaojie 专属终极版 (节点链接显示 + Alist + 40759 + 5分保活)
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
else
    address="useruno.com"
fi

WORKDIR="${HOME}/domains/${USERNAME}.${address}/logs"
[ -d "$WORKDIR" ] || mkdir -p "$WORKDIR"
devil binexec on >/dev/null 2>&1

# --- 基础交互 ---
read_ip() {
    IP=$(dig @8.8.8.8 +short "$HOSTNAME" | head -n 1)
    reading "请输入节点IP (默认回车: $IP): " input_ip
    [[ -n "$input_ip" ]] && IP=$input_ip
    echo "$IP" > $WORKDIR/ipone.txt
}

read_uuid() {
    reading "请输入统一UUID (回车随机): " UUID
    [[ -z "$UUID" ]] && UUID=$(uuidgen -r)
    echo "$UUID" > $WORKDIR/UUID.txt
}

read_reym() {
    reading "请输入Reality域名 (回车默认 $USERNAME.${address}): " reym
    [[ -z "$reym" ]] && reym=$USERNAME.${address}
    echo "$reym" > $WORKDIR/reym.txt
}

# --- 端口保护 (锁定40759) ---
check_port () {
    port_list=$(devil port list)
    tcp_ports=$(echo "$port_list" | grep "tcp" | awk '{print $1}' | grep -v "40759")
    export vless_port=$(echo "$tcp_ports" | sed -n '1p')
    export vmess_port=$(echo "$tcp_ports" | sed -n '2p')
    export hy2_port=$(echo "$port_list" | awk '/udp/ {print $1}')
    
    if [[ -z "$vless_port" || -z "$vmess_port" ]]; then
        red "端口不足，请先在面板手动多开几个TCP端口！"
        exit 1
    fi
}

# --- 节点安装 ---
download_and_run_singbox() {
    cd $WORKDIR
    green "正在下载勇哥核心文件..."
    curl -L -sS -o web https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/sb
    curl -L -sS -o bot https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/server
    chmod +x web bot
    echo "web" > sb.txt
    
    # 生成 Reality 密钥
    output=$(./web generate reality-keypair)
    private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
    export public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')
    
    # 证书
    openssl ecparam -genkey -name prime256v1 -out "private.key"
    openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=$USERNAME" > /dev/null 2>&1

    # 写配置
    cat > config.json <<EOF
{
  "log": {"level": "info"},
  "inbounds": [
    {"tag": "vless", "type": "vless", "listen": "::", "listen_port": $vless_port, "users": [{"uuid": "$UUID", "flow": "xtls-rprx-vision"}], "tls": {"enabled": true, "server_name": "$reym", "reality": {"enabled": true, "handshake": {"server": "$reym", "server_port": 443}, "private_key": "$private_key", "short_id": [""]}}},
    {"tag": "vmess", "type": "vmess", "listen": "::", "listen_port": $vmess_port, "users": [{"uuid": "$UUID"}], "transport": {"type": "ws", "path": "/$UUID-vm"}},
    {"tag": "hy2", "type": "hysteria2", "listen": "::", "listen_port": $hy2_port, "users": [{"password": "$UUID"}], "tls": {"enabled": true, "certificate_path": "cert.pem", "key_path": "private.key"}}
  ],
  "outbounds": [{"type": "direct"}]
}
EOF
    nohup ./web run -c config.json >/dev/null 2>&1 &
    nohup ./bot tunnel --url http://localhost:$vmess_port --no-autoupdate --logfile boot.log --loglevel info >/dev/null 2>&1 &
    sleep 5
}

# --- 链接生成展示 (这是你最需要的) ---
show_links() {
    argodomain=$(cat boot.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
    [[ -z "$argodomain" ]] && argodomain="等待获取中..."

    clear
    purple "=========================================="
    green "  安装成功！以下是你的节点链接 (请妥善保存)"
    purple "=========================================="
    
    yellow "1. VLESS-Reality 链接:"
    echo "vless://$UUID@$IP:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$snb-Reality"
    echo
    
    yellow "2. Hysteria2 链接:"
    echo "hysteria2://$UUID@$IP:$hy2_port?security=tls&sni=www.bing.com&alpn=h3&insecure=1#$snb-Hy2"
    echo
    
    yellow "3. Vmess-Argo (临时隧道) 链接:"
    vmess_json="{ \"v\": \"2\", \"ps\": \"$snb-Argo\", \"add\": \"www.visa.com.hk\", \"port\": \"8443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\"}"
    echo "vmess://$(echo "$vmess_json" | base64 -w0)"
    echo
    
    purple "=========================================="
    green "Alist 状态: 运行中 (端口 40759)"
    green "Alist 密码: admin123"
    purple "=========================================="
}

# --- Alist 与 保活 ---
install_alist() {
    mkdir -p ~/alist && cd ~/alist
    wget -q https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz
    tar -zxvf alist-freebsd-amd64.tar.gz >/dev/null && chmod +x alist
    ./alist admin set admin123 >/dev/null
    echo '{"address": "0.0.0.0", "port": 40759}' > data/config.json
    nohup ./alist server > /dev/null 2>&1 &
}

servkeep() {
    cat > ~/serv00keep.sh <<EOF
#!/bin/bash
pgrep -x "web" > /dev/null || (cd $WORKDIR && nohup ./web run -c config.json >/dev/null 2>&1 &)
pgrep -x "alist" > /dev/null || (cd ~/alist && nohup ./alist server >/dev/null 2>&1 &)
EOF
    chmod +x ~/serv00keep.sh
    (crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * ~/serv00keep.sh > /dev/null 2>&1") | crontab -
}

# --- 菜单 ---
clear
echo "1. 完整安装并获取链接"
echo "0. 退出"
read -p "选择: " choice
if [[ "$choice" == "1" ]]; then
    read_ip && read_reym && read_uuid && check_port
    download_and_run_singbox
    install_alist
    servkeep
    show_links
else
    exit
fi
