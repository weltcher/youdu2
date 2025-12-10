@echo off
REM 加密 .env 文件
echo 加密 .env 文件...
echo 请输入加密密码：
set /p PASSWORD=

go run encrypt_env.go -encrypt -password="%PASSWORD%"
pause









