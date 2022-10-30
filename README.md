# offsite-backup-script
一個透過 Rsync 為 Linux 主機異地備份的腳本，不需要設置繁雜的 Rsync config。
## 什麼是 Rsync
Rsync 是一款為 Unix 系統設計的資料同步軟體，Rsync 的使用方式與功能有很多，小弟我也才剛接觸，所以對整體的操作不是非常熟悉，所以本次就以目前所學的並以簡單簡易的構想來撰寫腳本，腳本是採用 Rsync 的 SSH 通道對本地與異地進行資料傳輸。
所以可能有些不盡人意之處，還請各位大佬指教。
## 腳本原理
1. 先取得當前的時間作為檔案的名稱，方便之後得知
2. 利用 tar zcvf 壓縮檔案
3. 透過 rsync 將剛剛壓縮的檔案傳送至其他主機內
## 腳本內容
```sh
#!/bin/sh  

# source 讓bash腳本執行環境下讀取並執行指定資料夾的指令
source /etc/profile
source ~/.bash_profile

# 取得目前的時間(格式 年月日_時分)  
time="$(date +'%Y%m%d_%H%M')"  
  
# 壓縮檔案，儲存格式為 .tar.gz
tar zcvf $time.tar.gz /本地端要備份的資料夾路徑/  
  
# 透過 rsync 將檔案傳送至備份端，並且傳輸完成後將本地端的壓縮檔案刪除  
# 本次傳輸將透過SSH公私鑰進行驗證  
rsync -avh --remove-source-files $time.tar.gz 備份端使用者名稱@備份端IP:/備份到的資料夾路徑/
```
## 使用方式
1. 下載腳本(https://github.com/FanYueee/offsite-backup-script/blob/main/backup.sh) 並上傳至本地端內
2. 編輯腳本中的內容
	1. `/本地端要備份的資料夾名稱/`: 要備份的資料夾
	2. `備份端使用者名稱`: 備份端 SSH 使用者名稱
	3. `備份端IP`: 備份端的 IP 位置
	4. `/備份到的資料夾路徑/`: 備份資料傳送至備份端的存放位置
3. 生成本地主機的公私鑰，供 Rsync 免登入直接驗證使用
   於本地端 SSH 輸入指令 `ssh-keygen`
```
Enter file in which to save the key (/home/ubuntu/.ssh/id_rsa): # 直接按 Enter
Enter passphrase (empty for no passphrase): # 直接按 Enter
Enter same passphrase again: # 直接按 Enter
```
4. 將公鑰放置到異地備份主機內，在本地端輸入以下指令
   `ssh-copy-id -i ~/.ssh/id_rsa.pub 備份端使用者名稱@備份端IP`
   輸入後將會需要輸入備份端的SSH密碼
5. 於本地端設定 crontab 定期執行腳本 `crontab -e -u root`
```
 * * * * * /腳本位置/
```
  crontab 的設置時間設置
```
* * * * * 
分時日月周
```
可以利用 https://crontab.guru/ 來測試與預覽是否有誤
```
# 範例: 每日12,0點整執行腳本
0 12,0 * * *
```
## 常見問題
執行 SH 腳本時出現以下類似字串:
> run.sh: line 5: $'\r': command not found
> tar: Removing leading `/' from member names

 如果出現此狀況在本地端 SSH 輸入以下指令
`sed -i 's/\r//' backup.sh`
	引起原因是因為 Windows 系統編輯時每行的結尾是 \r\n，然而 Linux 是 \n，並且執行時會認為 \r 是一個字符因而引起錯誤。
## 未來功能
- [ ] 傳輸完成後透過 Discord 發送通知給使用者