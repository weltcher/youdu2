@echo off
chcp 65001 >nul
setlocal

echo ========================================
echo        启动 Redis 服务
echo ========================================
echo.

set REDIS_PATH=C:\tools\redis

:: 检查Redis目录是否存在
if not exist "%REDIS_PATH%" (
    echo 错误: Redis目录不存在: %REDIS_PATH%
    echo 请确认Redis安装路径是否正确
    pause
    exit /b 1
)

:: 检查redis-server.exe是否存在
if not exist "%REDIS_PATH%\redis-server.exe" (
    echo 错误: redis-server.exe 不存在
    echo 路径: %REDIS_PATH%\redis-server.exe
    pause
    exit /b 1
)

:: 检查配置文件是否存在
if exist "%REDIS_PATH%\redis.conf" (
    echo Redis路径: %REDIS_PATH%
    echo 配置文件: redis.conf
    set USE_CONFIG=1
) else (
    echo Redis路径: %REDIS_PATH%
    echo 警告: 配置文件不存在，使用默认配置
    set USE_CONFIG=0
)

echo.

:: 切换到Redis目录
cd /d "%REDIS_PATH%"

:: 启动Redis服务
echo 正在启动Redis服务...
echo.

if "%USE_CONFIG%"=="1" (
    redis-server.exe redis.conf
) else (
    redis-server.exe
)

:: 如果Redis异常退出
echo.
echo Redis服务已停止
pause
