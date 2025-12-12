@echo off
chcp 65001 >nul

echo ========================================
echo        启动 Redis 服务 (简化版)
echo ========================================
echo.

set REDIS_PATH=C:\tools\redis

:: 检查Redis目录
if not exist "%REDIS_PATH%\redis-server.exe" (
    echo 错误: redis-server.exe 不存在
    echo 路径: %REDIS_PATH%\redis-server.exe
    pause
    exit /b 1
)

echo Redis路径: %REDIS_PATH%
echo 使用默认配置启动
echo.

:: 切换到Redis目录并启动（不带配置文件）
cd /d "%REDIS_PATH%"
echo 正在启动Redis服务...
echo.

redis-server.exe

echo.
echo Redis服务已停止
pause
