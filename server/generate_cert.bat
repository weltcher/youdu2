@echo off
REM 生成自签名SSL证书（用于开发测试）
REM 生产环境请使用正式的CA签发证书

echo 正在生成自签名SSL证书...

REM 创建证书目录
if not exist "certs" mkdir certs

REM 使用OpenSSL生成证书
REM 如果没有安装OpenSSL，请先安装：https://slproweb.com/products/Win32OpenSSL.html

openssl req -x509 -newkey rsa:4096 -keyout certs\server.key -out certs\server.crt -days 365 -nodes -subj "/C=CN/ST=Beijing/L=Beijing/O=YourCompany/OU=IT/CN=localhost"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ 证书生成成功！
    echo 📜 证书文件: certs\server.crt
    echo 🔑 密钥文件: certs\server.key
    echo.
    echo ⚠️  注意：这是自签名证书，仅用于开发测试
    echo    生产环境请使用正式的CA签发证书（如Let's Encrypt）
) else (
    echo.
    echo ❌ 证书生成失败！
    echo 请确保已安装OpenSSL
    echo 下载地址：https://slproweb.com/products/Win32OpenSSL.html
)

pause
