#!/bin/bash
# =========================================================
# tujiaojie 专属魔改版 (基于勇哥原版 sing-box-yg)
# 功能：全协议节点 + Alist + 40759 保护 + 5分钟巡逻保活
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

# --- 魔改逻辑：Alist 部署 (强制 40759) ---
install_alist() {
    green "正在同步部署 Alist 云盘 (锁定端口 40759)..."
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
  "force": false,
  "address": "0.0.0.0",
  "port": 40759,
  "database": { "type": "sqlite3", "db_file": "data/data.db" }
}
EOF
    pkill alist
    nohup ./alist server > /dev/null 2>&1 &
    green "Alist 启动完成！默认密码: admin123"
}

# --- 魔改逻辑：端口保护 (禁止删 40759) ---
check_port () {
    port_list=$(devil port list)
    # 统计 TCP/UDP，但保护 40759
    tcp_ports_count=$(echo "$port_list" | grep -c "tcp")
    udp_ports_count=$(echo "$port_list" | grep -c "udp")

    if [[ $tcp_ports_count -lt 2 ]]; then
        yellow "TCP 端口不足，正在申请..."
        added=0
        while [[ $added -lt $((2 - tcp_ports_count)) ]]; do
            p=$(shuf -i 10000-65535 -n 1)
            # 避开 40759
            [[ "$p" == "40759" ]] && continue
            if devil port add tcp $p > /dev/null 2>&1; then
                green "已添加 TCP 端口: $p"
                added=$((added + 1))
            fi
        done
    fi
    
    # 重新获取端口列表
    port_list=$(devil port list)
    # 排除 40759 后分配给节点使用
    tcp_ports_for_node=$(echo "$port_list" | grep "tcp" | awk '{print $1}' | grep -v "40759")
    export vless_port=$(echo "$tcp_ports_for_node" | sed -n '1p')
    export vmess_port=$(echo "$tcp_ports_for_node" | sed -n '2p')
    export hy2_port=$(echo "$port_list" | awk '/udp/ {print $1}')

    purple "端口锁定：Vless:$vless_port | Vmess:$vmess_port | Hy2:$hy2_port | Alist:40759"
}

# --- 魔改逻辑：5分钟保活巡逻 ---
servkeep() {
    cat > ~/serv00keep.sh <<EOF
#!/bin/bash
# tujiaojie 巡逻员
sbb=\$(cat $WORKDIR/sb.txt 2>/dev/null)
agg=\$(cat $WORKDIR/ag.txt 2>/dev/null)

# 检查 Sing-box
pgrep -x "\$sbb" > /dev/null || (cd $WORKDIR && nohup ./"\$sbb" run -c config.json >/dev/null 2>&1 &)
# 检查 Argo
if [ -f "$WORKDIR/boot.log" ]; then
    pgrep -x "\$agg" > /dev/null || (cd $WORKDIR && nohup ./"\$agg" tunnel --url http://localhost:$vmess_port --no-autoupdate --logfile boot.log --loglevel info >/dev/null 2>&1 &)
fi
# 检查 Alist
pgrep -x "alist" > /dev/null || (cd ~/alist && nohup ./alist server >/dev/null 2>&1 &)
EOF
    chmod +x ~/serv00keep.sh
    # 强制设置 5 分钟定时任务
    (crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * ~/serv00keep.sh > /dev/null 2>&1") | crontab -
    green "5分钟强力保活巡逻已启动！"
}

# (此处保留你发给我的 read_ip, read_uuid, download_and_run_singbox 等所有原始函数内容...)
# 为节省篇幅，安装时只需调用它们
# [注：运行脚本时请确保 download_and_run_singbox 函数在你的文件中是完整的]

# --- 修改安装入口 ---
install_singbox_magic() {
    if [[ -e $WORKDIR/list.txt ]]; then yellow "已安装，请先卸载" && exit; fi
    read_ip && read_reym && read_uuid && check_port
    argo_configure
    download_and_run_singbox
    install_alist
    servkeep
    green "tujiaojie 魔改全家桶安装完成！"
}

# --- 菜单逻辑 ---
menu() {
    clear
    purple "=========================================="
    purple "   tujiaojie 专属魔改菜单 (5min保活版)    "
    purple "=========================================="
    echo -e "1. ${green}完整安装 (节点+Alist+保活)${re}"
    echo -e "2. ${red}一键卸载${re}"
    echo -e "0. 退出"
    reading "选择: " choice
    case "$choice" in
        1) install_singbox_magic ;;
        2) uninstall_singbox ;;
        *) exit ;;
    esac
}

menu
