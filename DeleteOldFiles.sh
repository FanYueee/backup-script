#!/bin/bash

# =================================
# Created by FanYueee on 2023/03/26
# =================================

# 設定區域

# 要執行自動刪除過久檔案的資料夾
directory="/path/to/directory"
# 超過多久的檔案會刪除，單位: 日
days=14

# Main

timestamp=$(date +%s)
cutoff=$(($timestamp - ($days * 86400)))

find "$directory" -type f -mtime +"$days" -print -delete