@echo off
echo ========================================
echo YouDu Server 构建脚本
echo ========================================
echo.

REM 清理旧的构建文件
if exist youdu-server.exe (
    echo [清理] 删除旧的构建文件...
    del youdu-server.exe
)

REM 下载依赖
echo [1/3] 正在下载依赖...
go mod download
if errorlevel 1 (
    echo [错误] 依赖下载失败
    pause
    exit /b 1
)

REM 整理依赖
echo [2/3] 正在整理依赖...
go mod tidy

REM 构建
echo [3/3] 正在构建可执行文件...
go build -o youdu-server.exe main.go
if errorlevel 1 (
    echo [错误] 构建失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo 构建成功！
echo ========================================
echo.
echo 可执行文件: youdu-server.exe
echo.
echo 运行方式:
echo   1. 确保已配置 .env 文件
echo   2. 确保 PostgreSQL 服务已启动
echo   3. 执行: youdu-server.exe
echo ========================================
pause

