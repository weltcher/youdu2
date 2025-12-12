# Redis 启动脚本 (PowerShell)
# 使用方法: .\start_redis.ps1

param(
    [string]$RedisPath = "C:\tools\redis",
    [string]$ConfigFile = "redis.conf"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "       启动 Redis 服务"
Write-Host "========================================"
Write-Host ""

# 检查Redis目录是否存在
if (-not (Test-Path $RedisPath)) {
    Write-Host "错误: Redis目录不存在: $RedisPath" -ForegroundColor Red
    Write-Host "请确认Redis安装路径是否正确"
    Read-Host "按任意键退出"
    exit 1
}

# 检查redis-server.exe是否存在
$redisServerPath = Join-Path $RedisPath "redis-server.exe"
if (-not (Test-Path $redisServerPath)) {
    Write-Host "错误: redis-server.exe 不存在" -ForegroundColor Red
    Write-Host "路径: $redisServerPath"
    Read-Host "按任意键退出"
    exit 1
}

# 检查配置文件
$configPath = Join-Path $RedisPath $ConfigFile
$useConfig = $false

if (Test-Path $configPath) {
    $useConfig = $true
    Write-Host "Redis路径: $RedisPath"
    Write-Host "配置文件: $ConfigFile"
} else {
    Write-Host "警告: 配置文件不存在: $configPath" -ForegroundColor Yellow
    Write-Host "将使用默认配置启动Redis"
    Write-Host "Redis路径: $RedisPath"
}

Write-Host ""
Write-Host "正在启动Redis服务..." -ForegroundColor Green
Write-Host ""

# 切换到Redis目录（重要：使用相对路径）
Set-Location $RedisPath

# 启动Redis服务
try {
    if ($useConfig) {
        # 使用相对路径，避免路径混淆
        & .\redis-server.exe $ConfigFile
    } else {
        & .\redis-server.exe
    }
} catch {
    Write-Host ""
    Write-Host "错误: Redis启动失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Read-Host "按任意键退出"
    exit 1
}

Write-Host ""
Write-Host "Redis服务已停止" -ForegroundColor Yellow
Read-Host "按任意键退出"
