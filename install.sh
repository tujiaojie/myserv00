#!/bin/bash

# --- 修改这里 ---
MY_GITHUB_USER="你的用户名"
MY_GITHUB_REPO="你的仓库名"
# ----------------

# 基础变量设置
WORKDIR="${HOME}/domains/$(whoami).serv00.net/logs"
[ -d "$WORKDIR" ] || mkdir -p "$WORKDIR"

# 下载你自己的保活脚本和app.js
curl -sL "https://raw.githubusercontent.com/$MY_GITHUB_USER/$MY_GITHUB_REPO/main/keep.sh" -o "${HOME}/keep.sh"
chmod +x "${HOME}/keep.sh"

# 核心逻辑：这里引用原脚本的安装逻辑，但将资源下载改为你的仓库
# 注意：原脚本中涉及 wget/curl yonggekkk 的地方都要改为你的链接

# ... (此处保留原 serv00.sh 的交互逻辑：选IP、选端口、选域名) ...

# 关键修改点示例：
# 原代码中下载 sing-box 或 argo 的二进制文件，它们是存在勇哥的 release 里的。
# 建议你保留这些二进制下载链接，因为这些是编译好的工具，或者你也可以 fork 他的 release。

# 安装完成后自动启动保活
if [ -f "${HOME}/keep.sh" ]; then
    nohup bash "${HOME}/keep.sh" > /dev/null 2>&1 &
fi

echo "安装完成，保活脚本已从 https://github.com/$MY_GITHUB_USER/$MY_GITHUB_REPO 部署。"
