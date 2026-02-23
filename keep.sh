#!/bin/bash

# --- 修改这里 ---
MY_GITHUB_USER="你的用户名"
MY_GITHUB_REPO="你的仓库名"
# ----------------

USER=$(whoami)
WORKDIR="${HOME}/domains/${USER}.serv00.net/logs"

while true; do
    # 1. 检查 sing-box 进程
    if ! pgrep -u $USER -f "config.json" > /dev/null; then
        echo "Sing-box 挂了，正在从我的仓库恢复..."
        # 这里写启动 sing-box 的命令，例如：
        # cd $WORKDIR && ./sb run -c config.json >/dev/null 2>&1 &
    fi

    # 2. 检查 Argo 进程
    if ! pgrep -u $USER -f "tunnel" > /dev/null; then
        echo "Argo 挂了，正在恢复..."
        # 这里写启动 Argo 的命令
    fi

    # 3. 确保 app.js 存在 (从你自己仓库更新)
    if [ ! -f "${HOME}/app.js" ]; then
        curl -sL "https://raw.githubusercontent.com/$MY_GITHUB_USER/$MY_GITHUB_REPO/main/app.js" -o "${HOME}/app.js"
    fi

    sleep 300 # 每5分钟检查一次
done
