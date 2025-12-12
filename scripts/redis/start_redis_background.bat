@echo off
chcp 65001 >nul
setlocal

echo ========================================
echo     后台启动 Redis 服务
echo ========================================
echo.

set REDIS_PATH=C:\tools\redis

:: 检查Redis目录是否存在
if not exist "%REDIS_PATH%" (
    echo 错误: Redis目录不存在: %REDIS_PATH%
    pause
    exit /b 1
)

:: 检查redis-server.exe是否存在
if not exist "%REDIS_PATH%\redis-server.exe" (
    echo 错误: redis-server.exe 不存在
    pause
    exit /b 1
)

:: 检查Redis是否已经在运行
tasklist /FI "IMAGENAME eq redis-server.exe" 2>NUL | find /I /N "redis-server.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo Redis服务已在运行中
    echo.
    pause
    exit /b 0
)

:: 检查配置文件
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

:: 后台启动Redis服务
echo 正在后台启动Redis服务...

:: 切换到Redis目录并启动
cd /d "%REDIS_PATH%"

if "%USE_CONFIG%"=="1" (
    start "Redis Server" /MIN redis-server.exe redis.conf
) else (
    start "Redis Server" /MIN redis-server.exe
)

:: 等待一下确认启动
timeout /t 2 /nobreak >nul

:: 检查是否启动成功
tasklist /FI "IMAGENAME eq redis-server.exe" 2>NUL | find /I /N "redis-server.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo.
    echo Redis服务已成功启动（后台运行）
    echo.
    echo 提示:
    echo   - 使用 stop_redis.bat 停止服务
    echo   - 使用 redis-cli.exe 连接Redis
) else (
    echo.
    echo 错误: Redis服务启动失败
)

echo.
pause
