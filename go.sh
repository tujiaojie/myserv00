#!/bin/bash
# =========================================================
# tujiaojie 专属订阅版 (修复 EOF 语法错误 + 自动生成订阅链接)
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
HOSTNAME=$(hostname)
hona=$(hostname | cut -d. -f2)

if [ "$hona" = "serv00" ]; then
    address="serv00.net"
else
    address="useruno.com"
fi

# 核心路径定义
FILE_PATH="${HOME}/domains/${USERNAME}.${address}/public_html"
WORKDIR="${HOME}/domains/${USERNAME}.${address}/logs"
[ -d "$FILE_PATH" ] || mkdir -p "$FILE_PATH"
[ -d "$WORKDIR" ] || mkdir -p "$WORKDIR"
devil binexec on >/dev/null 2>&1

# --- 基础配置收集 ---
read_ip() {
    IP=$(dig @8.8.8.8 +short "$HOSTNAME" | head -n 1)
    reading "请输入节点IP (回车默认 $IP): " input_ip
    [[ -n "$input_ip" ]] && IP=$input_ip
}

read_uuid() {
    reading "请输入UUID (回车随机): " UUID
    [[ -z "$UUID" ]] && UUID=$(uuidgen -r)
}

read_reym() {
    reading "请输入Reality域名 (回#车默认 $USERNAME.${address}): " reym
    [[ -z "$reym" ]] && reym=$USERNAME.${address}
}

# --- 端口保护 (跳过40759) ---
check_port () {
    port_list=$(devil port list)
    tcp_ports=$(echo "$port_list" | grep "tcp" | awk '{print $1}' | grep -v "40759")
    export vless_port=$(echo "$tcp_ports" | sed -n '1p')
    export vmess_port=$(echo "$tcp_ports" | sed -n '2p')
    export hy2_port=$(echo "$port_list" | awk '/udp/ {print $1}')
}

# --- 节点程序安装 ---
install_node() {
    cd $WORKDIR
    green "正在同步勇哥内核..."
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
    {"tag": "vl", "type": "vless", "listen": "::", "listen_port": $vless_port, "users": [{"uuid": "$UUID", "flow": "xtls-rprx-vision"}], "tls": {"enabled": true, "server_name": "$reym", "reality": {"enabled": true, "handshake": {"server": "$reym", "server_port": 443}, "private_key": "$private_key", "short_id": [""]}}},
    {"tag": "vm", "type": "vmess", "listen": "::", "listen_port": $vmess_port, "users": [{"uuid": "$UUID"}], "transport": {"type": "ws", "path": "/$UUID-vm"}},
    {"tag": "hy", "type": "hysteria2", "listen": "::", "listen_port": $hy2_port, "users": [{"password": "$UUID"}], "tls": {"enabled": true, "certificate_path": "cert.pem", "key_path": "private.key"}}
  ],
  "outbounds": [{"type": "direct"}]
}
EOF
    nohup ./web run -c config.json >/dev/null 2>&1 &
    nohup ./bot tunnel --url http://localhost:$vmess_port --no-autoupdate --logfile boot.log --loglevel info >/dev/null 2>&1 &
    sleep 3
}

# --- Alist 安装 ---
install_alist() {
    green "正在部署 Alist 并锁定 40759..."
    mkdir -p ~/alist && cd ~/alist
    [ -f "alist" ] || (wget -q https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz && tar -zxvf alist-freebsd-amd64.tar.gz >/dev/null)
    chmod +x alist
    ./alist admin set admin123 >/dev/null
    echo '{"address": "0.0.0.0", "port": 40759}' > data/config.json
    pkill alist
    nohup ./alist server > /dev/null 2>&1 &
}

# --- 保活巡逻 (已修复 EOF 语法) ---
servkeep() {
    cat > ~/serv00keep.sh << 'EOF'
#!/bin/bash
USERNAME=$(whoami)
WORKDIR=$(find ${HOME}/domains -type d -name "logs" | head -n 1)
AL
