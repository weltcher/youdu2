@echo off
chcp 65001 >nul
setlocal

echo ========================================
echo      检查 Redis 服务状态
echo ========================================
echo.

set REDIS_PATH=C:\tools\redis

:: 检查Redis进程是否在运行
tasklist /FI "IMAGENAME eq redis-server.exe" 2>NUL | find /I /N "redis-server.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [√] Redis服务正在运行
    echo.
    
    :: 显示进程信息
    echo 进程信息:
    tasklist /FI "IMAGENAME eq redis-server.exe" /FO TABLE
    echo.
    
    :: 尝试连接测试
    if exist "%REDIS_PATH%\redis-cli.exe" (
        echo 测试连接...
        "%REDIS_PATH%\redis-cli.exe" ping 2>NUL
        if "%ERRORLEVEL%"=="0" (
            echo [√] Redis连接正常
        ) else (
            echo [×] Redis连接失败
        )
    )
) else (
    echo [×] Redis服务未运行
)

echo.
pause
