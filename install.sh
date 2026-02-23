#!/bin/bash

# 定义你的个人信息
MY_USER="tujiaojie"
MY_REPO="myserv00"
BASE_URL="https://raw.githubusercontent.com/$MY_USER/$MY_REPO/main"

# 设置颜色
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }

# 1. 准备工作：下载保活脚本和app.js到本地
echo "正在从 $MY_REPO 获取资源..."
curl -sL "$BASE_URL/keep.sh" -o "$HOME/serv00keep.sh"
curl -sL "$BASE_URL/app.js" -o "$HOME/app.js"
chmod +x "$HOME/serv00keep.sh"

# 2. 下载并修改原版主脚本 (动态将 yonggekkk 替换为 tujiaojie)
# 这样即使勇哥更新了，你只要重新运行此整合脚本，依然能保持链接指向你自己
curl -sL "https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh" -o "setup.sh"

# 核心整合：把脚本里所有的 yonggekkk 替换成你的用户名，把原脚本名替换成你的
sed -i "s/yonggekkk\/sing-box-yg/$MY_USER\/$MY_REPO/g" setup.sh
sed -i "s/serv00.sh/install.sh/g" setup.sh
sed -i "s/serv00keep.sh/keep.sh/g" setup.sh

# 3. 运行安装
bash setup.sh

# 4. 安装后清理
rm setup.sh
green "安装完成！代理已部署，保活脚本已指向 $MY_USER/$MY_REPO"
