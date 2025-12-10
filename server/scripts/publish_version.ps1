# 版本发布脚本 (PowerShell)
# 用于录入版本信息并将升级包推送到OSS
# 使用方法: .\publish_version.ps1 -Platform windows -Version 1.0.0 -FilePath .\app.exe -Notes "更新说明"
# 【Windows】 - 上传文件到OSS
# go run publish_version.go -platform windows -version 1.0.0 -file ./app.exe -notes "修复bug" -publish
# 【Android】 - 上传APK到OSS
# go run publish_version.go -platform android -version 1.0.0 -file ./app.apk -notes "新功能" -publish
# 【iOS】 - 使用TestFlight分发地址
# go run publish_version.go -platform ios -version 1.0.0 -url "https://testflight.apple.com/join/xxx" -notes "新版本" -publish

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("windows", "android", "ios")]
    [string]$Platform,
    
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [string]$Notes = "",
    
    [switch]$ForceUpdate,
    
    [string]$MinVersion = "",
    
    [string]$ServerURL = "http://localhost:8080",
    
    [switch]$Publish,
    
    [string]$EnvFile = "../.env"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "       版本发布工具 (PowerShell)"
Write-Host "========================================"

# 检查文件是否存在
if (-not (Test-Path $FilePath)) {
    Write-Host "错误: 文件不存在: $FilePath" -ForegroundColor Red
    exit 1
}

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

$OSSEndpoint = if ($env:S3_ENDPOINT) { $env:S3_ENDPOINT } else { $envConfig["S3_ENDPOINT"] }
$OSSAccessKey = if ($env:S3_ACCESS_KEY) { $env:S3_ACCESS_KEY } else { $envConfig["S3_ACCESS_KEY"] }
$OSSSecretKey = if ($env:S3_SECRET_KEY) { $env:S3_SECRET_KEY } else { $envConfig["S3_SECRET_KEY"] }
$OSSBucket = if ($env:S3_BUCKET) { $env:S3_BUCKET } else { $envConfig["S3_BUCKET"] }

if (-not $OSSEndpoint -or -not $OSSAccessKey -or -not $OSSSecretKey -or -not $OSSBucket) {
    Write-Host "错误: OSS配置不完整，请检查环境变量或.env文件" -ForegroundColor Red
    exit 1
}

Write-Host "平台: $Platform"
Write-Host "版本: $Version"
Write-Host "文件: $FilePath"
Write-Host "========================================"

# 获取文件信息
$fileInfo = Get-Item $FilePath
$fileSize = $fileInfo.Length
$fileHash = (Get-FileHash -Path $FilePath -Algorithm MD5).Hash.ToLower()

Write-Host "`n[1/5] 检查上一个版本..."

# 检查上一个版本
try {
    $response = Invoke-RestMethod -Uri "$ServerURL/api/version/latest?platform=$Platform" -Method Get -ErrorAction SilentlyContinue
    if ($response.data -and $response.data.oss_object_key) {
        Write-Host "找到上一个版本: $($response.data.version), OSS Key: $($response.data.oss_object_key)"
        Write-Host "注意: 上一个版本的OSS文件将在新版本上传后由服务端管理"
    }
} catch {
    Write-Host "没有找到上一个版本，跳过"
}

Write-Host "`n[2/5] 准备上传文件到OSS..."

# 生成OSS Key
$ext = [System.IO.Path]::GetExtension($FilePath)
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$ossKey = "releases/$Platform/${Version}_$timestamp$ext"

# 生成文件URL
$endpointHost = $OSSEndpoint -replace "^https?://", ""
$fileURL = "https://$OSSBucket.$endpointHost/$ossKey"

Write-Host "OSS Key: $ossKey"
Write-Host "文件大小: $fileSize bytes"
Write-Host "文件MD5: $fileHash"

# 注意: PowerShell直接上传到阿里云OSS需要签名，这里我们通过API来处理
# 实际上传逻辑建议使用Go脚本或阿里云CLI

Write-Host "`n[3/5] 创建版本记录..."

$body = @{
    platform = $Platform
    version = $Version
    package_url = $fileURL
    oss_object_key = $ossKey
    release_notes = $Notes
    is_force_update = $ForceUpdate.IsPresent
    file_size = $fileSize
    file_hash = $fileHash
}

if ($MinVersion) {
    $body["min_supported_version"] = $MinVersion
}

try {
    $response = Invoke-RestMethod -Uri "$ServerURL/api/app-versions" -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"
    
    if ($response.code -eq 0) {
        $versionID = $response.data.id
        Write-Host "版本记录创建成功! ID: $versionID" -ForegroundColor Green
    } else {
        Write-Host "错误: $($response.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "错误: 创建版本记录失败: $_" -ForegroundColor Red
    exit 1
}

# 发布版本
if ($Publish) {
    Write-Host "`n[4/5] 发布版本..."
    try {
        $response = Invoke-RestMethod -Uri "$ServerURL/api/app-versions/$versionID/publish" -Method Post
        if ($response.code -eq 0) {
            Write-Host "版本发布成功!" -ForegroundColor Green
        } else {
            Write-Host "警告: 发布失败: $($response.message)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "警告: 发布版本失败: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[4/5] 跳过发布（使用 -Publish 参数可自动发布）"
}

Write-Host "`n[5/5] 完成!"
Write-Host "========================================"
Write-Host "版本发布完成!" -ForegroundColor Green
Write-Host "  版本ID: $versionID"
Write-Host "  下载地址: $fileURL"
if (-not $Publish) {
    Write-Host "`n提示: 版本当前为草稿状态，请在管理后台发布或使用 -Publish 参数" -ForegroundColor Yellow
}
Write-Host "========================================"

Write-Host "`n注意: 文件上传需要使用Go脚本或阿里云CLI完成"
Write-Host "推荐使用: go run publish_version.go -platform $Platform -version $Version -file $FilePath"
