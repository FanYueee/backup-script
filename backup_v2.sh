source /etc/profile
source ~/.bash_profile

# 節點名稱
name="SG-M1"

# Discord Webhook
webhook="https://discord.com/api/webhooks/"

time="$(date +'%Y%m%d_%H%M')"
current_time="$(date +'%Y%m%d_%H%M')"

curl -H "Content-Type: application/json" -d '{"username": "'"$name"'", "content": "'"${current_time}"' 即將進行壓縮"}' "$webhook"

# 這裡要改
# tar -zcvf 壓縮到的位置 -C 壓縮的檔案位置 .
tar -zcvf $time.tar.gz -C /var/lib/pterodactyl/volumes .

backup_size=$(stat -c "%s" "$time.tar.gz")
backup_size_gb=$(echo "scale=2; $backup_size / 1024^3" | bc)

current_time="$(date +'%Y%m%d_%H%M')"
curl -H "Content-Type: application/json" -d '{"username": "'"$name"'", "content": "'"${current_time}"' 壓縮完畢，即將進行上傳（檔案大小 '"${backup_size_gb}"'GB）"}' "$webhook"

start=$(date +%s.%N)

# 這裡要改
# rsync -avh --remove-source-files $time.tar.gz root@IP位置:上船的資料夾
rsync -avh --remove-source-files $time.tar.gz root@0.0.0.0:/mnt/hdd/

end=$(date +%s.%N)

backup_time=$(echo "$end - $start" | bc)

if [ -e "$time.tar.gz" ]; then
        current_time="$(date +'%Y%m%d_%H%M')"
        curl -H "Content-Type: application/json" -d '{"username": "'"$name"'", "content": "'"${current_time}"' 上傳失敗，本地檔案尚存在（上傳用時：'"${backup_time}"'秒）。"}' "$webhook"
        if [ -e "$time.tar.gz" ]; then
                rm "$time.tar.gz"
                current_time="$(date +'%Y%m%d_%H%M')"
                curl -H "Content-Type: application/json" -d '{"username": "'"$name"'", "content": "'"${current_time}"' 上傳失敗，檔案已經刪除。"}' "$webhook"
        fi
else
        current_time="$(date +'%Y%m%d_%H%M')"
        curl -H "Content-Type: application/json" -d '{"username": "'"$name"'", "content": "'"${current_time}"' 上傳成功，本地檔案已刪除（上傳用時：'"${backup_time}"'秒）。"}' "$webhook"
fi
