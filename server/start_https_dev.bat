@echo off
echo ========================================
echo 启动 HTTPS 开发服务器
echo ========================================
echo.

REM 检查证书是否存在
if not exist "certs\server.crt" (
    echo 📜 证书不存在，正在生成...
    call generate_cert.bat
    echo.
)

REM 检查 .env 配置
echo 📋 检查配置...
findstr /C:"ENABLE_HTTPS=true" .env >nul
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️  警告：HTTPS 未启用
    echo 请在 .env 中设置 ENABLE_HTTPS=true
    pause
    exit /b 1
)

echo ✅ 配置检查完成
echo.

REM 启动服务器
echo 🚀 启动服务器...
echo.
go run main.go
