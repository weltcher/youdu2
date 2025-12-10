# 应用引用消息外键约束修复
# 此脚本移除 quoted_message_id 的外键约束，解决引用消息插入失败的问题

Write-Host "开始应用引用消息外键约束修复..." -ForegroundColor Green

# 从 .env 文件读取数据库配置
$envFile = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "错误: 找不到 .env 文件" -ForegroundColor Red
    exit 1
}

$dbHost = ""
$dbPort = ""
$dbUser = ""
$dbPassword = ""
$dbName = ""

Get-Content $envFile | ForEach-Object {
    if ($_ -match "^DB_HOST=(.+)$") { $dbHost = $matches[1] }
    if ($_ -match "^DB_PORT=(.+)$") { $dbPort = $matches[1] }
    if ($_ -match "^DB_USER=(.+)$") { $dbUser = $matches[1] }
    if ($_ -match "^DB_PASSWORD=(.+)$") { $dbPassword = $matches[1] }
    if ($_ -match "^DB_NAME=(.+)$") { $dbName = $matches[1] }
}

Write-Host "数据库配置:" -ForegroundColor Cyan
Write-Host "  主机: $dbHost" -ForegroundColor Cyan
Write-Host "  端口: $dbPort" -ForegroundColor Cyan
Write-Host "  用户: $dbUser" -ForegroundColor Cyan
Write-Host "  数据库: $dbName" -ForegroundColor Cyan

# 设置 PGPASSWORD 环境变量
$env:PGPASSWORD = $dbPassword

# 执行迁移脚本
$migrationFile = Join-Path $PSScriptRoot "db\migrations\remove_quoted_message_fkey.sql"

Write-Host "`n执行迁移脚本: $migrationFile" -ForegroundColor Yellow

try {
    $result = & psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -f $migrationFile 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ 迁移成功完成！" -ForegroundColor Green
        Write-Host $result
    } else {
        Write-Host "`n❌ 迁移失败！" -ForegroundColor Red
        Write-Host $result
        exit 1
    }
} catch {
    Write-Host "`n❌ 执行迁移时出错: $_" -ForegroundColor Red
    exit 1
} finally {
    # 清除密码环境变量
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

Write-Host "`n现在可以重新测试引用消息功能了。" -ForegroundColor Green
