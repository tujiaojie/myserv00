#!/bin/bash

# ==========================================
# 你的专属一键脚本：Serv00 专用版
# ==========================================

# 1. 调取甬哥专门为 Serv00 开发的脚本 (这个不需要 root)
echo "正在调取 Serv00 专用版脚本，请完成安装步骤..."
bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh)

# 2. 自动下载保活脚本
echo "正在配置自动保活系统..."
curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00keep.sh -o ~/serv00keep.sh
chmod +x ~/serv00keep.sh

# 3. 自动设置定时任务 (5分钟一次)
(crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * /home/$(whoami)/serv00keep.sh > /dev/null 2>&1") | crontab -

echo "------------------------------------------------"
echo "恭喜！一键配置已全部完成。"
echo "请注意：Serv00 环境下可能没有 sb 快捷键，"
echo "如需再次进入菜单，再次运行本一键脚本即可。"
echo "------------------------------------------------"
