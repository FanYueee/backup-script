#!/bin/sh

# source 讓bash腳本執行環境下讀取並執行指定資料夾的指令
source /etc/profile
source ~/.bash_profile

# 取得目前的時間(格式 年月日_時分)
time="$(date +'%Y%m%d_%H%M')"

# 壓縮檔案，儲存格式為 .tar.gz
tar zcvf $time.tar.gz /要備份的資料夾名稱/

# 透過 rsync 將檔案傳送至備份主機，並且傳輸完成後將本地主機的檔案刪除
# 本次傳輸將透過SSH公私鑰進行驗證，所以務必要有SSH的root權限
rsync -avh --remove-source-files $time.tar.gz 備份主機使用者名稱@備份主機IP:/備份到的資料夾路徑/

