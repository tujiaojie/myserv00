#!/bin/bash
USER=$(whoami)
ALIST_PATH="${HOME}/alist/alist"
chmod +x ${HOME}/bin/* > /dev/null 2>&1
chmod +x $ALIST_PATH > /dev/null 2>&1
while true; do
if ! pgrep -u $USER -x "web" > /dev/null && ! pgrep -u $USER -x "bot" > /dev/null; then
/usr/local/bin/bash -c "source ~/.bashrc && sb" > /dev/null 2>&1
fi
if ! pgrep -u $USER -f "$ALIST_PATH server" > /dev/null; then
cd ${HOME}/alist && nohup ./alist server > /dev/null 2>&1 &
fi
sleep 300
done
