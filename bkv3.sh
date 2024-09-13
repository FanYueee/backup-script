#!/bin/bash

source /etc/profile
source ~/.bash_profile

name="SG-M1"
webhook="https://discord.com/api/webhooks/"
time="$(date +'%Y%m%d_%H%M')"
log_file="/bk/log.txt"
# 刪除天數
max_days=7
# 壓縮的位置
compression=/var/lib/pterodactyl/volumes
# 壓縮至的位置
compressed_to=/mnt/nvme2/temp-bk


send_discord_message() {
    curl -H "Content-Type: application/json" -d "{\"username\": \"$name\", \"content\": \"$1\"}" "$webhook"
}

log_file_id() {
    echo "$(date +'%Y-%m-%d') $1" >> "$log_file"
}

check_and_delete_old_files() {
    current_date=$(date +%s)
    while IFS= read -r line; do
        file_date=$(echo "$line" | cut -d' ' -f1)
        file_id=$(echo "$line" | cut -d' ' -f2)
        file_timestamp=$(date -d "$file_date" +%s)
        days_diff=$(( (current_date - file_timestamp) / 86400 ))
        
        if [ "$days_diff" -gt "$max_days" ]; then
            if /home/ubuntu/gdrive files delete "$file_id"; then
                current_time="$(date +'%Y%m%d_%H%M')"
                send_discord_message "${current_time} 已刪除超過 ${max_days} 天的文件 (ID: ${file_id})"
                sed -i "/$file_id/d" "$log_file"
            else
                current_time="$(date +'%Y%m%d_%H%M')"
                send_discord_message "${current_time} 刪除文件失敗 (ID: ${file_id})"
            fi
        fi
    done < "$log_file"
}

current_time="$(date +'%Y%m%d_%H%M')"
send_discord_message "${current_time} 即將進行壓縮"

if ! tar -zcvf "${compressed_to}/${time}.tar.gz" -C "$compression" .; then
    current_time="$(date +'%Y%m%d_%H%M')"
    send_discord_message "${current_time} 壓縮失敗，腳本終止"
    rm "${compressed_to}/${time}.tar.gz"
    exit 1
fi

backup_size=$(stat -c "%s" "${compressed_to}/$time.tar.gz")
backup_size_gb=$(echo "scale=2; $backup_size / 1024^3" | bc)

current_time="$(date +'%Y%m%d_%H%M')"
send_discord_message "${current_time} 壓縮完畢，即將進行上傳（檔案大小 ${backup_size_gb}GB）"

start=$(date +%s.%N)

file_id=$(/home/ubuntu/gdrive files upload "${compressed_to}/${time}.tar.gz" | grep "^Id:" | awk '{print $2}')

end=$(date +%s.%N)
backup_time=$(echo "$end - $start" | bc)

if [ -n "$file_id" ]; then
    current_time="$(date +'%Y%m%d_%H%M')"
    send_discord_message "${current_time} 上傳成功，本地檔案已刪除（上傳用時：${backup_time}秒）。(ID: ${file_id})"
    log_file_id "$file_id"
    rm "${compressed_to}/${time}.tar.gz"
else
    current_time="$(date +'%Y%m%d_%H%M')"
    send_discord_message "${current_time} 上傳失敗（上傳用時：${backup_time}秒）。"
    if [ -e "${compressed_to}/${time}.tar.gz" ]; then
        rm "${compressed_to}/${time}.tar.gz"
        current_time="$(date +'%Y%m%d_%H%M')"
        send_discord_message "${current_time} 上傳失敗，本地檔案已刪除。"
    fi
fi

check_and_delete_old_files
