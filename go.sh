#!/bin/bash

# ==========================================
# 你的专属一键脚本：安装节点 + 自动设置 5 分钟保活
# ==========================================

# 1. 运行甬哥原版安装菜单
echo "正在从甬哥仓库调取原版脚本，请完成安装步骤..."
bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)

# 2. 自动下载保活脚本
echo "正在配置自动保活系统..."
curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00keep.sh -o ~/serv00keep.sh
chmod +x ~/serv00keep.sh

# 3. 自动设置定时任务 (5分钟一次)
# 这里会先清理旧任务，再添加新的，确保不重复
(crontab -l 2>/dev/null | grep -v "serv00keep.sh"; echo "*/5 * * * * /home/$(whoami)/serv00keep.sh > /dev/null 2>&1") | crontab -

echo "------------------------------------------------"
echo "恭喜！一键配置已全部完成。"
echo "1. 节点安装流程已结束。"
echo "2. 自动保活已设为每 5 分钟巡逻一次。"
echo "------------------------------------------------"    
