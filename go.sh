#!/bin/bash
# =========================================================
# tujiaojie 专属订阅版 (结构扁平化修复版)
# =========================================================

re="\033[0m"; red="\033[1;91m"; green="\e[1;32m"; yellow="\e[1;33m"; purple="\e[1;35m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }

USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
snb=$(hostname | cut -d. -f1)
HOSTNAME=$(hostname)
hona=$(hostname | cut -d. -f2)
[ "$hona" = "serv00" ] && address="serv00.net" || address="useruno.com"

FILE_PATH="${HOME}/domains/${USERNAME}.${address}/public_html"
WORKDIR="${HOME}/domains/${USERNAME}.${address}/logs"
[ -d "$FILE_PATH" ] || mkdir -p "$FILE_PATH"
[ -d "$WORKDIR" ] || mkdir -p "$WORKDIR"
devil binexec on >/dev/null 2>&1

# --- 基础配置 ---
read_config() {
    IP=$(dig @8.8.8.8 +short "$HOSTNAME" | head -n 1)
    reading "请输入节点IP (回车默认 $IP): " input_ip
    [[ -n "$input_ip" ]] && IP=$input_ip
    reading "请输入UUID (回车随机): " UUID
    [[ -z "$UUID" ]] && UUID=$(uuidgen -r)
    reading "请输入Reality域名 (回车默认 $USERNAME.${address}): " reym
    [[ -z "$reym" ]] && reym=$USERNAME.${address}
}

# --- 端口保护 ---
check_port () {
    port_list=$(devil port list)
    tcp_ports=$(echo "$port_list" | grep "tcp" | awk '{print $1}' | grep -v "40759")
    export vless_port=$(echo "$tcp_ports" | sed -n '1p')
    export vmess_port=$(echo "$tcp_ports" | sed -n '2p')
    export hy2_port=$(echo "$port_list" | awk '/udp/ {print $1}')
}

# --- 节点安装 ---
install_node() {
    cd $WORKDIR
    curl -L -sS -o web https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/sb
    curl -L -sS -o bot https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/server
    chmod +x web bot
    output=$(./web generate reality-keypair)
    private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
    export public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')
    openssl ecparam -genkey -name prime256v1 -out "private.key"
    openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=$USERNAME" > /dev/null 2>&1

    echo "{\"log\":{\"level\":\"info\"},\"inbounds\":[{\"tag\":\"vl\",\"type\":\"vless\",\"listen\":\"::\",\"listen_port\":$vless_port,\"users\":[{\"uuid\":\"$UUID\",\"flow\":\"xtls-rprx-vision\"}],\"tls\":{\"enabled\":true,\"server_name\":\"$reym\",\"reality\":{\"enabled\":true,\"handshake\":{\"server\":\"$reym\",\"server_port\":443},\"private_key\":\"$private_key\",\"short_id\":[\"\"]}}},{\"tag\":\"vm\",\"type\":\"vmess\",\"listen\":\"::\",\"listen_port\":$vmess_port,\"users\":[{\"uuid\":\"$UUID\"}],\"transport\":{\"type\":\"ws\",\"path\":\"/$UUID-vm\"}},{\"tag\":\"hy\",\"type\":\"hysteria2\",\"listen\":\"::\",\"listen_port\":$hy2_port,\"users\":[{\"password\":\"$UUID\"}],\"tls\":{\"enabled\":true,\"certificate_path\":\"cert.pem\",\"key_path\":\"private.key\"}}],\"outbounds\":[{\"type\":\"direct\"}]}" > config.json

    nohup ./web run -c config.json >/dev/null 2>&1 &
    nohup ./bot tunnel --url http://localhost:$vmess_port --no-autoupdate --logfile boot.log --loglevel info >/dev/null 2>&1 &
    sleep 5
}

# --- Alist 与 巡逻保活 ---
install_alist_keep() {
    mkdir -p ~/alist && cd ~/alist
    [ -f "alist" ] || (wget -q https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz && tar -zxvf alist-freebsd-amd64.tar.gz >/dev/null)
    chmod +x alist
    ./alist admin set admin123 >/dev/null
    echo '{"address": "0.0.0.0", "port": 40759}' > data/config.json
    pkill alist
    nohup ./alist server > /dev/null 2>&1 &

    # 写入保活脚本 (改用 printf 避免 EOF 报错)
    printf "#!/bin/bash\npgrep -x \"web\" > /dev/null || (cd $WORKDIR && nohup ./web run -c config.json >/dev/null 2>&1 &)\npgrep -x \"alist\" > /dev/null || (cd ${HOME}/alist && nohup ./alist server >/dev/null 2>&1 &)\n" > ~/serv00keep.sh
    chmod +x ~/serv00keep.sh
    (crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * ~/serv00keep.sh > /dev/null 2>&1") | crontab -
}

# --- 生成结果 ---
show_all() {
    argodomain=$(grep -a trycloudflare.com $WORKDIR/boot.log | awk -F// '{print $2}' | awk '{print $1}' | head -n 1)
    [[ -z "$argodomain" ]] && argodomain="argo-not-ready.com"

    vl="vless://$UUID@$IP:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$snb-Vl"
    hy="hysteria2://$UUID@$IP:$hy2_port?security=tls&sni=www.bing.com&alpn=h3&insecure=1#$snb-Hy"
    vm_json="{ \"v\": \"2\", \"ps\": \"$snb-Ar\", \"add\": \"www.visa.com.hk\", \"port\": \"8443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\"}"
    vm="vmess://$(echo "$vm_json" | base64 -w0)"

    echo -e "$vl\n$hy\n$vm" > $WORKDIR/links.txt
    base64 -w 0 $WORKDIR/links.txt > ${FILE_PATH}/${UUID}_v2sub.txt

    clear
    purple "=========================================="
    green "  🎉 安装成功！"
    purple "=========================================="
    yellow "🔗 你的订阅链接 (导入客户端):"
    green "https://${USERNAME}.${address}/${UUID}_v2sub.txt"
    echo
    yellow "📂 Alist 管理地址 (端口 40759):"
    green "http://${USERNAME}.${address}:40759"
    green "初始密码: admin123"
    purple "=========================================="
}

# --- 主入口 ---
clear
echo "1. 完整安装 (节点+Alist+保活+订阅)"
echo "2. 卸载"
read -p "选择: " choice
case "$choice" in
    1) read_config; check_port; install_node; install_alist_keep; show_all ;;
    2) pkill -u $(whoami); rm -rf ~/alist ~/serv00keep.sh; green "已清理" ;;
    *) exit ;;
esac
