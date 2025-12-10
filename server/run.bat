@echo off
echo ========================================
echo YouDu Server Launcher
echo ========================================
echo.

REM 检查.env文件是否存在
if not exist .env (
    echo [警告] .env 文件不存在，正在从 .env.example 复制...
    copy .env.example .env
    echo [提示] 请编辑 .env 文件配置数据库连接信息
    pause
)

REM 下载依赖
echo [1/3] 正在下载Go依赖...
go mod download
if errorlevel 1 (
    echo [错误] 依赖下载失败
    pause
    exit /b 1
)

REM 整理依赖
echo [2/3] 正在整理依赖...
go mod tidy

REM 运行服务器
echo [3/3] 正在启动服务器...
echo.
go run main.go

pause

