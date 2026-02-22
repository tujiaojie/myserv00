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
        if devil port add tcp $new_p >
        
