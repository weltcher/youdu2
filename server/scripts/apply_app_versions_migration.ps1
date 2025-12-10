# 应用app_versions表迁移脚本
# 使用方法: .\apply_app_versions_migration.ps1

param(
    [string]$EnvFile = "../.env"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "  应用 app_versions 表迁移"
Write-Host "========================================"

# 加载.env配置
function Load-EnvFile {
    param([string]$Path)
    
    $config = @{}
    
    if (Test-Path $Path) {
        Get-Content $Path | ForEach-Object {
            if ($_ -match "^\s*([^#][^=]+)=(.*)$") {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $config[$key] = $value
            }
        }
    }
    
    return $config
}

$envConfig = Load-EnvFile -Path $EnvFile

$DBHost = if ($env:DB_HOST) { $env:DB_HOST } else { $envConfig["DB_HOST"] }
$DBPort = if ($env:DB_PORT) { $env:DB_PORT } else { $envConfig["DB_PORT"] }
$DBUser = if ($env:DB_USER) { $env:DB_USER } else { $envConfig["DB_USER"] }
$DBPassword = if ($env:PASSWORD2) { $env:PASSWORD2 } else { $envConfig["PASSWORD2"] }
$DBName = if ($env:DB_NAME) { $env:DB_NAME } else { $envConfig["DB_NAME"] }

if (-not $DBHost) { $DBHost = "localhost" }
if (-not $DBPort) { $DBPort = "5432" }
if (-not $DBUser) { $DBUser = "postgres" }
if (-not $DBName) { $DBName = "youdu_db" }

Write-Host "数据库配置:"
Write-Host "  Host: $DBHost"
Write-Host "  Port: $DBPort"
Write-Host "  User: $DBUser"
Write-Host "  Database: $DBName"
Write-Host ""

# 设置环境变量
$env:PGPASSWORD = $DBPassword

# 执行迁移SQL
$migrationFile = "../db/migrations/create_app_versions_table.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "错误: 迁移文件不存在: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "执行迁移文件: $migrationFile"

try {
    psql -h $DBHost -p $DBPort -U $DBUser -d $DBName -f $migrationFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "迁移成功!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "迁移失败!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "错误: $_" -ForegroundColor Red
    exit 1
}

Write-Host "========================================"
