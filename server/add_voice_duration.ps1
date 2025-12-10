# 添加 voice_duration 字段的迁移脚本

# 从 .env 文件读取数据库配置
$envFile = ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
}

$DB_HOST = $env:DB_HOST
$DB_PORT = $env:DB_PORT
$DB_USER = $env:DB_USER
$DB_PASSWORD = $env:DB_PASSWORD
$DB_NAME = $env:DB_NAME

Write-Host "正在连接数据库: $DB_HOST:$DB_PORT/$DB_NAME" -ForegroundColor Cyan

# 设置 PGPASSWORD 环境变量
$env:PGPASSWORD = $DB_PASSWORD

# 执行迁移脚本
Write-Host "正在添加 voice_duration 字段..." -ForegroundColor Yellow
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "scripts/add_voice_duration.sql"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ voice_duration 字段添加成功！" -ForegroundColor Green
} else {
    Write-Host "❌ 迁移失败，错误代码: $LASTEXITCODE" -ForegroundColor Red
}

# 清除密码环境变量
Remove-Item Env:\PGPASSWORD
