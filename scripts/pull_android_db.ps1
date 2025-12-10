# ============================================================
# Android Database Export Script
# ============================================================
# Purpose: Export application database from Android device to project root
# 
# Prerequisites:
# 1. Android device connected with USB debugging enabled
# 2. Device has Root access
# 3. ADB tools installed
#
# Usage:
# .\scripts\pull_android_db.ps1
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Android Database Export Tool" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check if ADB is available
Write-Host "Step 1/4: Check ADB Environment" -ForegroundColor Yellow
Write-Host "--------------------------------------------"
try {
    $adbVersion = adb version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "ADB not installed or not in PATH"
    }
    Write-Host "   [OK] ADB is ready" -ForegroundColor Green
} catch {
    Write-Host "   [ERROR] $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Android SDK Platform-Tools and add to PATH" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 2. Check device connection
Write-Host "Step 2/4: Check Device Connection" -ForegroundColor Yellow
Write-Host "--------------------------------------------"
$devices = adb devices | Select-String -Pattern "device$"
if ($devices.Count -eq 0) {
    Write-Host "   [ERROR] No Android device detected" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "   1. Device is connected via USB" -ForegroundColor Yellow
    Write-Host "   2. USB debugging is enabled" -ForegroundColor Yellow
    Write-Host "   3. USB debugging authorization is granted" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can check device with command:" -ForegroundColor Cyan
    Write-Host "   adb devices" -ForegroundColor Gray
    exit 1
}
Write-Host "   [OK] Device connected" -ForegroundColor Green
Write-Host ""

# 3. Copy database from device to sdcard
Write-Host "Step 3/4: Copy Database to SD Card" -ForegroundColor Yellow
Write-Host "--------------------------------------------"
Write-Host "   Database path: /data/data/com.example.youdu/databases/youdu_messages.db" -ForegroundColor Gray

# Execute copy command (requires root)
$copyCommand = "su -c 'cp /data/data/com.example.youdu/databases/youdu_messages.db /sdcard/'"
$result = adb shell $copyCommand 2>&1

# Check if copy succeeded
$checkCommand = "ls /sdcard/youdu_messages.db"
$checkResult = adb shell $checkCommand 2>&1

if ($checkResult -match "No such file") {
    Write-Host "   [ERROR] Database copy failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible reasons:" -ForegroundColor Yellow
    Write-Host "   1. Device does not have Root access" -ForegroundColor Yellow
    Write-Host "   2. App not installed or incorrect package name" -ForegroundColor Yellow
    Write-Host "   3. Database file does not exist" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please manually execute following commands to troubleshoot:" -ForegroundColor Cyan
    Write-Host "   adb shell" -ForegroundColor Gray
    Write-Host "   su" -ForegroundColor Gray
    Write-Host "   ls /data/data/com.example.youdu/databases/" -ForegroundColor Gray
    exit 1
}

Write-Host "   [OK] Database copied to /sdcard/youdu_messages.db" -ForegroundColor Green
Write-Host ""

# 4. Pull database from device to project root
Write-Host "Step 4/4: Download Database to Project Directory" -ForegroundColor Yellow
Write-Host "--------------------------------------------"

# Get project root directory (parent of script directory)
$projectRoot = Split-Path -Parent $PSScriptRoot
$targetPath = Join-Path $projectRoot "youdu_messages.db"

Write-Host "   Target path: $targetPath" -ForegroundColor Gray

# Backup if target file already exists
if (Test-Path $targetPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $projectRoot "youdu_messages.db.backup_$timestamp"
    Write-Host "   [INFO] Found existing database file, backing up to:" -ForegroundColor Yellow
    Write-Host "          $backupPath" -ForegroundColor Gray
    Move-Item -Path $targetPath -Destination $backupPath -Force
}

# Pull database
Set-Location $projectRoot
$pullResult = adb pull /sdcard/youdu_messages.db . 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "   [ERROR] Database download failed" -ForegroundColor Red
    Write-Host "   Error message: $pullResult" -ForegroundColor Red
    exit 1
}

# Verify file was successfully downloaded
if (Test-Path $targetPath) {
    $fileSize = (Get-Item $targetPath).Length
    $fileSizeKB = [math]::Round($fileSize / 1024, 2)
    Write-Host "   [OK] Database downloaded" -ForegroundColor Green
    Write-Host "   File size: $fileSizeKB KB" -ForegroundColor Gray
} else {
    Write-Host "   [ERROR] Database file not found" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 5. Clean up temporary file on device (optional)
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
adb shell rm /sdcard/youdu_messages.db 2>&1 | Out-Null
Write-Host "   [OK] Temporary files cleaned" -ForegroundColor Green
Write-Host ""

# Complete
Write-Host "============================================" -ForegroundColor Green
Write-Host "   [SUCCESS] Database export completed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Database location: $targetPath" -ForegroundColor Cyan
Write-Host "File size: $fileSizeKB KB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps - run test scripts:" -ForegroundColor Yellow
Write-Host "   1. Get UUID:" -ForegroundColor Gray
Write-Host "      .\scripts\get_db_password.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. Test Android database:" -ForegroundColor Gray
Write-Host "      dart run test_db_encryption2.dart <UUID> --android" -ForegroundColor Gray
Write-Host ""
Write-Host "   3. Test iOS database:" -ForegroundColor Gray
Write-Host "      dart run test_db_encryption2.dart <UUID> --ios" -ForegroundColor Gray
Write-Host ""
