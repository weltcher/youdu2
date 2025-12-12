@echo off
chcp 65001 >nul
setlocal

echo ========================================
echo        停止 Redis 服务
echo ========================================
echo.

:: 检查Redis是否在运行
tasklist /FI "IMAGENAME eq redis-server.exe" 2>NUL | find /I /N "redis-server.exe">NUL
if "%ERRORLEVEL%"=="1" (
    echo Redis服务未运行
    echo.
    pause
    exit /b 0
)

echo 正在停止Redis服务...

:: 尝试优雅关闭（如果有redis-cli）
set REDIS_PATH=C:\tools\redis
if exist "%REDIS_PATH%\redis-cli.exe" (
    echo 尝试使用redis-cli优雅关闭...
    "%REDIS_PATH%\redis-cli.exe" shutdown 2>NUL
    timeout /t 2 /nobreak >nul
)

:: 检查是否已停止
tasklist /FI "IMAGENAME eq redis-server.exe" 2>NUL | find /I /N "redis-server.exe">NUL
if "%ERRORLEVEL%"=="1" (
    echo Redis服务已停止
    echo.
    pause
    exit /b 0
)

:: 如果还在运行，强制结束
echo 强制结束Redis进程...
taskkill /F /IM redis-server.exe >NUL 2>&1

:: 再次检查
timeout /t 1 /nobreak >nul
tasklist /FI "IMAGENAME eq redis-server.exe" 2>NUL | find /I /N "redis-server.exe">NUL
if "%ERRORLEVEL%"=="1" (
    echo Redis服务已停止
) else (
    echo 警告: 无法停止Redis服务
)

echo.
pause
