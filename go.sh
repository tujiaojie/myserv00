#!/bin/bash
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

# ==========================================
# 魔改函数 1：保护端口 (禁止删除 40759)
# ==========================================
check_port () {
port_list=$(devil port list)
tcp_ports=$(echo "$port_list" | grep -c "tcp")
udp_ports=$(echo "$port_list" | grep -c "udp")

if [[ $tcp_ports -ne 2 || $udp_ports -ne 1 ]]; then
    # 注意：这里我们移除了原版中的删除逻辑，只保留添加逻辑
    if [[ $tcp_ports -lt 2 ]]; then
        tcp_ports_to_add=$((2 - tcp_ports))
        tcp_ports_added=0
        while [[ $tcp_ports_added -lt $tcp_ports_to_add ]]; do
            tcp_port=$(shuf -i 10000-65535 -n 1) 
            result=$(devil port add tcp $tcp_port 2>&1)
            [[ $result == *"succesfully"* ]] && tcp_ports_added=$((tcp_ports_added + 1))
        done
    fi
    if [[ $udp_ports -lt 1 ]]; then
        while true; do
            udp_port=$(shuf -i 10000-65535 -n 1) 
            result=$(devil port add udp $udp_port 2>&1)
            [[ $result == *"succesfully"* ]] && break
        done
    fi
    sleep 3
    port_list=$(devil port list)
fi
# 重新抓取端口供节点使用
tcp_ports_final=$(echo "$port_list" | awk '/tcp/ {print $1}')
export vless_port=$(echo "$tcp_ports_final" | sed -n '1p')
export vmess_port=$(echo "$tcp_ports_final" | sed -n '2p')
export hy2_port=$(echo "$port_list" | awk '/udp/ {print $1}')
green "端口保护模式已开启，当前分配：Vless:$vless_port Vmess:$vmess_port Hy2:$hy2_port"
}

# ==========================================
# 魔改函数 2：安装 Alist (锁定 40759)
# ==========================================
install_alist() {
    green "正在为您部署 Alist 云盘..."
    mkdir -p ~/alist && cd ~/alist
    if [ ! -f "alist" ]; then
        wget https://github.com/AlistGo/alist/releases/latest/download/alist-freebsd-amd64.tar.gz
        tar -zxvf alist-freebsd-amd64.tar.gz && chmod +x alist
    fi
    ./alist admin set admin123
    mkdir -p data
    cat > data/config.json <<EOF
{
  "force": false,
  "address": "0.0.0.0",
  "port": 40759,
  "database": { "type": "sqlite3", "db_file": "data/data.db" }
}
EOF
    pkill alist
    nohup ./alist server > /dev/null 2>&1 &
    green "Alist 安装成功！端口: 40759，密码: admin123"
}

# --- 之后是勇哥原版的其余函数 (已注入保活魔改) ---
# ... (此处省略中间重复的 read_ip, read_uuid 等函数，代码逻辑保持原样) ...

# 这里是安装的主入口
install_singbox() {
    if [[ -e $WORKDIR/list.txt ]]; then yellow "已安装，请先卸载" && exit; fi
    read_ip && read_reym && read_uuid && check_port
    # 此处执行原版的下载与配置逻辑...
    # [这里插入原版下载代码]
    
    # 注入 Alist 安装
    install_alist
    
    # 注入保活
    servkeep
    green "全部安装完成！输入 sb 呼出菜单"
}

# 修改保活逻辑
servkeep() {
    cat > ~/serv00keep.sh <<EOF
#!/bin/bash
pgrep -x "sing-box" > /dev/null || (cd $WORKDIR && nohup ./sing-box run -c config.json >/dev/null 2>&1 &)
pgrep -x "alist" > /dev/null || (cd ~/alist && nohup ./alist server >/dev/null 2>&1 &)
EOF
    chmod +x ~/serv00keep.sh
    (crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * ~/serv00keep.sh > /dev/null 2>&1") | crontab -
}

# (此处补全你刚才发给我的 menu, uninstall 等剩余代码
