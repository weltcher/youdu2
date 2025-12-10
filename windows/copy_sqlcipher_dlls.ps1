# 自动复制 SQLCipher 和 OpenSSL DLL 到输出目录
# 在 Flutter Windows 编译后运行

param(
    [string]$BuildMode = "Debug"  # Debug 或 Release
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "自动复制 SQLCipher 相关 DLL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 项目根目录
$ProjectRoot = Split-Path $PSScriptRoot -Parent

# 目标目录
$TargetDir = Join-Path $ProjectRoot "build\windows\x64\runner\$BuildMode"

# SQLCipher DLL 源路径（从 sqlcipher_flutter_libs 包编译生成）
$SqlCipherSource = Join-Path $ProjectRoot "build\windows\x64\plugins\sqlcipher_flutter_libs\$BuildMode\sqlite3.dll"

# OpenSSL DLL 路径
$OpenSSLBinDir = "C:\tools\openssl\openssl-3.0.17\dist\bin"

Write-Host "`n1. 检查目标目录..." -ForegroundColor Yellow
if (!(Test-Path $TargetDir)) {
    Write-Host "   ❌ 目标目录不存在: $TargetDir" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ 目标目录存在: $TargetDir" -ForegroundColor Green

Write-Host "`n2. 复制 SQLCipher DLL..." -ForegroundColor Yellow
if (Test-Path $SqlCipherSource) {
    $TargetSqlCipher = Join-Path $TargetDir "sqlcipher.dll"
    Copy-Item $SqlCipherSource -Destination $TargetSqlCipher -Force
    Write-Host "   ✅ 已复制: sqlite3.dll → sqlcipher.dll" -ForegroundColor Green
    Write-Host "      源: $SqlCipherSource" -ForegroundColor Gray
    Write-Host "      目标: $TargetSqlCipher" -ForegroundColor Gray
} else {
    Write-Host "   ❌ SQLCipher DLL 不存在: $SqlCipherSource" -ForegroundColor Red
    Write-Host "   💡 请先运行 flutter build windows" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n3. 复制 OpenSSL DLL..." -ForegroundColor Yellow
if (Test-Path $OpenSSLBinDir) {
    $OpenSSLDlls = @("libcrypto-3-x64.dll", "libssl-3-x64.dll")
    foreach ($dll in $OpenSSLDlls) {
        $source = Join-Path $OpenSSLBinDir $dll
        if (Test-Path $source) {
            $target = Join-Path $TargetDir $dll
            Copy-Item $source -Destination $target -Force
            Write-Host "   ✅ 已复制: $dll" -ForegroundColor Green
        } else {
            Write-Host "   ❌ 未找到: $dll" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ❌ OpenSSL 目录不存在: $OpenSSLBinDir" -ForegroundColor Red
    Write-Host "   💡 请确保 OpenSSL 3.x 已安装到: C:\tools\openssl\openssl-3.0.17\dist" -ForegroundColor Yellow
}

Write-Host "`n4. 验证 DLL 复制完成..." -ForegroundColor Yellow
$RequiredDlls = @("sqlcipher.dll", "libcrypto-3-x64.dll", "libssl-3-x64.dll")
$AllPresent = $true
foreach ($dll in $RequiredDlls) {
    $path = Join-Path $TargetDir $dll
    if (Test-Path $path) {
        $size = (Get-Item $path).Length / 1KB
        Write-Host "   ✅ $dll ($([math]::Round($size, 2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $dll (缺失)" -ForegroundColor Red
        $AllPresent = $false
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
if ($AllPresent) {
    Write-Host "✅ 所有 DLL 复制完成！" -ForegroundColor Green
    Write-Host "🔐 SQLCipher 加密功能已就绪！" -ForegroundColor Green
} else {
    Write-Host "❌ 部分 DLL 缺失，加密功能可能无法正常工作" -ForegroundColor Red
    exit 1
}
Write-Host "========================================" -ForegroundColor Cyan
