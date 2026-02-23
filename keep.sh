#!/bin/bash

# 变量配置
USER=$(whoami)
WORKDIR="${HOME}/domains/${USER}.serv00.net/logs"
MY_USER="tujiaojie"
MY_REPO="myserv00"

# 确保二进制文件有执行权限
chmod +x ${HOME}/bin/* > /dev/null 2>&1

while true; do
    # 1. 检查 Sing-box 进程
    if ! pgrep -u $USER -x "web" > /dev/null && ! pgrep -u $USER -x "bot" > /dev/null; then
        echo "检测到服务掉线，正在重新启动..."
        # 尝试运行本地保存的快捷启动（sb是原脚本创建的别名）
        /usr/local/bin/bash -c "source ~/.bashrc && sb" > /dev/null 2>&1
    fi

    # 2. 检查并同步自己的资源
    if [ ! -f "$HOME/app.js" ]; then
        curl -sL "https://raw.githubusercontent.com/$MY_USER/$MY_REPO/main/app.js" -o "$HOME/app.js"
    fi

    # 3. 这里的 300 秒可以根据需要调整，建议 5-10 分钟检查一次
    sleep 300
done
