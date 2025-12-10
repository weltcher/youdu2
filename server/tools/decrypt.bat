@echo off
REM 解密 .env.encrypted 文件
echo 解密 .env.encrypted 文件...
echo 请输入解密密码：
set /p PASSWORD=

go run encrypt_env.go -decrypt -password="%PASSWORD%"
pause









