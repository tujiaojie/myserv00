#!/bin/bash
# =========================================================
# tujiaojie 订阅版 (节点订阅 + Alist + 40759 + 5分保活)
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

# 网页根目录，用于存放订阅文件
FILE_PATH="${HOME}/domains/${USERNAME}.${address}/public_html"
WORKDIR="${HOME}/domains/${USERNAME}.${address}/logs"
[ -d "$FILE_PATH" ] || mkdir -p "$FILE_PATH"
[ -d "$WORKDIR" ] || mkdir -p "$WORKDIR"
devil binexec on >/dev/null 2>&1

# --- 交互 ---
read_ip() {
    IP=$(dig @8.8.8.8 +short "$HOSTNAME" | head -n 1)
    reading "请输入节点IP (回车默认: $IP): " input_ip
    [[ -n "$input_ip" ]] && IP=$input_ip
}

read_uuid() {
    reading "请输入UUID密码 (回车随机): " UUID
    [[ -z "$UUID" ]] && UUID=$(uuidgen -r)
}

read_reym() {
    reading "请输入Reality域名 (回车默认 $USERNAME.${address}): " reym
    [[ -z "$reym" ]] && reym=$USERNAME.${address}
}

# --- 端口保护 (锁定40759) ---
check_port () {
    port_list=$(devil port list)
    tcp_ports=$(echo "$port_list" | grep "tcp" | awk '{print $1}' | grep -v "40759")
    export vless_port=$(echo "$tcp_ports" | sed -n '1p')
    export vmess_port=$(echo "$tcp_ports" | sed -n '2p')
    export hy2_port=$(echo "$port_list" | awk '/udp/ {print $1}')
}

# --- 核心安装 ---
download_and_run_singbox() {
    cd $WORKDIR
    curl -L -sS -o web https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/sb
    curl -L -sS -o bot https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/server
    chmod +x web bot
    output=$(./web generate reality-keypair)
    private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
    export public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')
    
    openssl ecparam -genkey -name prime256v1 -out "private.key"
    openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=$USERNAME" > /dev/null 2>&1

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
}

# --- 订阅文件生成与展示 ---
generate_subscription() {
    argodomain=$(cat $WORKDIR/boot.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
    [[ -z "$argodomain" ]] && argodomain="argo.waiting.com"

    # 生成各协议链接
    vl="vless://$UUID@$IP:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$snb-Reality"
    hy="hysteria2://$UUID@$IP:$hy2_port?security=tls&sni=www.bing.com&alpn=h3&insecure=1#$snb-Hy2"
    vm_json="{ \"v\": \"2\", \"ps\": \"$snb-Argo\", \"add\": \"www.visa.com.hk\", \"port\": \"8443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\"}"
    vm="vmess://$(echo "$vm_json" | base64 -w0)"

    # 写入文件并进行 Base64 编码（勇哥标准）
    echo -e "$vl\n$hy\n$vm" > $WORKDIR/links.txt
    base64 -w 0 $WORKDIR/links.txt > ${FILE_PATH}/${UUID}_v2sub.txt

    # 结果展示
    clear
    purple "=========================================="
    green "  🎉 安装成功！你的节点信息如下："
    purple "=========================================="
    yellow "🔗 你的通用订阅链接 (直接填入客户端):"
    green "https://${USERNAME}.${address}/${UUID}_v2sub.txt"
    echo
    yellow "🌐 Alist 管理地址 (端口 40759):"
    green "http://${USERNAME}.${address}:40759 (初始密码: admin123)"
    purple "=========================================="
    echo "提示：如果订阅链接打不开，请检查 Serv00 面板 WWW 列表是否已添加该域名。"
}

# --- Alist & 保活 ---
install_alist() {
    mkdir -p ~/alist && cd ~/alist
    wget -q https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz
    tar -zxvf alist-freebsd-amd64.tar.gz >/dev/null && chmod +x alist
    ./alist admin set admin123 >/dev/null
    echo '{"address": "0.0.0.0", "port": 40759}' > data/config.json
    pkill alist
    nohup ./alist server > /dev/null 2>&1 &
}

servkeep() {
    cat > ~/serv00keep.sh <<EOF
#!/bin/bash
pgrep -x "web" > /dev/null || (cd $WORKDIR && nohup ./web run -c config.json >/dev/null 2>&1 &)
pgrep -x "alist" > /dev/null || (cd ~/alist && nohup ./alist server >/dev/null
